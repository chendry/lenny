defmodule Lenny.Recordings do
  import Ecto.Changeset

  alias Lenny.Repo
  alias Lenny.Recordings.Recording

  def insert_or_update_from_twilio_params!(%{"CallSid" => sid} = params) do
    recording = Repo.get_by(Recording, sid: sid) || %Recording{sid: sid}

    recording
    |> change(
      status: params["RecordingStatus"],
      url: params["RecordingUrl"],
      params: params
    )
    |> Repo.insert_or_update!()
  end
end
