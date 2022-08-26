defmodule LennyWeb.WaitLiveTest do
  use LennyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lenny.PhoneNumbersFixtures

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
end
