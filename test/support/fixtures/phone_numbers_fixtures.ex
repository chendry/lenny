defmodule Lenny.PhoneNumbersFixtures do
  alias Lenny.Repo
  alias Lenny.Accounts.User
  alias Lenny.PhoneNumbers.PhoneNumber

  def phone_number_fixture(%User{} = user, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        phone: random_phone_number(),
        channel: "sms"
      })

    %PhoneNumber{user_id: user.id}
    |> Ecto.Changeset.change(attrs)
    |> Repo.insert!()
  end

  defp random_phone_number do
    digits =
      1..10
      |> Enum.map(fn _ -> Enum.random(0..9) end)
      |> Enum.join()

    "+1#{digits}"
  end
end
