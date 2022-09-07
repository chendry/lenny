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
    |> cast(attrs, [:phone, :channel])
    |> validate_required([:phone, :channel])
    |> validate_format(:phone, ~r/^(\d{10}|\+[1-9]\d{6,14})$/)
    |> validate_inclusion(:channel, ~w(sms call))
    |> prepare_changes(fn changeset ->
      changeset
      |> update_change(:phone, fn phone ->
        if String.starts_with?(phone, "+") do
          phone
        else
          "+1#{phone}"
        end
      end)
    end)
  end
end
