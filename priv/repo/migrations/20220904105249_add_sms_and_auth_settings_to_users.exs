defmodule Lenny.Repo.Migrations.AddSmsAndAuthSettingsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :send_sms, :boolean, null: false
      add :skip_auth_for_active_calls, :boolean
    end
  end
end
