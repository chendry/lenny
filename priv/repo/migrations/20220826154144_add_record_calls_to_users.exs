defmodule Lenny.Repo.Migrations.AddRecordCallsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :record_calls, :boolean, null: false
    end
  end
end
