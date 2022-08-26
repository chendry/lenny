defmodule Lenny.CallsTest do
  use Lenny.DataCase

  alias Lenny.Calls
  alias Lenny.Calls.Call
  alias Lenny.Calls.UsersCalls

  import Ecto.Query
  import Lenny.CallsFixtures
  import Lenny.AccountsFixtures
  import Lenny.PhoneNumbersFixtures

  test "create a call using twilio params for a forwarded call" do
    params = %{
      "AccountSid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      "ApiVersion" => "2010-04-01",
      "CallSid" => "CAf49023ea159a82f9c4cc192f22ff5909",
      "CallStatus" => "ringing",
      "CallToken" =>
        "%7B%22parentCallInfoToken%22%3A%22eyJhbGciOiJFUzI1NiJ9.eyJjYWxsU2lkIjoiQ0FmNDkwMjNlYTE1OWE4MmY5YzRjYzE5MmYyMmZmNTkwOSIsImZyb20iOiIrMTc3MzY1NTU3NzgiLCJ0byI6IisxOTM4NDY1MzY2OSIsImlhdCI6IjE2NjExNzYyMDQifQ.9nhKsqwHe-W4F9TBrYB3i0eskYaocBb0S1g5OJThSj_hnj9OD3uLZ_BEmzdkTotOiLpdHfdE0V80qlSh1QkABw%22%2C%22identityHeaderTokens%22%3A%5B%5D%7D",
      "Called" => "+19384653669",
      "CalledCity" => "",
      "CalledCountry" => "US",
      "CalledState" => "AL",
      "CalledVia" => "+13126180256",
      "CalledZip" => "",
      "Caller" => "+17736555778",
      "CallerCity" => "CHICAGO",
      "CallerCountry" => "US",
      "CallerState" => "IL",
      "CallerZip" => "60712",
      "Direction" => "inbound",
      "ForwardedFrom" => "+13126180256",
      "From" => "+17736555778",
      "FromCity" => "CHICAGO",
      "FromCountry" => "US",
      "FromState" => "IL",
      "FromZip" => "60712",
      "To" => "+19384653669",
      "ToCity" => "",
      "ToCountry" => "US",
      "ToState" => "AL",
      "ToZip" => ""
    }

    %{id: id} = Calls.create_from_twilio_params!(params)
    call = Repo.get(Call, id)

    assert call.id != nil
    assert call.to == "+19384653669"
    assert call.from == "+17736555778"
    assert call.forwarded_from == "+13126180256"
    assert call.ended_at == nil
    assert call.params == params
  end

  test "create a call using twilio params for a direct call" do
    params = %{
      "AccountSid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      "ApiVersion" => "2010-04-01",
      "CallSid" => "CA64c65dc07b71ce03c2dfde69bd575b45",
      "CallStatus" => "ringing",
      "CallToken" =>
        "%7B%22parentCallInfoToken%22%3A%22eyJhbGciOiJFUzI1NiJ9.eyJjYWxsU2lkIjoiQ0E2NGM2NWRjMDdiNzFjZTAzYzJkZmRlNjliZDU3NWI0NSIsImZyb20iOiIrMTMxMjYxODAyNTYiLCJ0byI6IisxOTM4NDY1MzY2OSIsImlhdCI6IjE2NjExNzk3MTAifQ.olYkQE1c6OC_jGuvzBWIwK0_qInNQYS15zRxuXhUvCpsezgR51T85AYa2JWCMetgMtlDcV9Mr0SfjbD6jsHmJg%22%2C%22identityHeaderTokens%22%3A%5B%5D%7D",
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

    %{id: id} = Calls.create_from_twilio_params!(params)
    call = Repo.get(Call, id)

    assert call.id != nil
    assert call.to == "+19384653669"
    assert call.from == "+13126180256"
    assert call.forwarded_from == nil
    assert call.ended_at == nil
    assert call.params == params
  end

  test "save_and_broadcast_call" do
    call =
      call_fixture(
        sid: "CA001",
        autopilot: true,
        speech: nil,
        ended_at: nil,
        iteration: 0
      )

    Phoenix.PubSub.subscribe(Lenny.PubSub, "call:CA001")

    Calls.save_and_broadcast_call(
      call,
      autopilot: false,
      speech: "hi",
      ended_at: ~N[2022-08-26 18:12:33],
      iteration: 1
    )

    call = Repo.get(Call, call.id)

    assert call.autopilot == false
    assert call.speech == "hi"
    assert call.ended_at == ~N[2022-08-26 18:12:33]
    assert call.iteration == 1

    assert_received {
      :call,
      %Call{
        sid: "CA001",
        autopilot: false,
        speech: "hi",
        ended_at: ~N[2022-08-26 18:12:33],
        iteration: 1
      }
    }
  end

  test "new calls are associated with users based on verified phone numbers" do
    u1 = user_fixture()
    u2 = user_fixture()
    u3a = user_fixture()
    u3b = user_fixture()

    phone_number_fixture(u1, phone: "+13126180001")
    phone_number_fixture(u1, phone: "+13126180002", verified_at: nil)
    phone_number_fixture(u1, phone: "+13126180003", deleted_at: ~N[2022-08-26 21:33:16])

    phone_number_fixture(u2, phone: "+13126180002")

    phone_number_fixture(u3a, phone: "+13126180003")
    phone_number_fixture(u3b, phone: "+13126180003")

    call =
      Calls.create_from_twilio_params!(%{
        "CallSid" => "CA001",
        "From" => "+13126180001",
        "ForwardedFrom" => nil,
        "To" => "+1888GOLENNY"
      })

    assert Repo.all(
             from uc in UsersCalls,
               where: [call_id: ^call.id],
               select: uc.user_id,
               order_by: uc.user_id
           ) == [u1.id]

    call =
      Calls.create_from_twilio_params!(%{
        "CallSid" => "CA002",
        "From" => "+13126180002",
        "ForwardedFrom" => nil,
        "To" => "+1888GOLENNY"
      })

    assert Repo.all(
             from uc in UsersCalls,
               where: [call_id: ^call.id],
               select: uc.user_id,
               order_by: uc.user_id
           ) == [u2.id]

    call =
      Calls.create_from_twilio_params!(%{
        "CallSid" => "CA003",
        "From" => "+13126180003",
        "ForwardedFrom" => nil,
        "To" => "+1888GOLENNY"
      })

    assert Repo.all(
             from uc in UsersCalls,
               where: [call_id: ^call.id],
               select: uc.user_id,
               order_by: uc.user_id
           ) == [u3a.id, u3b.id]
  end
end
