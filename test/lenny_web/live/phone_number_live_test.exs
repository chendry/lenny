defmodule LennyWeb.PhoneNumberLiveTest do
  use LennyWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Lenny.Repo
  alias Lenny.Calls.Call
  alias Lenny.PhoneNumbers.PhoneNumber

  setup [:register_and_log_in_user]

  test "register a number", %{conn: conn} do
    {:ok, lenny_live, html} = live(conn, "/phone_numbers/new")

    assert html =~ ~r{<h1.*>\s*Register a phone number}

    html =
      lenny_live
      |> form("form", %{"phone_number[phone]" => "555-555-5555"})
      |> render_submit()

    assert html =~ ~r{<h1.*>\s*Register a phone number}
    assert html =~ "has invalid format"

    Lenny.TwilioMock
    |> Mox.expect(:verify_start, fn "+13126180256", "sms" -> {:ok, "VE-XXXX"} end)
    |> Mox.expect(:verify_check, fn "VE-XXXX", "1234" -> {:error, "invalid according to twilio"} end)
    |> Mox.expect(:verify_check, fn "VE-XXXX", "5678" -> :ok end)

    html =
      lenny_live
      |> form("form", %{"phone_number[phone]" => "+13126180256"})
      |> render_submit()

    assert html =~ ~r{<h1.*>\s*Verify your phone number}

    html =
      lenny_live
      |> form("form", %{"verification_form[code]" => "1234"})
      |> render_submit()

    assert html =~ ~r{<h1.*>\s*Verify your phone number}
    assert html =~ "invalid according to twilio"

    {:ok, _lenny_live, html} =
      lenny_live
      |> form("form", %{"verification_form[code]" => "5678"})
      |> render_submit()
      |> follow_redirect(conn, "/calls")

    assert html =~ "Approved: +13126180256"
  end

  test "change a number", %{conn: conn, user: user} do
    %PhoneNumber{
      user_id: user.id,
      phone: "+13126180256",
      verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
    |> Repo.insert!()

    {:ok, lenny_live, html} = live(conn, "/calls")

    assert html =~ ~r{<h1.*>\s*Waiting for a forwarded call}
    assert html =~ "Approved: +13126180256"

    {:ok, lenny_live, html} =
      lenny_live
      |> element("a", "Change")
      |> render_click()
      |> follow_redirect(conn, "/phone_numbers/new")

    assert html =~ ~r{<h1.*>\s*Change your phone number}

    Lenny.TwilioMock
    |> Mox.expect(:verify_start, fn "+13125551234", "sms" -> {:ok, "VE-XXXX"} end)
    |> Mox.expect(:verify_check, fn "VE-XXXX", "9999" -> :ok end)

    html =
      lenny_live
      |> form("form", %{"phone_number[phone]" => "+13125551234"})
      |> render_submit()

    assert html =~ "Approved: +13126180256"
    assert html =~ "Pending: +13125551234"

    {:ok, _lenny_live, html} =
      lenny_live
      |> form("form", %{"verification_form[code]" => "9999"})
      |> render_submit()
      |> follow_redirect(conn, "/calls")

    refute html =~ "Pending: +13125551234"
    assert html =~ "Approved: +13125551234"
  end

  test "cancel changing a number", %{conn: conn, user: user} do
    %PhoneNumber{
      user_id: user.id,
      phone: "+15551112222",
      verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
    |> Repo.insert!()

    {:ok, lenny_live, html} = live(conn, "/calls")

    assert html =~ ~r{<h1.*>\s*Waiting for a forwarded call}
    assert html =~ "Approved: +15551112222"

    {:ok, lenny_live, html} =
      lenny_live
      |> element("a", "Change")
      |> render_click()
      |> follow_redirect(conn, "/phone_numbers/new")

    assert html =~ ~r{<h1.*>\s*Change your phone number}

    Lenny.TwilioMock
    |> Mox.expect(:verify_start, fn "+15551113333", "sms" -> {:ok, "VE-XXXX"} end)
    |> Mox.expect(:verify_cancel, fn "VE-XXXX" -> :ok end)

    html =
      lenny_live
      |> form("form", %{"phone_number[phone]" => "+15551113333"})
      |> render_submit()

    assert html =~ "Approved: +15551112222"
    assert html =~ "Pending: +15551113333"

    {:ok, _lenny_live, html} =
      lenny_live
      |> element("a", "Cancel")
      |> render_click()
      |> follow_redirect(conn, "/calls")

    assert html =~ "Approved: +15551112222"
    refute html =~ "Pending: +15551113333"
  end

  test "change number to a number with an active call", %{conn: conn, user: user} do
    %PhoneNumber{
      user_id: user.id,
      phone: "+13126180256",
      verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
    |> Repo.insert!()

    %Call{
      sid: "CAXXXX5678",
      from: "+15551231234",
      to: "+18384653669",
      ended_at: nil,
    }
    |> Repo.insert!()

    {:ok, lenny_live, html} = live(conn, "/calls")
    assert html =~ "Waiting for a forwarded call..."

    {:ok, lenny_live, html} =
      lenny_live
      |> element("a", "Change number")
      |> render_click()
      |> follow_redirect(conn, "/phone_numbers/new")

    assert html =~ "Change your phone number"

    Lenny.TwilioMock
    |> Mox.expect(:verify_start, fn "+15551231234", "sms" -> {:ok, "VE-XXXX"} end)
    |> Mox.expect(:verify_check, fn "VE-XXXX", "1234" -> :ok end)

    _html =
      lenny_live
      |> form("form", %{"phone_number[phone]" => "+15551231234"})
      |> render_submit()

    {:ok, _lenny_live, html} =
      lenny_live
      |> form("form", %{"verification_form[code]" => "1234"})
      |> render_submit()
      |> follow_redirect(conn, "/calls")

    assert html =~ "Approved: +15551231234"
    assert html =~ "Active call: CAXXXX5678"
  end
end
