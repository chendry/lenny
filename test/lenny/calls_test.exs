defmodule Lenny.CallsTest do
  use Lenny.DataCase

  alias Lenny.Calls
  alias Lenny.Calls.Call
  alias Lenny.Calls.UsersCalls
  alias Lenny.PhoneNumbers.PhoneNumber

  import Lenny.CallsFixtures
  import Lenny.AccountsFixtures
  import Lenny.PhoneNumbersFixtures
  import Lenny.UsersCallsFixtures

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

  test "new calls are associated with users based on verified phone numbers at the time" do
    u1 = user_fixture()
    u2 = user_fixture()
    u3a = user_fixture()
    u3b = user_fixture()
    u4 = user_fixture()
    u5 = user_fixture()

    phone_number_fixture(u1, phone: "+13126180001")
    phone_number_fixture(u1, phone: "+13126180002", verified_at: nil)
    phone_number_fixture(u1, phone: "+13126180003", deleted_at: ~N[2022-08-26 21:33:16])
    phone_number_fixture(u2, phone: "+13126180002")
    phone_number_fixture(u3a, phone: "+13126180003")
    phone_number_fixture(u3b, phone: "+13126180003")
    phone_number_fixture(u4, phone: "+13126180004")
    phone_number_fixture(u5, phone: "+13126180005")

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA001",
      "From" => "+13126180001",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA002",
      "From" => "+13126180002",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA003",
      "From" => "+13126180003",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA004",
      "From" => "+15554443333",
      "ForwardedFrom" => "+13126180004",
      "To" => "+1888GOLENNY"
    })

    call_sids_for_user = fn user ->
      Repo.all(
        from uc in UsersCalls,
          join: c in assoc(uc, :call),
          where: uc.user_id == ^user.id,
          order_by: uc.id,
          select: c.sid
      )
    end

    assert call_sids_for_user.(u1) == ["CA001"]
    assert call_sids_for_user.(u2) == ["CA002"]
    assert call_sids_for_user.(u3a) == ["CA003"]
    assert call_sids_for_user.(u3b) == ["CA003"]
    assert call_sids_for_user.(u4) == ["CA004"]
    assert call_sids_for_user.(u5) == []

    PhoneNumber
    |> Repo.update_all(set: [deleted_at: ~N[2022-08-28 12:56:43]])

    phone_number_fixture(u1, phone: "+13126180005")
    phone_number_fixture(u2, phone: "+13126180004")
    phone_number_fixture(u3a, phone: "+13126180002")
    phone_number_fixture(u3b, phone: "+13126180002")
    phone_number_fixture(u4, phone: "+13126180003")
    phone_number_fixture(u5, phone: "+13126180001")

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA011",
      "From" => "+13126180001",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA012",
      "From" => "+13126180002",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA013",
      "From" => "+13126180003",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA014",
      "From" => "+13126180004",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA015",
      "From" => "+13126180005",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    assert call_sids_for_user.(u1) == ["CA001", "CA015"]
    assert call_sids_for_user.(u2) == ["CA002", "CA014"]
    assert call_sids_for_user.(u3a) == ["CA003", "CA012"]
    assert call_sids_for_user.(u3b) == ["CA003", "CA012"]
    assert call_sids_for_user.(u4) == ["CA004", "CA013"]
    assert call_sids_for_user.(u5) == ["CA011"]
  end

  test "recorded flag is not on user_calls based on user's record_call setting at the time" do
    u1a = user_fixture(record_calls: true)
    u1b = user_fixture(record_calls: false)

    phone_number_fixture(u1a, phone: "+13125550001", verified_at: ~N[2022-08-27 17:46:20])
    phone_number_fixture(u1b, phone: "+13125550001", verified_at: ~N[2022-08-27 17:46:20])

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA0001",
      "From" => "+13125550001",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    call_recorded_flags_for_user = fn user ->
      Repo.all(
        from uc in UsersCalls,
          where: uc.user_id == ^user.id,
          order_by: uc.id,
          select: uc.recorded
      )
    end

    assert call_recorded_flags_for_user.(u1a) == [true]
    assert call_recorded_flags_for_user.(u1b) == [false]

    u1a
    |> change(record_calls: false)
    |> Repo.update!()

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA0002",
      "From" => "+13125550001",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    assert call_recorded_flags_for_user.(u1a) == [true, false]
    assert call_recorded_flags_for_user.(u1b) == [false, false]
  end

  test "should_record_call? is true if any associated user is recording calls" do
    u1a = user_fixture(record_calls: true)
    u1b = user_fixture(record_calls: false)

    phone_number_fixture(u1a, phone: "+13125550001", verified_at: ~N[2022-08-27 17:46:20])
    phone_number_fixture(u1b, phone: "+13125550001", verified_at: ~N[2022-08-27 17:46:20])

    call =
      Calls.create_from_twilio_params!(%{
        "CallSid" => "CA0001",
        "From" => "+13125550001",
        "ForwardedFrom" => nil,
        "To" => "+1888GOLENNY"
      })

    assert Calls.should_record_call?(call)
  end

  test "should_record_call? is false if no associated user is recording calls" do
    u1a = user_fixture(record_calls: false)
    u1b = user_fixture(record_calls: false)

    phone_number_fixture(u1a, phone: "+13125550001", verified_at: ~N[2022-08-27 17:46:20])
    phone_number_fixture(u1b, phone: "+13125550001", verified_at: ~N[2022-08-27 17:46:20])

    call =
      Calls.create_from_twilio_params!(%{
        "CallSid" => "CA0001",
        "From" => "+13125550001",
        "ForwardedFrom" => nil,
        "To" => "+1888GOLENNY"
      })

    refute Calls.should_record_call?(call)
  end

  test "get_sole_unseen_active_call_for_user" do
    u1 = user_fixture()
    u2 = user_fixture()

    c1 = call_fixture(ended_at: nil)
    uc1 = users_calls_fixture(u1, c1, seen_at: nil)

    assert Calls.get_sole_unseen_active_call_for_user(u1.id) == c1.sid
    assert Calls.get_sole_unseen_active_call_for_user(u2.id) == nil

    Repo.update!(change(uc1, seen_at: ~N[2022-08-29 14:47:20]))

    assert Calls.get_sole_unseen_active_call_for_user(u1.id) == nil

    c2 = call_fixture(ended_at: ~N[2022-08-29 14:48:55])
    users_calls_fixture(u1, c2, seen_at: nil)

    assert Calls.get_sole_unseen_active_call_for_user(u1.id) == nil

    c3 = call_fixture(ended_at: nil)
    c4 = call_fixture(ended_at: nil)
    users_calls_fixture(u1, c3)
    users_calls_fixture(u1, c4)

    assert Calls.get_sole_unseen_active_call_for_user(u1.id) == nil
  end

  test "anonyomus users can access calls not registered to any user" do
    call = call_fixture(sid: "CA0001", from: "+3125551234")
    assert Calls.get_call_for_user!(nil, "CA0001") == call
  end

  test "anonyomus users can't access calls registered a user" do
    call = call_fixture(sid: "CA0001", from: "+3125551234")
    user = user_fixture()
    users_calls_fixture(user, call)

    assert catch_error(Calls.get_call_for_user!(nil, "CA0001"))
  end

  test "users can access calls associated with them" do
    call = call_fixture(sid: "CA0001", from: "+3125551234")
    user = user_fixture()
    users_calls_fixture(user, call)
    assert Calls.get_call_for_user!(user, "CA0001") == call
  end

  test "users can't access deleted calls associated with them" do
    call = call_fixture(sid: "CA0001", from: "+3125551234")
    user = user_fixture()
    users_calls_fixture(user, call, deleted_at: ~N[2022-08-29 16:57:03])
    assert catch_error(Calls.get_call_for_user!(user, "CA0001"))
  end

  test "users can't access calls associated to uther users but not them" do
    call = call_fixture(sid: "CA0001", from: "+3125551234")
    other_user = user_fixture()
    users_calls_fixture(other_user, call, deleted_at: ~N[2022-08-29 16:57:03])
    user = user_fixture()
    assert catch_error(Calls.get_call_for_user!(user, "CA0001"))
  end
end
