defmodule TicketElixir.Messages.Attachment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "attachments" do
    field :filename, :string
    field :content_type, :string
    field :path, :string

    belongs_to :message, TicketElixir.Messages.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:filename, :content_type, :path, :message_id])
    |> validate_required([:filename, :content_type, :path, :message_id])
  end
end
