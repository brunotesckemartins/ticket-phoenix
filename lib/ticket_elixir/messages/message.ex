defmodule TicketElixir.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :body, :string
    field :internal, :boolean, default: false

    belongs_to :ticket, TicketElixir.Tickets.Ticket
    belongs_to :user, TicketElixir.Accounts.User
    has_many :attachments, TicketElixir.Messages.Attachment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body, :internal, :ticket_id, :user_id])
    |> validate_required([:ticket_id, :user_id])
  end
end
