defmodule Lenny.Repo.Migrations.CreateUsersCalls do
  use Ecto.Migration

  def change do
    create table(:users_calls) do
      add :user_id, references(:users, on_delete: :nothing)
      add :call_id, references(:calls, on_delete: :nothing)
      add :recorded, :boolean, null: false
      add :seen_at, :naive_datetime
      add :deleted_at, :naive_datetime

      timestamps()
    end

    create unique_index(:users_calls, [:user_id, :call_id])
  end
end
