defmodule Lenny.PhoneNumbers do
  import Ecto.Query
  import Ecto.Changeset

  alias Lenny.Repo
  alias Lenny.Accounts.User
  alias Lenny.PhoneNumbers.PhoneNumber
  alias Lenny.PhoneNumbers.VerificationForm
  alias Lenny.Twilio

  def get_approved_phone_number(%User{} = user) do
    PhoneNumber
    |> for_user(user)
    |> where([p], not is_nil(p.verified_at))
    |> limit(1)
    |> Repo.one()
  end

  def get_pending_phone_number(%User{} = user) do
    PhoneNumber
    |> for_user(user)
    |> where([p], is_nil(p.verified_at))
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
    case Twilio.verify_start(phone_number.phone, "sms") do
      {:ok, sid} ->
        phone_number
        |> change(sid: sid)
        |> Repo.update()

      {:error, message} ->
        {:error,
         phone_number
         |> PhoneNumber.changeset()
         |> add_error(:phone, message)
         |> Map.put(:action, :insert)}
    end
  end

  def verify_phone_number(%PhoneNumber{} = phone_number, %{"code" => code} = attrs) do
    changeset =
      %VerificationForm{}
      |> VerificationForm.changeset(attrs)
      |> Map.put(:action, :insert)

    if not changeset.valid? do
      {:error, changeset}
    else
      case Twilio.verify_check(phone_number.sid, code) do
        :ok ->
          phone_number
          |> change(verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
          |> Repo.update()

        {:error, message} ->
          {:error, add_error(changeset, :code, message)}

        {:stop, message} ->
          {:stop, message}
      end
    end
  end

  def soft_delete_phone_number(%PhoneNumber{} = phone_number) do
    phone_number
    |> change(deleted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second))
    |> Repo.update!()
  end
end
