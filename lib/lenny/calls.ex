defmodule Lenny.Calls do
  import Ecto.Query
  import Ecto.Changeset

  alias Ecto.Multi
  alias Lenny.Calls.Call
  alias Lenny.Calls.UsersCalls
  alias Lenny.PhoneNumbers.PhoneNumber
  alias Lenny.Repo

  def get_by_sid!(sid) do
    Call
    |> where(sid: ^sid)
    |> Repo.one!()
  end

  def create_from_twilio_params!(params) do
    changeset =
      %Call{}
      |> change(
        sid: params["CallSid"],
        from: params["From"],
        to: params["To"],
        forwarded_from: params["ForwardedFrom"],
        ended_at: nil,
        iteration: 0,
        speech: nil,
        autopilot: true,
        params: params
      )

    {:ok, %{call: call}} =
      Multi.new()
      |> Multi.insert(:call, changeset)
      |> Multi.insert_all(
        :users_calls,
        UsersCalls,
        fn %{call: call} ->
          build_users_calls_records(call)
        end
      )
      |> Repo.transaction()

    call
  end

  def build_users_calls_records(call) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    PhoneNumber
    |> where([p], is_nil(p.deleted_at) and not is_nil(p.verified_at))
    |> where([p], p.phone == ^call.from)
    |> select([p], p.user_id)
    |> Repo.all()
    |> Enum.map(fn user_id ->
      %{
        user_id: user_id,
        call_id: call.id,
        inserted_at: now,
        updated_at: now
      }
    end)
  end

  def save_and_broadcast_call(sid, changes) when is_binary(sid) do
    sid
    |> get_by_sid!()
    |> save_and_broadcast_call(changes)
  end

  def save_and_broadcast_call(%Call{} = call, changes) do
    call =
      call
      |> Ecto.Changeset.change(changes)
      |> Repo.update!()

    Phoenix.PubSub.broadcast(
      Lenny.PubSub,
      "call:#{call.sid}",
      {:call, %{call | params: nil}}
    )
  end

  def get_all_calls_for_user_id(user_id) do
    Call
    |> join(:inner, [c], u in assoc(c, :users))
    |> where([c, u], u.id == ^user_id)
    |> select([c, u], c)
    |> Repo.all()
  end

  def get_effective_number(%Call{} = call) do
    call.forwarded_from || call.from
  end
end
