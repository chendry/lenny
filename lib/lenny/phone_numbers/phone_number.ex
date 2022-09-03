defmodule Lenny.PhoneNumbers.PhoneNumber do
  use Ecto.Schema
  import Ecto.Changeset

  schema "phone_numbers" do
    belongs_to :user, Lenny.Accounts.User

    field :phone, :string
    field :channel, :string
    field :sid, :string
    field :carrier, :map
    field :verified_at, :naive_datetime
    field :deleted_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = phone_number \\ %__MODULE__{}, attrs \\ %{}) do
    phone_number
    |> cast(attrs, [:phone])
    |> validate_required([:phone])
    |> validate_format(:phone, ~r/^\d{10}$/)
    |> prepare_changes(fn changeset ->
      update_change(changeset, :phone, &("+1" <> &1))
    end)
  end
end
