defmodule Lenny.PhoneNumbers.VerificationForm do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :code, :string
  end

  def changeset(%__MODULE__{} = verification_form, attrs \\ %{}) do
    verification_form
    |> cast(attrs, [:code])
    |> validate_required(:code)
    |> validate_format(:code, ~r/^\s*\d{4,10}\s*$/)
  end
end
