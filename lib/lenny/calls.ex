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
      ended: false,
      iteration: 0,
      speech: nil,
      autopilot: true,
      params: params
    }
    |> Repo.insert!()
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

  def get_active_calls(phone) do
    Call
    |> where([c], c.from == ^phone or c.forwarded_from == ^phone)
    |> where([c], c.ended == false)
    |> order_by([c], c.id)
    |> Repo.all()
  end

  def get_effective_number(%Call{} = call) do
    call.forwarded_from || call.from
  end
end
