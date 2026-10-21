defmodule TicketElixir.Tickets.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tickets" do
    field :subject, :string
    field :description, :string
    field :status, Ecto.Enum,
      values: [:aberto, :em_andamento, :aguardando_solicitante, :resolvido, :fechado],
      default: :aberto

    belongs_to :solicitante, TicketElixir.Accounts.User
    belongs_to :atendente, TicketElixir.Accounts.User
    has_many :messages, TicketElixir.Messages.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:subject, :description, :status, :solicitante_id, :atendente_id])
    |> validate_required([:subject, :description, :solicitante_id])
  end
end
