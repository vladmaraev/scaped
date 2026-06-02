defmodule Scaped.AzureService do
  require Req

  defp azure_key, do: Application.fetch_env!(:scaped, Scaped.AzureService)[:key]
  defp azure_clu_key, do: Application.fetch_env!(:scaped, Scaped.AzureService)[:clu_key]

  def get_token do
    Req.post!("https://francecentral.api.cognitive.microsoft.com/sts/v1.0/issueToken",
      headers: %{"Ocp-Apim-Subscription-Key": azure_key()},
      body: ""
    ).body
  end
end
