defmodule Lenny.Repo.Migrations.CreatePhoneNumbers do
  use Ecto.Migration

  def change do
    create table(:phone_numbers) do
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :phone, :string, null: false
      add :channel, :string
      add :sid, :string
      add :status, :string
      add :deleted_at, :naive_datetime

      timestamps()
    end

    create index(:phone_numbers, [:user_id])
    create unique_index(:phone_numbers, [:user_id, :phone, :deleted_at])
  end
end
