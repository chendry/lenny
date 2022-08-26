defmodule Lenny.Calls.UsersCalls do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users_calls" do
    field :deleted_at, :naive_datetime
    field :user_id, :id
    field :call_id, :id

    timestamps()
  end

  @doc false
  def changeset(users_calls, attrs) do
    users_calls
    |> cast(attrs, [:deleted_at])
    |> validate_required([:deleted_at])
  end
end
