defmodule Lenny.RecordingsTest do
  use Lenny.DataCase

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
      |> Recordings.create_from_twilio_params!()
      |> Repo.reload()

    assert recording.sid == "CAcfcd3db14f143b00141b45cd0ffa3d65"
    assert recording.status == "in-progress"

    assert recording.url ==
             "https://api.twilio.com/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Recordings/REafd66b74b49551a69593c41da1d638c0"

    assert recording.params == params
  end
end
