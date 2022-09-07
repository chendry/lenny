defmodule Lenny.PhoneNumberTest do
  use Lenny.DataCase, async: true

  import Lenny.AccountsFixtures

  alias Lenny.PhoneNumbers.PhoneNumber

  describe "validation" do
    test "invalid phone number" do
      changeset = PhoneNumber.changeset(%PhoneNumber{channel: "sms"}, %{phone: "(555) 555-5555"})
      assert %{phone: ["has invalid format"]} = errors_on(changeset)
    end

    test "north american numbers don't need the +1" do
      assert PhoneNumber.changeset(%PhoneNumber{channel: "sms"}, %{phone: "5551112222"}).valid?
    end

    test "north american numbers can have the +1" do
      assert PhoneNumber.changeset(%PhoneNumber{channel: "sms"}, %{phone: "+15552221234"}).valid?
    end

    test "digits after the + can be as few as 6" do
      refute PhoneNumber.changeset(%PhoneNumber{channel: "sms"}, %{phone: "+112345"}).valid?
      assert PhoneNumber.changeset(%PhoneNumber{channel: "sms"}, %{phone: "+1123456"}).valid?
    end

    test "digits after the + can be as many as 15" do
      assert PhoneNumber.changeset(%PhoneNumber{channel: "sms"}, %{phone: "+123456789012345"}).valid?
      refute PhoneNumber.changeset(%PhoneNumber{channel: "sms"}, %{phone: "+1234567890123456"}).valid?
    end
  end

  test "inserting a 10 digit number without a country code adds the code on insertion" do
    phone_number =
      %PhoneNumber{user: user_fixture()}
      |> PhoneNumber.changeset(%{channel: "sms", phone: "2223334444"})
      |> Repo.insert!()

    assert phone_number.phone == "+12223334444"
  end

  test "numbers with country codes are inserted un-modified" do
    phone_number =
      %PhoneNumber{user: user_fixture()}
      |> PhoneNumber.changeset(%{channel: "sms", phone: "+1123456"})
      |> Repo.insert!()

    assert phone_number.phone == "+1123456"

    phone_number =
      %PhoneNumber{user: user_fixture()}
      |> PhoneNumber.changeset(%{channel: "sms", phone: "+123456789012345"})
      |> Repo.insert!()

    assert phone_number.phone == "+123456789012345"
  end
end
