defmodule LennyWeb.PhoneNumberLiveTest do
  use LennyWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Lenny.PhoneNumbersFixtures

  setup [:register_and_log_in_user]

  test "register a number using sms and voice", %{conn: conn} do
    Enum.each(~w(sms call), fn channel ->
      {:ok, live_view, _html} = live_isolated(conn, LennyWeb.PhoneNumberLive)

      html =
        live_view
        |> form(
          "form",
          %{
            "phone_number[phone]" => "555-555-5555",
            "phone_number[channel]" => channel
          }
        )
        |> render_submit()

      assert html =~ "has invalid format"

      Mox.expect(Lenny.TwilioMock, :verify_start, fn "+13125550001", ^channel ->
        {:ok, %{sid: "VEea7f", carrier: %{}}}
      end)

      html =
        live_view
        |> form(
          "form",
          %{
            "phone_number[phone]" => "3125550001",
            "phone_number[channel]" => channel
          }
        )
        |> render_submit()

      assert html =~ ~r{We sent a code}

      Mox.expect(Lenny.TwilioMock, :verify_check, fn "VEea7f", "1234" ->
        {:error, "invalid according to twilio"}
      end)

      html =
        live_view
        |> form("form", %{"verification_form[code]" => "1234"})
        |> render_submit()

      assert html =~ "invalid according to twilio"

      Mox.expect(Lenny.TwilioMock, :verify_check, fn "VEea7f", "5678" -> :ok end)

      {:ok, _live_view, html} =
        live_view
        |> form("form", %{"verification_form[code]" => "5678"})
        |> render_submit()
        |> follow_redirect(conn, "/calls")

      assert html =~ ~S{<span id="verified-number" data-number="+13125550001"}
    end)
  end

  test "change a number", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+13125550001")

    {:ok, live_view, _html} = live_isolated(conn, LennyWeb.PhoneNumberLive)

    Mox.expect(Lenny.TwilioMock, :verify_start, fn "+13125550002", "sms" ->
      {:ok, %{sid: "VEbc85", carrier: %{}}}
    end)

    html =
      live_view
      |> form(
        "form",
        %{
          "phone_number[phone]" => "3125550002",
          "phone_number[channel]" => "sms"
        }
      )
      |> render_submit()

    assert html =~ ~S(<span id="pending-number" data-number="+13125550002")

    Mox.expect(Lenny.TwilioMock, :verify_check, fn "VEbc85", "9999" -> :ok end)

    {:ok, _live_view, html} =
      live_view
      |> form("form", %{"verification_form[code]" => "9999"})
      |> render_submit()
      |> follow_redirect(conn, "/calls")

    assert html =~ ~s(<span id="verified-number" data-number="+13125550002")
  end

  test "cancel changing a number", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+13125550001")

    {:ok, live_view, _html} = live_isolated(conn, LennyWeb.PhoneNumberLive)

    Mox.expect(Lenny.TwilioMock, :verify_start, fn "+13125550002", "sms" ->
      {:ok, %{sid: "VE86a9", carrier: %{}}}
    end)

    html =
      live_view
      |> form(
        "form",
        %{
          "phone_number[phone]" => "3125550002",
          "phone_number[channel]" => "sms"
        }
      )
      |> render_submit()

    assert html =~ ~S(<span id="pending-number" data-number="+13125550002")

    Mox.expect(Lenny.TwilioMock, :verify_cancel, fn "VE86a9" -> :ok end)

    {:ok, _live_view, html} =
      live_view
      |> element("a", "Cancel")
      |> render_click()
      |> follow_redirect(conn, "/calls")

    assert html =~ ~S{<span id="verified-number" data-number="+13125550001"}
  end

  test "prompts to verify if there is a pending phone number", %{conn: conn, user: user} do
    phone_number_fixture(user)
    phone_number_fixture(user, verified_at: nil)

    {:ok, _live_view, html} = live_isolated(conn, LennyWeb.PhoneNumberLive)

    assert html =~ ~S{phx-submit="verify_phone_number"}
  end
end
