defmodule Lenny.Calls.UsersCalls do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users_calls" do
    belongs_to :user, Lenny.Accounts.User
    belongs_to :call, Lenny.Calls.Call

    field :recorded, :boolean
    field :seen_at, :naive_datetime
    field :deleted_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(users_calls, attrs) do
    users_calls
    |> cast(attrs, [:deleted_at])
    |> validate_required([:deleted_at])
  end
end
