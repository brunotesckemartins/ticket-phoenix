defmodule TicketElixir.Repo.Migrations.CreateAttachments do
  use Ecto.Migration

  def change do
    create table(:attachments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :content_type, :string
      add :path, :string
      add :message_id, references(:messages, on_delete: :delete_all, type: :binary_id), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:attachments, [:user_id])

    create index(:attachments, [:message_id])
  end
end
