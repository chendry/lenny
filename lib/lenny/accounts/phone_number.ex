defmodule Lenny.Accounts.PhoneNumber do
  use Ecto.Schema
  import Ecto.Changeset

  schema "phone_numbers" do
    field :user_id, :id
    field :phone, :string
    field :sid, :string
    field :channel, :string
    field :status, :string
    field :deleted_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(phone_number, attrs) do
    phone_number
    |> cast(attrs, [:phone, :sid, :channel, :status, :deleted_at])
    |> validate_required([:phone, :sid, :channel, :status, :deleted_at])
  end
end
