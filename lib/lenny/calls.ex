defmodule Lenny.Calls do
  alias Lenny.Calls.Call

  alias Lenny.Repo

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
end
