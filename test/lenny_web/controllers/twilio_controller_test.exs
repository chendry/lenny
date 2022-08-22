defmodule LennyWeb.TwilioControllerTest do
  use LennyWeb.ConnCase

  test "POST /", %{conn: conn} do
    conn = post(conn, "/twilio", %{"CallSid" => "foobar"})
    assert response(conn, 200) =~ "lenny_01.mp3"
  end
end
