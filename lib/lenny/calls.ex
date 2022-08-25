defmodule Lenny.Calls do
  import Ecto.Query

  alias Lenny.Calls.Call
  alias Lenny.Repo

  def get_by_sid!(sid) do
    Call
    |> where(sid: ^sid)
    |> Repo.one!()
  end

  def create_from_twilio_params!(params) do
    %Call{
      sid: params["CallSid"],
      from: params["From"],
      to: params["To"],
      forwarded_from: params["ForwardedFrom"],
      autopilot: true,
      params: params
    }
    |> Repo.insert!()
  end

  def mark_as_finished!(sid) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Call
    |> where(sid: ^sid)
    |> Repo.update_all(set: [ended_at: now])
  end

  def set_autopilot!(sid, autopilot) do
    Call
    |> where(sid: ^sid)
    |> Repo.update_all(set: [autopilot: autopilot])
  end

  def get_autopilot(sid) do
    Call
    |> where(sid: ^sid)
    |> select([c], c.autopilot)
    |> Repo.one()
  end

  def get_active_calls(phone) do
    Call
    |> where([c], c.from == ^phone or c.forwarded_from == ^phone)
    |> where([c], is_nil(c.ended_at))
    |> order_by([c], c.id)
    |> Repo.all()
  end

  def get_effective_number(%Call{} = call) do
    call.forwarded_from || call.from
  end
end
