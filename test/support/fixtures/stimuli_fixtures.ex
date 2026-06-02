defmodule Scaped.StimuliFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Scaped.Stimuli` context.
  """

  @doc """
  Generate a image.
  """
  def image_fixture(attrs \\ %{}) do
    {:ok, image} =
      attrs
      |> Enum.into(%{
        filename: "some filename"
      })
      |> Scaped.Stimuli.create_image()

    image
  end
end
