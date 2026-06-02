defmodule ScapedWeb.AzureController do
  use ScapedWeb, :controller
  alias Scaped.AzureService

  require Logger

  defp azure_clu_key, do: Application.fetch_env!(:scaped, Scaped.AzureService)[:clu_key]

  def token(conn, _params) do
    token = AzureService.get_token()
    text(conn, token)
  end

  def clu_key(conn, _params) do
    text(conn, azure_clu_key())
  end
  
end
