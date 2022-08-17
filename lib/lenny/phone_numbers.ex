defmodule Lenny.PhoneNumbers do
  alias Lenny.Repo
  alias Lenny.Accounts.User
  alias Lenny.PhoneNumbers.PhoneNumber

  def register_phone_number(%User{} = user, phone_number) do
    %PhoneNumber{user_id: user.id}
    |> PhoneNumber.changeset(%{phone: phone_number})
    |> Repo.insert()
  end
end
