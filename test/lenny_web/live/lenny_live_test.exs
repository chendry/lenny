defmodule LennyWeb.LennyLiveTest do
  use LennyWeb.ConnCase

  import Mox
  import Phoenix.LiveViewTest

  alias Lenny.Repo
  alias Lenny.PhoneNumbers.PhoneNumber

  setup [:register_and_log_in_user]

  test "register a number", %{conn: conn} do
    {:ok, lenny_live, html} = live(conn, "/lenny/new")

    assert html =~ ~r{<h1.*>\s*Register a phone number}

    html =
      lenny_live
      |> form("form", %{"phone_number[phone]" => "555-555-5555"})
      |> render_submit()

    assert html =~ ~r{<h1.*>\s*Register a phone number}
    assert html =~ "has invalid format"

    Lenny.TwilioMock
    |> expect(:verify_start, fn "+13126180256", "sms" -> {:ok, "VE-XXXX"} end)
    |> expect(:verify_check, fn "VE-XXXX", "1234" -> {:error, "invalid according to twilio"} end)
    |> expect(:verify_check, fn "VE-XXXX", "5678" -> :ok end)

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

    html =
      lenny_live
      |> form("form", %{"verification_form[code]" => "5678"})
      |> render_submit()

    assert html =~ "Approved: +13126180256"
  end

  test "change a number", %{conn: conn, user: user} do
    %PhoneNumber{
      user_id: user.id,
      phone: "+13126180256",
      status: "approved"
    }
    |> Repo.insert!()

    {:ok, lenny_live, html} = live(conn, "/lenny")

    assert html =~ ~r{<h1.*>\s*Waiting for a forwarded call}
    assert html =~ "Approved: +13126180256"

    html =
      lenny_live
      |> element("a", "Change")
      |> render_click()

    assert html =~ ~r{<h1.*>\s*Change your phone number}

    Lenny.TwilioMock
    |> expect(:verify_start, fn "+13125551234", "sms" -> {:ok, "VE-XXXX"} end)
    |> expect(:verify_check, fn "VE-XXXX", "9999" -> :ok end)

    html =
      lenny_live
      |> form("form", %{"phone_number[phone]" => "+13125551234"})
      |> render_submit()

    assert html =~ "Approved: +13126180256"
    assert html =~ "Pending: +13125551234"

    html =
      lenny_live
      |> form("form", %{"verification_form[code]" => "9999"})
      |> render_submit()

    refute html =~ "Pending: +13125551234"
    assert html =~ "Approved: +13125551234"
  end

  test "cancel changing a number", %{conn: conn, user: user} do
    %PhoneNumber{
      user_id: user.id,
      phone: "+15551112222",
      status: "approved"
    }
    |> Repo.insert!()

    {:ok, lenny_live, html} = live(conn, "/lenny")

    assert html =~ ~r{<h1.*>\s*Waiting for a forwarded call}
    assert html =~ "Approved: +15551112222"

    html =
      lenny_live
      |> element("a", "Change")
      |> render_click()

    assert html =~ ~r{<h1.*>\s*Change your phone number}

    Lenny.TwilioMock
    |> expect(:verify_start, fn "+15551113333", "sms" -> {:ok, "VE-XXXX"} end)
    |> expect(:verify_cancel, fn "VE-XXXX" -> :ok end)

    html =
      lenny_live
      |> form("form", %{"phone_number[phone]" => "+15551113333"})
      |> render_submit()

    assert html =~ "Approved: +15551112222"
    assert html =~ "Pending: +15551113333"

    html =
      lenny_live
      |> element("a", "Cancel")
      |> render_click()

    assert html =~ "Approved: +15551112222"
    refute html =~ "Pending: +15551113333"
  end
end
