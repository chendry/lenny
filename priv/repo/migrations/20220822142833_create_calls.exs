defmodule Lenny.Repo.Migrations.CreateCalls do
  use Ecto.Migration

  def change do
    create table(:calls) do
      add :sid, :string, null: false
      add :from, :string, null: false
      add :to, :string, null: false
      add :forwarded_from, :string
      add :ended_at, :naive_datetime
      add :params, :map, null: false

      timestamps()
    end

    create unique_index(:calls, :sid)
  end
end
