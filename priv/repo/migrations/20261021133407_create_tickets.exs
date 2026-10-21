defmodule TicketElixir.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :subject, :string, null: false
      add :description, :text
      add :status, :string, default: "aberto", null: false

      # O chamado sempre tem um solicitante. Se o solicitante for apagado, o chamado também é.
      add :solicitante_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      # O atendente é opcional (null: true). Se o atendente for apagado, o chamado fica sem atendente.
      add :atendente_id, references(:users, on_delete: :nilify_all, type: :binary_id), null: true

      timestamps(type: :utc_datetime)
    end

    create index(:tickets, [:solicitante_id])
    create index(:tickets, [:atendente_id])
  end
end
