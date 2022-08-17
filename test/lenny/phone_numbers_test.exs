defmodule Lenny.PhoneNumbersTest do
  use Lenny.DataCase

  alias Lenny.PhoneNumbers
  alias Lenny.PhoneNumbers.PhoneNumber

  import Lenny.AccountsFixtures

  describe "register_phone_number/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates phone_number", %{user: user} do
      {:error, changeset} = PhoneNumbers.register_phone_number(user, "(312) 618-0256")
      assert %{phone: ["has invalid format"]} = errors_on(changeset)
    end

    test "inserts a phone_number record", %{user: user} do
      {:ok, phone_number} = PhoneNumbers.register_phone_number(user, "+13126180256")
      assert %PhoneNumber{} = phone_number
      assert phone_number.id != nil
    end
  end
end
