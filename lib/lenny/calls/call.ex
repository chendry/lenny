defmodule Lenny.Calls.Call do
  use Ecto.Schema
  import Ecto.Changeset

  schema "calls" do
    many_to_many :users, Lenny.Accounts.User, join_through: "users_calls"

    field :sid, :string
    field :from, :string
    field :to, :string
    field :autopilot, :boolean
    field :speech, :string
    field :iteration, :integer
    field :silence, :boolean
    field :forwarded_from, :string
    field :ended_at, :naive_datetime
    field :params, :map

    timestamps()
  end

  @doc false
  def changeset(call, attrs) do
    call
    |> cast(attrs, [:sid, :from, :to, :forwarded_from, :params])
    |> validate_required([:sid, :from, :to, :forwarded_from, :params])
  end
end
