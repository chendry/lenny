defmodule LennyWeb.AutopilotControllerTest do
  use LennyWeb.ConnCase

  test "POST /autopilot/1", %{conn: conn} do
    conn = post(conn, "/autopilot/1", %{})
    assert response(conn, 200) =~ "lenny_02.mp3"
    refute response(conn, 200) =~ "lenny_03.mp3"
    assert response(conn, 200) =~ "/autopilot/2"
  end

  test "POST /autopilot/2", %{conn: conn} do
    conn = post(conn, "/autopilot/2", %{})
    assert response(conn, 200) =~ "lenny_03.mp3"
    refute response(conn, 200) =~ "lenny_04.mp3"
    assert response(conn, 200) =~ "/autopilot/3"
  end
end
