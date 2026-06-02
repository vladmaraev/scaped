defmodule Scaped.RecordingPipeline do
  @moduledoc """
  Records screen (video + system audio) and mic (audio) to a single MP4:
  - video: VP8→H264 or H264 directly
  - audio: 2 tracks (screen audio + mic), both AAC
  """

  use Membrane.Pipeline
  import Membrane.ChildrenSpec
  require Logger

  alias Membrane.WebRTC.PhoenixSignaling
  alias Membrane.WebRTC.Source, as: WebRTCSource

  alias Membrane.MP4.Muxer.ISOM, as: MP4Muxer
  alias Membrane.File.Sink, as: FileSink

  alias Membrane.Opus.Decoder, as: OpusDec
  alias Membrane.AAC.FDK.Encoder, as: AACEnc
  alias Membrane.AAC.Parser, as: AACParser

  alias Membrane.VPX.Decoder, as: VPXDec
  alias Membrane.H264.FFmpeg.Encoder, as: H264Enc
  alias Membrane.H264.Parser, as: H264Parser

  @type opts :: %{
          required(:screen_signaling_id) => String.t(),
          required(:mic_signaling_id) => String.t(),
          required(:out_path) => Path.t()
        }

  @impl true
  def handle_init(_ctx, %{
        screen_signaling_id: screen_id,
        mic_signaling_id: mic_id,
        out_path: out_path
      }) do
    Logger.info(
      "RecordingPipeline init — screen_id=#{screen_id} mic_id=#{mic_id} out=#{out_path}"
    )

    screen_sig = PhoenixSignaling.new(screen_id)
    mic_sig = PhoenixSignaling.new(mic_id)

    # Start both WebRTC sources + MP4 writer; we’ll link tracks when we learn about them.
    spec = [
      child(:screen_src, %WebRTCSource{signaling: screen_sig}),
      child(:mic_src, %WebRTCSource{signaling: mic_sig}),
      child(:mp4, %MP4Muxer{fast_start: true}),
      child(:file, %FileSink{location: out_path}),
      # connect MP4 → File (default pads: :output -> :input)
      get_child(:mp4) |> get_child(:file)
    ]

    state = %{
      screen_audio_linked?: false,
      mic_audio_linked?: false,
      video_linked?: false
    }

    {[spec: spec], state}
  end

  # When the SCREEN source announces tracks, add the needed chains.
  @impl true
  def handle_child_notification(_ctx, {:new_tracks, tracks}, %{name: :screen_src}, state) do
    Logger.info("screen_src NEW TRACKS: #{inspect(tracks, pretty: true)}")

    add_specs =
      Enum.flat_map(tracks, fn t ->
        case {t.kind, t.encoding} do
          {:audio, _} ->
            if state.screen_audio_linked?, do: [], else: screen_audio_chain()

          {:video, :H264} ->
            if state.video_linked?, do: [], else: h264_video_chain()

          {:video, :VP8} ->
            if state.video_linked?, do: [], else: vp8_video_chain()

          # ignore other kinds/encodings
          _ ->
            []
        end
      end)

    new_state =
      Enum.reduce(tracks, state, fn t, acc ->
        case t.kind do
          :audio -> %{acc | screen_audio_linked?: true}
          :video -> %{acc | video_linked?: true}
          _ -> acc
        end
      end)

    {{:ok, spec: add_specs}, new_state}
  end

  # When the MIC source announces tracks, link its audio chain once.
  @impl true
  def handle_child_notification(_ctx, {:new_tracks, tracks}, %{name: :mic_src}, state) do
    Logger.info("mic_src NEW TRACKS: #{inspect(tracks, pretty: true)}")

    add_specs =
      if state.mic_audio_linked?, do: [], else: mic_audio_chain()

    new_state =
      if Enum.any?(tracks, &(&1.kind == :audio)),
        do: %{state | mic_audio_linked?: true},
        else: state

    {{:ok, spec: add_specs}, new_state}
  end

  # (Optional) Log ICE/SDP progress from sources for easier debugging.
  @impl true
  def handle_child_notification(_ctx, notif, child, state) do
    case notif do
      {:negotiated_codecs, codecs} ->
        Logger.info("[#{child.name}] negotiated_codecs=#{inspect(codecs, pretty: true)}")

      other ->
        Logger.debug("[#{child.name}] notif: #{inspect(other)}")
    end

    {:ok, state}
  end

  # ---------- Chain builders (return ChildrenSpec lists) ----------

  # Screen/system audio → Opus → AAC → AAC Parser → MP4 (:screen_audio pad)
  defp screen_audio_chain do
    [
      get_child(:screen_src)
      |> via_out(Pad.ref(:output, :screen_audio), options: [kind: :audio])
      |> child(:screen_opus_dec, OpusDec)
      |> child(:screen_aac_enc, %AACEnc{bitrate: 128_000})
      |> child(:screen_aac_par, %AACParser{output_config: :esds})
      |> via_in(Pad.ref(:input, :screen_audio))
      |> get_child(:mp4)
    ]
  end

  # Mic audio → Opus → AAC → AAC Parser → MP4 (:mic_audio pad)
  defp mic_audio_chain do
    [
      get_child(:mic_src)
      |> via_out(Pad.ref(:output, :mic_audio), options: [kind: :audio])
      |> child(:mic_opus_dec, OpusDec)
      |> child(:mic_aac_enc, %AACEnc{bitrate: 128_000})
      |> child(:mic_aac_par, %AACParser{output_config: :esds})
      |> via_in(Pad.ref(:input, :mic_audio))
      |> get_child(:mp4)
    ]
  end

  # H.264 (from browser) → AU-align → MP4 (:video pad)
  defp h264_video_chain do
    [
      get_child(:screen_src)
      |> via_out(Pad.ref(:output, :screen_video), options: [kind: :video])
      |> child(:h264_par, %H264Parser{output_alignment: :au})
      |> via_in(Pad.ref(:input, :video))
      |> get_child(:mp4)
    ]
  end

  # VP8 → VP8 decoder → H.264 encoder → MP4 (:video pad)
  defp vp8_video_chain do
    [
      get_child(:screen_src)
      |> via_out(Pad.ref(:output, :screen_video), options: [kind: :video])
      |> child(:vp8_dec, VPXDec)
      |> child(:h264_enc, %H264Enc{
        preset: :veryfast,
        tune: :zerolatency,
        profile: :high
      })
      # H264Enc produces AU-aligned bitstream suitable for MP4
      |> via_in(Pad.ref(:input, :video))
      |> get_child(:mp4)
    ]
  end
end
