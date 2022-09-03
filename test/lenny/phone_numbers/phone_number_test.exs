defmodule Lenny.PhoneNumberTest do
  use Lenny.DataCase

  alias Lenny.PhoneNumbers.PhoneNumber

  describe "validation" do
    test "invalid phone number" do
      changeset = PhoneNumber.changeset(%PhoneNumber{}, %{phone: "(555) 555-5555"})
      assert %{phone: ["has invalid format"]} = errors_on(changeset)
    end

    test "valid phone number" do
      changeset = PhoneNumber.changeset(%PhoneNumber{}, %{phone: "5551112222"})
      assert changeset.valid?
    end
  end
end
