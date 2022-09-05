defmodule LennyWeb.CallsLiveTest do
  use LennyWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Lenny.PhoneNumbersFixtures
  import Lenny.CallsFixtures
  import Lenny.PhoneNumbersFixtures
  import Lenny.UsersCallsFixtures

  alias Lenny.Repo

  setup [:register_and_log_in_user]

  test "incoming calls trigger redirect to call", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "555-0000")

    Mox.expect(Lenny.TwilioMock, :send_sms, fn "555-0000", _ -> :ok end)

    {:ok, live_view, _html} = live(conn, "/calls")

    Phoenix.ConnTest.build_conn()
    |> post("/twilio/incoming", %{
      "CallSid" => "CA46d9",
      "From" => "555-0000",
      "To" => "+19384653669"
    })

    assert_redirect(live_view, "/calls/CA46d9")
  end

  test "/calls prompts for phone number if there is no verified or pending phone number", %{
    conn: conn
  } do
    {:ok, _live_view, html} = live(conn, "/calls")
    assert html =~ ~s(phx-submit="register_phone_number")
  end

  test "/calls prompts for verification if there is a pending phone number but no verified phone number",
       %{conn: conn, user: user} do
    phone_number_fixture(user, verified_at: nil)
    {:ok, _live_view, html} = live(conn, "/calls")
    assert html =~ ~s(phx-submit="verify_phone_number")
  end

  test "delete a call", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "555-0000", verified_at: ~N[2022-08-29 12:14:59])

    c1 = call_fixture(sid: "CAb0f3", from: "555-0001", ended_at: ~N[2022-08-29 13:31:38])
    c2 = call_fixture(sid: "CA6a4b", from: "555-0002", ended_at: ~N[2022-08-29 13:31:57])

    users_calls_fixture(user, c1)
    users_calls_fixture(user, c2)

    {:ok, live_view, html} = live(conn, "/calls")

    assert html =~ "555-0001"
    assert html =~ "555-0001"

    {:ok, live_view, _html} =
      live_view
      |> element("a", "555-0001")
      |> render_click()
      |> follow_redirect(conn, "/calls/CAb0f3")

    _html =
      live_view
      |> element("button", "Delete")
      |> render_click()

    {:ok, _live_view, html} =
      live_view
      |> element("button", "Yes")
      |> render_click()
      |> follow_redirect(conn, "/calls")

    refute html =~ "555-0001"
    assert html =~ "555-0002"
  end

  test "loading /calls redirects to the single active call", %{conn: conn, user: user} do
    c = call_fixture(sid: "CA34c5", ended_at: nil)
    uc = users_calls_fixture(user, c, seen_at: nil)

    {:ok, _live_view, _html} =
      live(conn, "/calls")
      |> follow_redirect(conn, "/calls/CA34c5")

    assert Repo.reload!(uc).seen_at != nil

    {:ok, _live_view, _html} = live(conn, "/calls")
  end

  test "/calls automatically updates active calls when their status changes", %{conn: conn, user: user} do
    phone_number_fixture(user)

    c1 = call_fixture(sid: "CA429c", ended_at: ~N[2022-08-29 15:12:24])
    c2 = call_fixture(sid: "CAc8e6", ended_at: nil)

    users_calls_fixture(user, c1, seen_at: ~N[2022-08-29 15:14:00])
    users_calls_fixture(user, c2, seen_at: ~N[2022-08-29 15:14:30])

    {:ok, live_view, _html} = live(conn, "/calls")
    refute live_view |> element("#call-CA429c") |> render() =~ "Connected"
    assert live_view |> element("#call-CAc8e6") |> render() =~ "Connected"

    Phoenix.ConnTest.build_conn()
    |> post("/twilio/status/call", %{"CallSid" => c2.sid, "CallStatus" => "completed"})

    refute live_view |> element("#call-CA429c") |> render() =~ "Connected"
    refute live_view |> element("#call-CAc8e6") |> render() =~ "Connected"
  end
end
