defmodule Lenny.Repo.Migrations.CreateRecordings do
  use Ecto.Migration

  def change do
    create table(:recordings) do
      add :sid, :string
      add :status, :string
      add :url, :string
      add :params, :map

      timestamps()
    end

    create unique_index(:recordings, [:sid])
  end
end
