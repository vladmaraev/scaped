defmodule ScapedWeb.DemoController do
  use ScapedWeb, :controller

  alias Scaped.OllamaService
  require Logger

  def demo(conn, _params) do
    [head | _] = Enum.take_random(Scaped.Stimuli.list_images(), 1)
    {:ok, img} = OllamaService.get_image_base64(head.filename)
    description = "dummy description"
    # description = OllamaService.ollama_generate_visual_description(img)
    render(conn, :demo, image64: img, description: description, state: "dummy")
  end
end
