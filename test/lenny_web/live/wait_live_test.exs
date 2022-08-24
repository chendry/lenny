defmodule LennyWeb.WaitLiveTest do
  use LennyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lenny.PhoneNumbersFixtures
  import Lenny.CallsFixtures

  setup [:register_and_log_in_user]

  test "incoming calls trigger redirect to call", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+13126180256")

    {:ok, live_view, _html} = live(conn, "/wait")

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

    assert html =~ ~S{data-sid="CAXXXX1234"}
  end

  test "loading /wait with multiple active calls shows links for those calls", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+12223334444")

    call_fixture(sid: "CA001", from: "+12223334444")
    call_fixture(sid: "CA002", from: "+12223334444", forwarded_from: "+14445556666")
    call_fixture(sid: "CA003", from: "+15555555555")
    call_fixture(sid: "CA004", from: "+15555555555")
    call_fixture(sid: "CA005", from: "+12223334444", ended_at: ~N[2022-08-24 00:51:20])

    {:ok, live_view, _html} = live(conn, "/wait")

    html =
      live_view
      |> element("ul#calls")
      |> render()

    assert html =~ "+12223334444"
    assert html =~ "+14445556666"
    refute html =~ "+15555555555"

    live_view
    |> element("a", "+14445556666")
    |> render_click()
    |> follow_redirect(conn, "/calls/CA002")
  end
end
