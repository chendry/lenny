defmodule Lenny.Calls.Call do
  use Ecto.Schema
  import Ecto.Changeset

  schema "calls" do
    field :sid, :string
    field :from, :string
    field :to, :string
    field :forwarded_from, :string
    field :ended_at, :naive_datetime
    field :params, :map

    timestamps()
  end

  @doc false
  def changeset(call, attrs) do
    call
    |> cast(attrs, [:sid, :from, :to, :forwarded_from, :ended_at, :params])
    |> validate_required([:sid, :from, :to, :forwarded_from, :ended_at, :params])
  end
end
