defmodule Lenny.Repo.Migrations.CreateCalls do
  use Ecto.Migration

  def change do
    create table(:calls) do
      add :sid, :string
      add :from, :string
      add :to, :string
      add :forwarded_from, :string
      add :ended_at, :naive_datetime
      add :params, :map

      timestamps()
    end
  end
end
