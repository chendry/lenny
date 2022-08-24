defmodule LennyWeb.PhoneNumberLiveTest do
  use LennyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lenny.PhoneNumbersFixtures
  import Lenny.CallsFixtures

  setup [:register_and_log_in_user]

  test "register a number", %{conn: conn} do
    {:ok, live_view, html} = live(conn, "/phone_numbers/new")

    assert html =~ ~r{<h1.*>\s*Register a Phone Number}

    html =
      live_view
      |> form("form", %{"phone_number[phone]" => "555-555-5555"})
      |> render_submit()

    assert html =~ ~r{<h1.*>\s*Register a Phone Number}
    assert html =~ "has invalid format"

    Lenny.TwilioMock
    |> Mox.expect(:verify_start, fn "+13126180256", "sms" -> {:ok, "VE-XXXX"} end)
    |> Mox.expect(:verify_check, fn "VE-XXXX", "1234" ->
      {:error, "invalid according to twilio"}
    end)
    |> Mox.expect(:verify_check, fn "VE-XXXX", "5678" -> :ok end)

    html =
      live_view
      |> form("form", %{"phone_number[phone]" => "+13126180256"})
      |> render_submit()

    assert html =~ ~r{<h1.*>\s*Verify your Phone Number}

    html =
      live_view
      |> form("form", %{"verification_form[code]" => "1234"})
      |> render_submit()

    assert html =~ ~r{<h1.*>\s*Verify your Phone Number}
    assert html =~ "invalid according to twilio"

    {:ok, _live_view, html} =
      live_view
      |> form("form", %{"verification_form[code]" => "5678"})
      |> render_submit()
      |> follow_redirect(conn, "/wait")

    assert html =~ ~S{<span id="approved-number">+13126180256</span>}
  end

  test "change a number", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+13126180256")

    {:ok, live_view, html} = live(conn, "/wait")

    assert html =~ "+13126180256"

    {:ok, live_view, _html} =
      live_view
      |> element("a", "Change")
      |> render_click()
      |> follow_redirect(conn, "/phone_numbers/new")

    Lenny.TwilioMock
    |> Mox.expect(:verify_start, fn "+13125551234", "sms" -> {:ok, "VE-XXXX"} end)
    |> Mox.expect(:verify_check, fn "VE-XXXX", "9999" -> :ok end)

    html =
      live_view
      |> form("form", %{"phone_number[phone]" => "+13125551234"})
      |> render_submit()

    assert html =~ "+13125551234"

    {:ok, _live_view, html} =
      live_view
      |> form("form", %{"verification_form[code]" => "9999"})
      |> render_submit()
      |> follow_redirect(conn, "/wait")

    refute html =~ "Pending: +13125551234"
    assert html =~ "+13125551234"
  end

  test "cancel changing a number", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+15551112222")

    {:ok, live_view, html} = live(conn, "/wait")

    assert html =~ ~S{<span id="approved-number">+15551112222</span>}

    {:ok, live_view, html} =
      live_view
      |> element("a", "Change")
      |> render_click()
      |> follow_redirect(conn, "/phone_numbers/new")

    assert html =~ ~r{<h1.*>\s*Change your Phone Number}

    Lenny.TwilioMock
    |> Mox.expect(:verify_start, fn "+15551113333", "sms" -> {:ok, "VE-XXXX"} end)
    |> Mox.expect(:verify_cancel, fn "VE-XXXX" -> :ok end)

    html =
      live_view
      |> form("form", %{"phone_number[phone]" => "+15551113333"})
      |> render_submit()

    assert html =~ ~S(<span id="pending-number">+15551113333</span>)

    {:ok, _live_view, html} =
      live_view
      |> element("a", "Cancel")
      |> render_click()
      |> follow_redirect(conn, "/wait")

    assert html =~ ~S{<span id="approved-number">+15551112222</span>}
    refute html =~ "+15551113333"
  end

  test "change number to a number with an active call", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+13126180256")
    call_fixture(sid: "CAXXXX5678", from: "+15551231234")

    {:ok, live_view, _html} = live(conn, "/wait")

    {:ok, live_view, html} =
      live_view
      |> element("a", "Change Number")
      |> render_click()
      |> follow_redirect(conn, "/phone_numbers/new")

    assert html =~ "Change your Phone Number"

    Lenny.TwilioMock
    |> Mox.expect(:verify_start, fn "+15551231234", "sms" -> {:ok, "VE-XXXX"} end)
    |> Mox.expect(:verify_check, fn "VE-XXXX", "1234" -> :ok end)

    _html =
      live_view
      |> form("form", %{"phone_number[phone]" => "+15551231234"})
      |> render_submit()

    {:ok, _live_view, html} =
      live_view
      |> form("form", %{"verification_form[code]" => "1234"})
      |> render_submit()
      |> follow_redirect(conn, "/wait")
      |> follow_redirect(conn, "/calls/CAXXXX5678")

    assert html =~ ~S{data-sid="CAXXXX5678"}
  end
end
