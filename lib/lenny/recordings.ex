defmodule Lenny.Recordings do
  import Ecto.Changeset
  import Ecto.Query

  alias Lenny.Repo
  alias Lenny.Recordings.Recording
  alias Lenny.Calls.Call
  alias Lenny.Calls.UsersCalls

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

  def get_recording_for_user(user_id, sid) do
    Repo.one(
      from r in Recording,
        join: c in Call,
        on: c.sid == r.sid,
        join: uc in UsersCalls,
        on: uc.call_id == c.id,
        where: uc.user_id == ^user_id and c.sid == ^sid and uc.recorded == true
    )
  end
end
