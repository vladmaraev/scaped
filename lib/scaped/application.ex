defmodule Scaped.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ScapedWeb.Telemetry,
      Scaped.Repo,
      {DNSCluster, query: Application.get_env(:scaped, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Scaped.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Scaped.Finch},
      # Start a worker by calling: Scaped.Worker.start_link(arg)
      # {Scaped.Worker, arg},
      # Start to serve requests, typically the last entry
      ScapedWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Scaped.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ScapedWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
