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
      "AccountSid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      "CallSid" => "CAcfcd3db14f143b00141b45cd0ffa3d65",
      "RecordingChannels" => "1",
      "RecordingSid" => "REafd66b74b49551a69593c41da1d638c0",
      "RecordingSource" => "StartCallRecordingAPI",
      "RecordingStartTime" => "Sat, 27 Aug 2022 11:03:41 +0000",
      "RecordingStatus" => "in-progress",
      "RecordingTrack" => "both",
      "RecordingUrl" =>
        "https://api.twilio.com/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Recordings/REafd66b74b49551a69593c41da1d638c0"
    }

    recording =
      params
      |> Recordings.insert_or_update_from_twilio_params!()
      |> Repo.reload()

    assert recording.sid == "CAcfcd3db14f143b00141b45cd0ffa3d65"
    assert recording.status == "in-progress"

    assert recording.url ==
             "https://api.twilio.com/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Recordings/REafd66b74b49551a69593c41da1d638c0"

    assert recording.params == params
  end

  test "update a recording using twilio params" do
    recording =
      recordings_fixture(
        sid: "CAcfcd3db14f143b00141b45cd0ffa3d65",
        status: "in-progress",
        url: "https://foo.bar/",
        params: %{}
      )

    Recordings.insert_or_update_from_twilio_params!(%{
      "AccountSid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      "CallSid" => "CAcfcd3db14f143b00141b45cd0ffa3d65",
      "ErrorCode" => "0",
      "RecordingChannels" => "1",
      "RecordingDuration" => "10",
      "RecordingSid" => "REafd66b74b49551a69593c41da1d638c0",
      "RecordingSource" => "StartCallRecordingAPI",
      "RecordingStartTime" => "Sat, 27 Aug 2022 11:03:41 +0000",
      "RecordingStatus" => "completed",
      "RecordingTrack" => "both",
      "RecordingUrl" =>
        "https://api.twilio.com/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Recordings/REafd66b74b49551a69593c41da1d638c0"
    })

    recording = Repo.reload(recording)

    assert recording.status == "completed"

    assert recording.url ==
             "https://api.twilio.com/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Recordings/REafd66b74b49551a69593c41da1d638c0"
  end

  test "get_recording_for_user" do
    u1 = user_fixture()
    u2 = user_fixture()

    phone_number_fixture(u1, phone: "+15554443333")
    phone_number_fixture(u2, phone: "+15554443333")

    c = call_fixture(sid: "CA001")
    r = recordings_fixture(sid: "CA001")

    users_calls_fixture(u1, c, recorded: true)
    users_calls_fixture(u2, c, recorded: false)

    assert Recordings.get_recording_for_user(u1.id, "CA001") == r
    assert Recordings.get_recording_for_user(u2.id, "CA001") == nil
  end
end
