defmodule LennyWeb.CallLiveTest do
  use LennyWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Lenny.AccountsFixtures
  import Lenny.PhoneNumbersFixtures
  import Lenny.CallsFixtures
  import Lenny.UsersCallsFixtures

  alias Lenny.Repo

  describe "when authenticated" do
    setup [:register_and_log_in_user]

    test "call status webhook with CallStatus=completed ends the call", %{conn: conn, user: user} do
      call = call_fixture(sid: "CAf173")
      users_calls_fixture(user, call)

      {:ok, live_view, html} = live(conn, "/calls/CAf173")
      assert html =~ ~S(data-sid="CAf173")

      Phoenix.ConnTest.build_conn()
      |> post("/twilio/status/call", %{"CallSid" => "CAf173", "CallStatus" => "completed"})

      assert render(live_view) =~ "Call ended"
      assert Repo.reload!(call).ended_at != nil
    end

    test "push the say buttons during a call", %{conn: conn, user: user} do
      call = call_fixture(sid: "CAa820")
      users_calls_fixture(user, call)

      {:ok, live_view, _html} = live(conn, "/calls/CAa820")

      Mox.expect(Lenny.TwilioMock, :modify_call, fn "CAa820", twiml ->
        assert twiml =~ "lenny_01.mp3"
        assert twiml =~ "/twilio/gather/1"
      end)

      _html =
        live_view
        |> element("button#say_01")
        |> render_click()

      Mox.expect(Lenny.TwilioMock, :modify_call, fn "CAa820", twiml ->
        assert twiml =~ "lenny_03.mp3"
        assert twiml =~ "/twilio/gather/3"
      end)

      _html =
        live_view
        |> element("button#say_03")
        |> render_click()
    end

    test "clicking the autopilot checkbox toggles autopilot on the record", %{conn: conn, user: user} do
      call = call_fixture(sid: "CA7f8b", autopilot: true)
      users_calls_fixture(user, call)

      {:ok, live_view, _html} = live(conn, "/calls/CA7f8b")

      live_view
      |> element("#autopilot")
      |> render_click()

      assert Repo.reload(call).autopilot == false
    end

    test "push the say buttons with autopilot on", %{conn: conn, user: user} do
      call = call_fixture(sid: "CA4b93", autopilot: true)
      users_calls_fixture(user, call)

      {:ok, live_view, _html} = live(conn, "/calls/CA4b93")

      assert render(element(live_view, "#autopilot")) =~ "checked"

      Mox.expect(Lenny.TwilioMock, :modify_call, fn "CA4b93", twiml ->
        assert twiml =~ "lenny_07.mp3"
        assert twiml =~ "/twilio/gather/7"
      end)

      _html =
        live_view
        |> element("button#say_07")
        |> render_click()
    end

    test "push the say buttons with autopilot off", %{conn: conn, user: user} do
      call = call_fixture(sid: "CA02fc", autopilot: false)
      users_calls_fixture(user, call)

      {:ok, live_view, _html} = live(conn, "/calls/CA02fc")

      refute render(element(live_view, "#autopilot")) =~ "checked"

      Mox.expect(Lenny.TwilioMock, :modify_call, fn "CA02fc", twiml ->
        assert twiml =~ "lenny_07.mp3"
        refute twiml =~ "/twilio/gather/7"
      end)

      live_view
      |> element("button#say_07")
      |> render_click()
    end

    test "push the last say button", %{conn: conn, user: user} do
      call = call_fixture(sid: "CAc482", autopilot: true)
      users_calls_fixture(user, call)

      {:ok, live_view, _html} = live(conn, "/calls/CAc482")

      Mox.expect(Lenny.TwilioMock, :modify_call, fn "CAc482", twiml ->
        assert twiml =~ "lenny_16.mp3"
        refute twiml =~ "/twilio/gather/7"
      end)

      live_view
      |> element("button#say_16")
      |> render_click()
    end

    test "push the hello buttons with autopilot on", %{conn: conn, user: user} do
      call = call_fixture(sid: "CAf068", iteration: 3, autopilot: true)
      users_calls_fixture(user, call)

      {:ok, live_view, _html} = live(conn, "/calls/CAf068")

      Enum.each(~w(hello hello_are_you_there), fn button ->
        Mox.expect(Lenny.TwilioMock, :modify_call, fn "CAf068", twiml ->
          assert twiml =~ "#{button}.mp3"
          assert twiml =~ "/twilio/gather/3"
        end)

        live_view
        |> element("##{button}")
        |> render_click()
      end)
    end

    test "push the hello buttons with autopilot off", %{conn: conn, user: user} do
      call = call_fixture(sid: "CAf068", iteration: 3, autopilot: false)
      users_calls_fixture(user, call)

      {:ok, live_view, _html} = live(conn, "/calls/CAf068")

      Enum.each(~w(hello hello_are_you_there), fn button ->
        Mox.expect(Lenny.TwilioMock, :modify_call, fn "CAf068", twiml ->
          assert twiml =~ "#{button}.mp3"
          refute twiml =~ "/twilio/gather/3"
        end)

        live_view
        |> element("##{button}")
        |> render_click()
      end)
    end

    test "push the DTMF buttons", %{conn: conn, user: user} do
      phone_number_fixture(user)
      call = call_fixture(sid: "CA7923")
      users_calls_fixture(user, call)

      {:ok, live_view, _html} = live(conn, "/calls/CA7923")

      Mox.expect(Lenny.TwilioMock, :modify_call, fn "CA7923", twiml ->
        assert twiml =~ ~r{<Response>\s*<Play digits="1"}
      end)

      _html =
        live_view
        |> element("#dtmf-1")
        |> render_click()

      Mox.expect(Lenny.TwilioMock, :modify_call, fn "CA7923", twiml ->
        assert twiml =~ ~r{<Response>\s*<Play digits="#"}
      end)

      _html =
        live_view
        |> element("#dtmf-pound")
        |> render_click()
    end

    test "push the silence button", %{conn: conn, user: user} do
      call = call_fixture(sid: "CA6b37")
      users_calls_fixture(user, call)

      {:ok, live_view, _html} = live(conn, "/calls/CA6b37")

      Mox.expect(Lenny.TwilioMock, :modify_call, fn "CA6b37", twiml ->
        assert twiml =~ ~s{<Pause length="120" />}
        refute twiml =~ ".mp3"
      end)

      live_view
      |> element("#silence")
      |> render_click()
    end

    test "hang up", %{conn: conn, user: user} do
      call = call_fixture(sid: "CA4dc0")
      users_calls_fixture(user, call)

      {:ok, live_view, _html} = live(conn, "/calls/CA4dc0")

      Mox.expect(Lenny.TwilioMock, :modify_call, fn "CA4dc0", twiml ->
        assert twiml =~ "<Hangup />"
      end)

      assert Repo.reload!(call).ended_at == nil

      _html =
        live_view
        |> element("#hangup")
        |> render_click()

      assert Repo.reload!(call).ended_at != nil
    end

    test "visit a call that has ended", %{conn: conn, user: user} do
      call = call_fixture(sid: "CAfc43", ended_at: ~N[2022-08-26 18:07:43])
      users_calls_fixture(user, call)

      {:ok, _live_view, html} = live(conn, "/calls/CAfc43")

      assert html =~ "Call ended"
      refute html =~ "Start Audio"
    end

    test "show what the scammer says", %{conn: conn, user: user} do
      call = call_fixture(sid: "CA7b20")
      users_calls_fixture(user, call)

      {:ok, live_view, html} = live(conn, "/calls/CA7b20")

      refute html =~ "I'm a banana"

      Phoenix.ConnTest.build_conn()
      |> post("/twilio/gather/3", %{
        "CallSid" => "CA7b20",
        "SpeechResult" => "I'm a banana."
      })

      html =
        live_view
        |> element("#speech")
        |> render()

      assert html =~ "I&#39;m a banana."
    end

    test "the active button changes in response to say buttons", %{conn: conn, user: user} do
      call = call_fixture(sid: "CA9c8d")
      users_calls_fixture(user, call)

      {:ok, live_view, _html} = live(conn, "/calls/CA9c8d")

      html =
        live_view
        |> element(".active-say-button")
        |> render()

      assert html =~ "Hello, this is Lenny"

      Mox.expect(Lenny.TwilioMock, :modify_call, fn _, _ -> nil end)

      live_view
      |> element("button#say_03")
      |> render_click()

      html =
        live_view
        |> element(".active-say-button")
        |> render()

      assert html =~ "Oh good! Yes yes yes yes"
    end

    test "the active button changes on autopilot when scammer responds", %{conn: conn, user: user} do
      call = call_fixture(sid: "CA0ad9", autopilot: true)
      users_calls_fixture(user, call)

      {:ok, live_view, _html} = live(conn, "/calls/CA0ad9")

      html =
        live_view
        |> element(".active-say-button")
        |> render()

      assert html =~ "Hello, this is Lenny"

      Phoenix.ConnTest.build_conn()
      |> post("/twilio/gather/0", %{
        "CallSid" => "CA0ad9",
        "CallStatus" => "in-progress",
        "SpeechResult" => "Hello Lenny"
      })

      html =
        live_view
        |> element(".active-say-button")
        |> render()

      assert html =~ "Sorry, I can barely hear &#39;ya there."
    end

    test "scammer responding to gather on the last sound loops lenny back to somebody did call...", %{
      conn: conn,
      user: user
    } do
      call = call_fixture(sid: "CA4c2f", autopilot: true, iteration: 16)
      users_calls_fixture(user, call)

      {:ok, live_view, _html} = live(conn, "/calls/CA4c2f")

      html =
        live_view
        |> element(".active-say-button")
        |> render()

      assert html =~ "Sorry, bit of a problem..."

      Phoenix.ConnTest.build_conn()
      |> post("/twilio/gather/16", %{
        "CallSid" => "CA4c2f",
        "SpeechResult" => "What?"
      })

      html =
        live_view
        |> element(".active-say-button")
        |> render()

      assert html =~ "Someone did call last week about the same thing"
    end

    test "viewing a call marks it as seen for that user", %{user: u1, conn: conn} do
      call = call_fixture(sid: "CAccdf")

      u2 = user_fixture()

      uc1 = users_calls_fixture(u1, call, seen_at: nil)
      uc2 = users_calls_fixture(u2, call, seen_at: nil)

      {:ok, _live_view, _html} = live(conn, "/calls/CAccdf")

      assert Repo.reload!(uc1).seen_at != nil
      assert Repo.reload!(uc2).seen_at == nil
    end

    test "attempt to view a call that the user doesn't have access to", %{conn: conn} do
      call = call_fixture(sid: "CAb212")
      other_user = user_fixture()
      users_calls_fixture(other_user, call)

      {:error, {:live_redirect, %{flash: %{"alert" => alert}}}} =
        live(conn, "/calls/CAb212")

      assert alert =~ "You must be logged in"
    end

    test "breadcrumbs are visible", %{conn: conn, user: user} do
      call = call_fixture(sid: "CA8505")
      users_calls_fixture(user, call)
      {:ok, live_view, _html} = live(conn, "/calls/CA8505")
      assert live_view |> element("#breadcrumbs") |> has_element?()
    end
  end

  describe "when anonymous" do
    test "breadcrumbs are not visible", %{conn: conn} do
      call_fixture(sid: "CA1657")
      {:ok, live_view, _html} = live(conn, "/calls/CA1657")
      refute live_view |> element("#breadcrumbs") |> has_element?()
    end

    test "can't access a finished call", %{conn: conn} do
      call_fixture(sid: "CA05f5", ended_at: ~N[2022-08-29 20:11:17])

      {:error, {:live_redirect, %{flash: %{"alert" => alert}}}} =
        live(conn, "/calls/CA05f5")

      assert alert =~ "You must be logged in"
    end

    test "can't access call when any associated user has skip_auth_for_active_calls disabled", %{
      conn: conn
    } do
      call = call_fixture(sid: "CAa046")

      u1 = user_fixture(skip_auth_for_active_calls: false)
      u2 = user_fixture(skip_auth_for_active_calls: true)

      users_calls_fixture(u1, call)
      users_calls_fixture(u2, call)

      {:error, {:live_redirect, %{flash: %{"alert" => alert}}}} =
        live(conn, "/calls/CAa046")

      assert alert =~ "You must be logged in"
    end

    test "doesn't crash when a recording ends", %{conn: conn} do
      call_fixture(sid: "CAc6d9")
      {:ok, live_view, _html} = live(conn, "/calls/CAc6d9")
      send live_view.pid, :recording
      assert render(live_view) =~ ~s(data-sid="CAc6d9")
    end
  end
end
