defmodule Lenny.Recordings.Recording do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recordings" do
    field :sid, :string
    field :status, :string
    field :url, :string
    field :params, :map

    timestamps()
  end

  @doc false
  def changeset(recording, attrs) do
    recording
    |> cast(attrs, [:sid, :status, :url, :params])
    |> validate_required([:sid, :status, :url, :params])
  end
end
