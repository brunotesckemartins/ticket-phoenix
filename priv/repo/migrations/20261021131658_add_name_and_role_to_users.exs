defmodule TicketElixir.Repo.Migrations.AddNameAndRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :string
      add :role, :string, default: "solicitante", null: false
    end

    create constraint(:users, :role_must_be_valid,
             check: "role IN ('solicitante', 'suporte', 'admin')"
           )
  end
end
