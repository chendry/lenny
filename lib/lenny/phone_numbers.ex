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
    changeset =
      %PhoneNumber{user_id: user.id}
      |> PhoneNumber.changeset(attrs)
      |> Map.put(:action, :insert)

    if changeset.valid? do
      changeset
      |> Repo.insert!()
      |> start_new_verification()
    else
      {:error, changeset}
    end
  end

  defp start_new_verification(%PhoneNumber{} = phone_number) do
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
          |> add_error(:phone, "is invalid according to twilio")

        {:error, changeset}

      :max_send_attempts_reached ->
        changeset =
          phone_number
          |> PhoneNumber.changeset(%{})
          |> Map.put(:action, :insert)
          |> add_error(:phone, "max attempts reached")

        {:error, changeset}
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
