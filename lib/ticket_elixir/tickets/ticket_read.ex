defmodule TicketElixir.Tickets.TicketRead do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ticket_reads" do
    field :last_read_at, :utc_datetime
    belongs_to :user, TicketElixir.Accounts.User
    belongs_to :ticket, TicketElixir.Tickets.Ticket

    timestamps(type: :utc_datetime)
  end
end
