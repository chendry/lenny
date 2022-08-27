defmodule Lenny.Recordings do
  import Ecto.Changeset

  alias Lenny.Repo
  alias Lenny.Recordings.Recording

  def create_from_twilio_params!(params) do
    %Recording{}
    |> change(
      sid: params["CallSid"],
      status: params["RecordingStatus"],
      url: params["RecordingUrl"],
      params: params
    )
    |> Repo.insert!()
  end
end
