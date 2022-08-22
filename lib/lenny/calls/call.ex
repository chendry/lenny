defmodule Lenny.Calls.Call do
  use Ecto.Schema
  import Ecto.Changeset

  schema "calls" do
    field :ended_at, :naive_datetime
    field :forwarded_from, :string
    field :from, :string
    field :params, :map
    field :sid, :string
    field :to, :string

    timestamps()
  end

  @doc false
  def changeset(call, attrs) do
    call
    |> cast(attrs, [:sid, :from, :to, :forwarded_from, :ended_at, :params])
    |> validate_required([:sid, :from, :to, :forwarded_from, :ended_at, :params])
  end
end
