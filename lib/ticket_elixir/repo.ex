defmodule TicketElixir.Repo do
  use Ecto.Repo,
    otp_app: :ticket_elixir,
    adapter: Ecto.Adapters.Postgres
end
