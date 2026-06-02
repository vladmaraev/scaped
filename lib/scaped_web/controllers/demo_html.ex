defmodule ScapedWeb.DemoHTML do
  use ScapedWeb, :live_view

  embed_templates "demo_html/*"

  attr :image64, :string
  attr :description, :string
  attr :state, :string
  attr :class, :string, default: "bg-green-200"

  def avatar(assigns) do
    ~H"""
    <div class="flex justify-center m-5">
      <button id="speechstate" class="btn-idle" phx-hook="SpeechState"></button>
    </div>
    """
  end

  def image(assigns) do
    ~H"""
    <div class="flex justify-center mb-5">
      <img src={"data:image/jpeg;base64, #{@image64}"} />
    </div>
    """
  end

  def script(assigns) do
    ~H"""
    <script type="module">
      window.dmActor.start();
      window.dmActor.send({type: "SETUP", value: `<%= @description %>`})
    </script>
    """
  end
end
