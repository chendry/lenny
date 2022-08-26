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
    |> post(
      "/twilio/incoming",
      %{
        "AccountSid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
        "ApiVersion" => "2010-04-01",
        "CallSid" => "CAcd3d0f9f054366f89712ef4278630247",
        "CallStatus" => "ringing",
        "CallToken" =>
          "%7B%22parentCallInfoToken%22%3A%22eyJhbGciOiJFUzI1NiJ9.eyJjYWxsU2lkIjoiQ0FjZDNkMGY5ZjA1NDM2NmY4OTcxMmVmNDI3ODYzMDI0NyIsImZyb20iOiIrMTMxMjYxODAyNTYiLCJ0byI6IisxOTM4NDY1MzY2OSIsImlhdCI6IjE2NjE0NDYzNjIifQ.IA5Hg2PlrYTH38bybo4WQ-vzgg5hSGH3UQZRjNWxTo1hpXDUydPMyJdigR5BmN4f2gllKMR9_Ua6VoKuUOPhlw%22%2C%22identityHeaderTokens%22%3A%5B%5D%7D",
        "Called" => "+19384653669",
        "CalledCity" => "",
        "CalledCountry" => "US",
        "CalledState" => "AL",
        "CalledZip" => "",
        "Caller" => "+13126180256",
        "CallerCity" => "CHICAGO",
        "CallerCountry" => "US",
        "CallerState" => "IL",
        "CallerZip" => "60605",
        "Direction" => "inbound",
        "From" => "+13126180256",
        "FromCity" => "CHICAGO",
        "FromCountry" => "US",
        "FromState" => "IL",
        "FromZip" => "60605",
        "To" => "+19384653669",
        "ToCity" => "",
        "ToCountry" => "US",
        "ToState" => "AL",
        "ToZip" => ""
      }
    )

    assert_redirect(live_view, "/calls/CAcd3d0f9f054366f89712ef4278630247")
  end

  test "loading /wait with a single active call redirects to that call", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+13126180256")
    call_fixture(sid: "CAXXXX1234", from: "+13126180256")

    {:ok, _live_view, html} =
      live(conn, "/wait")
      |> follow_redirect(conn, "/calls/CAXXXX1234")

    assert html =~ ~S{data-sid="CAXXXX1234"}
  end

  test "loading /wait with multiple active calls shows links for those calls", %{
    conn: conn,
    user: user
  } do
    phone_number_fixture(user, phone: "+12223334444")

    call_fixture(sid: "CA001", from: "+12223334444")
    call_fixture(sid: "CA002", from: "+12223334444", forwarded_from: "+14445556666")
    call_fixture(sid: "CA003", from: "+15555555555")
    call_fixture(sid: "CA004", from: "+15555555555")
    call_fixture(sid: "CA005", from: "+12223334444", ended_at: ~N[2022-08-26 18:07:43])

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

  test "/wait redirects if there is a pending phone number", %{conn: conn, user: user} do
    phone_number_fixture(user)
    phone_number_fixture(user, verified_at: nil)

    {:ok, _live_view, _html} =
      live(conn, "/wait")
      |> follow_redirect(conn, "/phone_numbers/verify")
  end
end
