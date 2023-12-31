defmodule LennyWeb.RecordingController do
  use LennyWeb, :controller

  require Logger

  alias Lenny.Recordings
  alias Lenny.TwilioImpl

  def show(conn, %{"sid" => sid}) do
    recording = Recordings.get_recording_for_user(conn.assigns.current_user.id, sid)
    path = Path.join([System.tmp_dir!(), "#{sid}.wav"])

    if not File.exists?(path) do
      credentials = Base.encode64("#{TwilioImpl.account_sid()}:#{TwilioImpl.auth_token()}")

      {:ok, :saved_to_file} =
        :httpc.request(
          :get,
          {
            String.to_charlist(recording.url),
            [{'Authorization', 'Basic #{credentials}'}]
          },
          [],
          stream: String.to_charlist(path)
        )
    end

    filename =
      DateTime.now!("America/Chicago")
      |> Calendar.strftime("%Y%m%d%H%M%S.wav")

    conn
    |> put_resp_content_type("audio/wav")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_file(200, path)
  end
end
