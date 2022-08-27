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
      |> Multi.insert_all(:users_calls, UsersCalls, fn %{call: call} ->
        from c in Call,
          where: c.id == ^call.id,
          join: p in PhoneNumber,
          on: p.phone == c.from or p.phone == c.forwarded_from,
          join: u in assoc(p, :user),
          where: is_nil(p.deleted_at) and not is_nil(p.verified_at),
          select: %{
            user_id: p.user_id,
            call_id: c.id,
            recorded: u.record_calls,
            inserted_at: c.inserted_at,
            updated_at: c.updated_at
          }
      end)
      |> Repo.transaction()

    call
  end

  def should_record_call?(%Call{} = call) do
    UsersCalls
    |> where([uc], uc.call_id == ^call.id)
    |> where([uc], uc.recorded == true)
    |> Repo.exists?()
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

  def get_effective_from(%Call{} = call) do
    call.forwarded_from || call.from
  end
end
