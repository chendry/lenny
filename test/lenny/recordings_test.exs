defmodule Lenny.RecordingsTest do
  use Lenny.DataCase

  import Lenny.AccountsFixtures
  import Lenny.RecordingsFixtures
  import Lenny.CallsFixtures
  import Lenny.PhoneNumbersFixtures
  import Lenny.UsersCallsFixtures

  alias Lenny.Repo
  alias Lenny.Recordings

  test "create a recording using twilio params" do
    params = %{
      "CallSid" => "CAb965",
      "RecordingStatus" => "in-progress",
      "RecordingUrl" => "https://example.com/CAb965.wav"
    }

    recording =
      params
      |> Recordings.insert_or_update_from_twilio_params!()
      |> Repo.reload()

    assert recording.sid == "CAb965"
    assert recording.status == "in-progress"
    assert recording.url == "https://example.com/CAb965.wav"
    assert recording.params == params
  end

  test "update a recording using twilio params" do
    recording =
      recordings_fixture(
        sid: "CA73ee",
        status: "in-progress",
        url: "https://example.com/CA73ee.wav"
      )

    Recordings.insert_or_update_from_twilio_params!(%{
      "CallSid" => "CA73ee",
      "RecordingStatus" => "completed",
      "RecordingUrl" => "https://example.com/CA73ee.mp3"
    })

    recording = Repo.reload(recording)
    assert recording.status == "completed"
    assert recording.url == "https://example.com/CA73ee.mp3"
  end

  test "get_recording_for_user" do
    u1 = user_fixture()
    u2 = user_fixture()

    phone_number_fixture(u1)
    phone_number_fixture(u2)

    c = call_fixture(sid: "CAb103")
    r = recordings_fixture(sid: "CAb103")

    users_calls_fixture(u1, c, recorded: true)
    users_calls_fixture(u2, c, recorded: false)

    assert Recordings.get_recording_for_user(u1.id, "CAb103") == r
    assert Recordings.get_recording_for_user(u2.id, "CAb103") == nil
  end
end
