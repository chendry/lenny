defmodule Lenny.PhoneNumbersTest do
  use Lenny.DataCase, async: true

  alias Lenny.PhoneNumbers
  alias Lenny.PhoneNumbers.PhoneNumber

  import Lenny.AccountsFixtures
  import Lenny.PhoneNumbersFixtures

  test "register_phone_number_and_start_verification deletes pending phone numbers" do
    user = user_fixture()

    p1 = phone_number_fixture(user, verified_at: ~N[2022-08-21 15:37:22], deleted_at: nil)
    p2 = phone_number_fixture(user, verified_at: nil, deleted_at: ~N[2022-08-21 15:39:41])
    p3 = phone_number_fixture(user, verified_at: nil, deleted_at: nil)
    p4 = phone_number_fixture(user_fixture(), verified_at: nil, deleted_at: nil)

    Mox.expect(Lenny.TwilioMock, :verify_start, fn _, _ -> {:ok, %{sid: "VEa29d", carrier: %{}}} end)

    {:ok, phone_number} =
      PhoneNumbers.register_phone_number_and_start_verification(
        user,
        %{"phone" => "5551112222"}
      )

    assert phone_number.verified_at == nil
    assert phone_number.deleted_at == nil

    assert Repo.get(PhoneNumber, p1.id).deleted_at == nil
    assert Repo.get(PhoneNumber, p2.id).deleted_at == ~N[2022-08-21 15:39:41]
    assert Repo.get(PhoneNumber, p3.id).deleted_at != nil
    assert Repo.get(PhoneNumber, p4.id).deleted_at == nil
  end

  test "register_phone_number_and_start_verification for invalid phone number" do
    user = user_fixture()

    Mox.expect(Lenny.TwilioMock, :verify_start, fn _, _ -> {:error, "invalid phone number"} end)

    {:error, changeset} =
      PhoneNumbers.register_phone_number_and_start_verification(
        user,
        %{"phone" => "WOOF"}
      )

    assert errors_on(changeset) == %{phone: ["has invalid format"]}
  end

  test "register_phone_number_and_start_verification records sid and carrier" do
    user = user_fixture()

    Lenny.TwilioMock
    |> Mox.expect(:verify_start, fn "+13125550004", _ ->
      {:ok,
       %{
         sid: "VEb8d6",
         carrier: %{
           "error_code" => nil,
           "mobile_country_code" => "311",
           "mobile_network_code" => "180",
           "name" => "AT&T Wireless",
           "type" => "mobile"
         }
       }}
    end)

    {:ok, phone_number} =
      PhoneNumbers.register_phone_number_and_start_verification(
        user,
        %{"phone" => "3125550004"}
      )

    assert phone_number.sid == "VEb8d6"

    assert phone_number.carrier ==
             %{
               "error_code" => nil,
               "mobile_country_code" => "311",
               "mobile_network_code" => "180",
               "name" => "AT&T Wireless",
               "type" => "mobile"
             }
  end
end
