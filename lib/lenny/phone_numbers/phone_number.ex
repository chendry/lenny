defmodule Lenny.PhoneNumbers.PhoneNumber do
  use Ecto.Schema
  import Ecto.Changeset

  schema "phone_numbers" do
    field :user_id, :id
    field :phone, :string
    field :verification_sid, :string
    field :channel, :string
    field :status, :string
    field :deleted_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = phone_number \\ %__MODULE__{}, attrs \\ %{}) do
    phone_number
    |> cast(attrs, [:phone])
    |> validate_required([:phone])
    |> validate_format(:phone, ~r/^\+[1-9]\d{1,14}$/)
  end
end
