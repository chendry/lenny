defmodule Lenny.Repo.Migrations.CreateUsersCalls do
  use Ecto.Migration

  def change do
    create table(:users_calls) do
      add :deleted_at, :naive_datetime
      add :user_id, references(:users, on_delete: :nothing)
      add :call_id, references(:calls, on_delete: :nothing)

      timestamps()
    end

    create index(:users_calls, [:user_id])
    create index(:users_calls, [:call_id])
  end
end
