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

  def register_phone_number_and_start_verification(%User{} = user, attrs) do
    %PhoneNumber{user_id: user.id}
    |> PhoneNumber.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, phone_number} -> start_new_verification(phone_number)
      error -> error
    end
  end

  defp start_new_verification(%PhoneNumber{} = phone_number) do
    case Twilio.start_new_verification(phone_number.phone, "sms") do
      {:ok, sid} ->
        phone_number
        |> change(sid: sid)
        |> Repo.update()

      error ->
        changeset =
          phone_number
          |> PhoneNumber.changeset(%{})
          |> Map.put(:action, :insert)

        case error do
          :invalid_phone_number ->
            {:error, add_error(changeset, :phone, "is invalid according to twilio")}

          :max_send_attempts_reached ->
            {:error, add_error(changeset, :phone, "max attempts reached")}
        end
    end
  end

  def verify_phone_number(%PhoneNumber{} = phone_number, %{"code" => code} = _attrs) do
    case Twilio.check_verification(phone_number.sid, code) do
      :approved ->
        phone_number
        |> change(status: "approved")
        |> Repo.update()

      error ->
        {:error,
         phone_number
         |> change()
         |> add_error(:code, inspect(error))}
    end
  end
end
