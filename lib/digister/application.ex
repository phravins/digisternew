defmodule Digister.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DigisterWeb.Telemetry,
      Digister.Repo,
      {DNSCluster, query: Application.get_env(:digister, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Digister.PubSub},
      Digister.BinCleaner,
      DigisterWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Digister.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DigisterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
