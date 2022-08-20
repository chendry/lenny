defmodule LennyWeb.LennyLiveTest do
  use LennyWeb.ConnCase

  import Mox
  import Phoenix.LiveViewTest

  setup [:register_and_log_in_user]

  test "register a number", %{conn: conn} do
    {:ok, lenny_live, _html} = live(conn, "/lenny")

    assert lenny_live
           |> form("form", %{"phone_number[phone]" => "555-555-5555"})
           |> render_submit() =~ "invalid format"

    Lenny.TwilioMock
    |> expect(:verify_start, fn "+13126180256", "sms" -> {:ok, "VE-XXXX"} end)
    |> expect(:verify_check, fn "VE-XXXX", "1234" -> {:error, "invalid according to twilio"} end)
    |> expect(:verify_check, fn "VE-XXXX", "5678" -> :ok end)

    assert lenny_live
           |> form("form", %{"phone_number[phone]" => "+13126180256"})
           |> render_submit() =~ "Verify your phone number:"

    assert lenny_live
           |> form("form", %{"verification_form[code]" => "1234"})
           |> render_submit() =~ "invalid according to twilio"

    assert lenny_live
           |> form("form", %{"verification_form[code]" => "5678"})
           |> render_submit() =~ "Approved: +13126180256"
  end
end
