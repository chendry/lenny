defmodule Lenny.PhoneNumbers.VerificationForm do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :code, :integer
  end

  def changeset(%__MODULE__{} = verification_form, attrs \\ %{}) do
    verification_form
    |> cast(attrs, [:code])
    |> validate_required(:code)
    |> validate_number(:code, greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999_999)
  end
end
