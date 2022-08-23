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
end
