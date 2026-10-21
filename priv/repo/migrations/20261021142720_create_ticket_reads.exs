defmodule TicketElixir.Repo.Migrations.CreateTicketReads do
  use Ecto.Migration

  def change do
    create table(:ticket_reads, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :ticket_id, references(:tickets, on_delete: :delete_all, type: :binary_id), null: false
      add :last_read_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:ticket_reads, [:user_id, :ticket_id])
  end
end
