defmodule LennyWeb.WaitLiveTest do
  use LennyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lenny.PhoneNumbersFixtures
  import Lenny.CallsFixtures

  setup [:register_and_log_in_user]

  test "incoming calls trigger redirect to call", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+13126180256")

    {:ok, live_view, html} = live(conn, "/wait")
    assert html =~ "Waiting for a forwarded call..."

    Phoenix.ConnTest.build_conn()
    |> post("/twilio/incoming", %{"CallSid" => "CAXXX", "From" => "+13126180256"})

    assert_redirect(live_view, "/calls/CAXXX")
  end

  test "loading /wait with a single active call redirects to that call", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+13126180256")
    call_fixture(sid: "CAXXXX1234", from: "+13126180256")

    {:ok, _live_view, html} =
      live(conn, "/wait")
      |> follow_redirect(conn, "/calls/CAXXXX1234")

    assert html =~ "Active call: CAXXXX1234"
  end
end
