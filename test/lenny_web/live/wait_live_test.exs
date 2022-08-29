defmodule LennyWeb.WaitLiveTest do
  use LennyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lenny.PhoneNumbersFixtures
  import Lenny.CallsFixtures
  import Lenny.PhoneNumbersFixtures
  import Lenny.UsersCallsFixtures

  alias Lenny.Repo

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

  test "/wait redirects if there is a pending phone number", %{conn: conn, user: user} do
    phone_number_fixture(user)
    phone_number_fixture(user, verified_at: nil)

    {:ok, _live_view, _html} =
      live(conn, "/wait")
      |> follow_redirect(conn, "/phone_numbers/verify")
  end

  test "delete a call", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+15552223333", verified_at: ~N[2022-08-29 12:14:59])

    c1 = call_fixture(sid: "CA0001", from: "+15552220001", ended_at: ~N[2022-08-29 13:31:38])
    c2 = call_fixture(sid: "CA0002", from: "+15552220002", ended_at: ~N[2022-08-29 13:31:57])

    users_calls_fixture(user, c1)
    users_calls_fixture(user, c2)

    {:ok, live_view, html} = live(conn, "/wait")

    assert html =~ "+15552220001"
    assert html =~ "+15552220002"

    {:ok, live_view, _html} =
      live_view
      |> element("a", "+15552220001")
      |> render_click()
      |> follow_redirect(conn, "/calls/CA0001")

    _html =
      live_view
      |> element("button", "Delete")
      |> render_click()

    {:ok, _live_view, html} =
      live_view
      |> element("button", "Yes")
      |> render_click()
      |> follow_redirect(conn, "/wait")

    refute html =~ "+15552220001"
    assert html =~ "+15552220002"
  end

  test "loading the wait page redirects to the single active call", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+15555551234", verified_at: ~N[2022-08-29 15:00:41])

    c = call_fixture(sid: "CA0001", ended_at: nil)
    uc = users_calls_fixture(user, c, seen_at: nil)

    {:ok, _live_view, _html} =
      live(conn, "/wait")
      |> follow_redirect(conn, "/calls/CA0001")

    assert Repo.reload!(uc).seen_at != nil

    {:ok, _live_view, html} =
      live(conn, "/wait")

    assert html =~ "Your Verified Phone Number"
  end

  test "/wait automatically updates active calls", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+15551231234")

    c1 = call_fixture(from: "+12223330001", ended_at: ~N[2022-08-29 15:12:24])
    c2 = call_fixture(from: "+12223330002", ended_at: nil)

    users_calls_fixture(user, c1, seen_at: ~N[2022-08-29 15:14:00])
    users_calls_fixture(user, c2, seen_at: ~N[2022-08-29 15:14:30])

    {:ok, live_view, _html} = live(conn, "/wait")
    refute live_view |> element("#call-#{c1.sid}") |> render() =~ "Connected"
    assert live_view |> element("#call-#{c2.sid}") |> render() =~ "Connected"

    Phoenix.ConnTest.build_conn()
    |> post("/twilio/status/call", %{"CallSid" => c2.sid, "CallStatus" => "completed"})

    refute live_view |> element("#call-#{c1.sid}") |> render() =~ "Connected"
    refute live_view |> element("#call-#{c2.sid}") |> render() =~ "Connected"
  end
end
