defmodule Lenny.Calls do
  import Ecto.Query
  import Ecto.Changeset

  alias Ecto.Multi
  alias Lenny.Accounts.User
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
        silence: false,
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
          on: p.phone == coalesce(c.forwarded_from, c.from),
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

  def call_history_report(user_id) do
    Repo.all(
      from uc in UsersCalls,
        join: c in assoc(uc, :call),
        order_by: [desc: uc.id],
        where: uc.user_id == ^user_id,
        select: %{
          sid: c.sid,
          from: c.from,
          to: c.to,
          started_at: c.inserted_at,
          ended_at: c.ended_at,
          recorded: uc.recorded
        }
    )
  end

  def get_effective_from(%Call{} = call) do
    call.forwarded_from || call.from
  end

  def format_duration(started_at, ended_at) do
    seconds = NaiveDateTime.diff(ended_at, started_at)

    if seconds < 60 do
      "#{seconds}s"
    else
      "#{div(seconds, 60)}m #{rem(seconds, 60)}s"
    end
  end

  def format_timestamp_date(%NaiveDateTime{} = timestamp) do
    timestamp
    |> chicago_time()
    |> Calendar.strftime("%b %d %Y")
  end

  def format_timestamp_time(%NaiveDateTime{} = timestamp) do
    timestamp
    |> chicago_time()
    |> Calendar.strftime("%I:%M%P")
  end

  defp chicago_time(%NaiveDateTime{} = timestamp) do
    timestamp
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!("America/Chicago")
  end

  def delete_call(user_id, call_id) do
    UsersCalls
    |> Repo.get_by(user_id: user_id, call_id: call_id)
    |> Repo.delete!()
  end

  def mark_as_seen(user_id, call_id) do
    uc =
      UsersCalls
      |> where([uc], uc.user_id == ^user_id)
      |> where([uc], uc.call_id == ^call_id)
      |> Repo.one()

    if uc do
      uc
      |> change(seen_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
      |> Repo.update!()
    end
  end

  def get_sole_unseen_active_call_for_user(user_id) do
    Repo.all(
      from uc in UsersCalls,
        join: c in assoc(uc, :call),
        where: uc.user_id == ^user_id,
        where: is_nil(uc.seen_at) and is_nil(c.ended_at),
        select: c.sid
    )
    |> case do
      [sid] -> sid
      _ -> nil
    end
  end

  def get_active_calls_for_user(user_id) do
    Repo.all(
      from uc in UsersCalls,
        join: c in assoc(uc, :call),
        where: uc.user_id == ^user_id,
        select: c
    )
  end

  def get_call_for_user!(user_or_nil, sid) do
    case user_or_nil do
      nil ->
        Repo.one!(
          from c in Call,
            as: :call,
            where: c.sid == ^sid,
            where: not exists(from uc in UsersCalls, where: uc.call_id == parent_as(:call).id),
            select: c
        )

      %User{id: user_id} ->
        Repo.one!(
          from uc in UsersCalls,
            join: c in assoc(uc, :call),
            where: c.sid == ^sid,
            where: uc.user_id == ^user_id,
            where: is_nil(uc.deleted_at),
            select: c
        )
    end
  end
end
