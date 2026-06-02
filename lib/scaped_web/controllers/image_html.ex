defmodule ScapedWeb.ImageHTML do
  use ScapedWeb, :html

  embed_templates "image_html/*"

  @doc """
  Renders a image form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def image_form(assigns)
end
