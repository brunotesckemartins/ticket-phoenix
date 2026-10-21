defmodule TicketElixir.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TicketElixirWeb.Telemetry,
      TicketElixir.Repo,
      {DNSCluster, query: Application.get_env(:ticket_elixir, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TicketElixir.PubSub},
      # Start a worker by calling: TicketElixir.Worker.start_link(arg)
      # {TicketElixir.Worker, arg},
      # Start to serve requests, typically the last entry
      TicketElixirWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TicketElixir.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TicketElixirWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
