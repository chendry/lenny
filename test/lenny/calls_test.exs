defmodule Lenny.CallsTest do
  use Lenny.DataCase

  alias Lenny.Calls
  alias Lenny.Calls.Call

  import Lenny.CallsFixtures

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

  test "get_active_call returns nil when no calls are active" do
    phone = "+12223334444"

    call_fixture(from: "+15555555555", ended_at: nil)
    call_fixture(from: phone, ended_at: ~N[2022-08-23 18:39:08])
    call_fixture(from: phone, ended_at: ~N[2022-08-23 18:39:24])

    assert Calls.get_active_call(phone) == nil
  end

  test "get_active_call returns the most recent non-ended phone call" do
    phone = "+12223334444"

    _c1 = call_fixture(from: phone, ended_at: ~N[2022-08-23 18:39:08])
    _c2 = call_fixture(from: phone, ended_at: ~N[2022-08-23 18:39:24])
    c3 = call_fixture(from: phone, ended_at: nil)
    _c3 = call_fixture(from: "+15555555555", ended_at: nil)

    assert Calls.get_active_call(phone) == c3
  end
end
