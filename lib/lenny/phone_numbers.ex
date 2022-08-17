defmodule Lenny.PhoneNumbers do
  import Ecto.Query
  import Ecto.Changeset

  alias Lenny.Repo
  alias Lenny.Accounts.User
  alias Lenny.PhoneNumbers.PhoneNumber
  alias Lenny.Twilio

  def get_approved_phone_number(%User{} = user) do
    PhoneNumber
    |> for_user(user)
    |> where([p], p.status == "approved")
    |> limit(1)
    |> Repo.one()
  end

  def get_pending_phone_number(%User{} = user) do
    PhoneNumber
    |> for_user(user)
    |> where([p], is_nil(p.status) or p.status == "pending")
    |> limit(1)
    |> Repo.one()
  end

  defp for_user(query, %User{} = user) do
    query
    |> where([p], p.user_id == ^user.id)
    |> where([p], is_nil(p.deleted_at))
    |> order_by([p], desc: p.id)
  end

  def register_phone_number(%User{} = user, phone_number) do
    %PhoneNumber{user_id: user.id}
    |> PhoneNumber.changeset(%{phone: phone_number})
    |> Repo.insert()
  end

  def start_new_verification(%PhoneNumber{} = phone_number) do
    case Twilio.start_new_verification(phone_number.phone, "sms") do
      {:ok, sid} ->
        phone_number =
          phone_number
          |> change(sid: sid)
          |> Repo.update!()

        {:ok, phone_number}

      :invalid_phone_number ->
        changeset =
          phone_number
          |> PhoneNumber.changeset(%{})
          |> Map.put(:action, :insert)
          |> Ecto.Changeset.add_error(:phone, "is invalid according to twilio")

        {:error, changeset}
    end
  end
end
