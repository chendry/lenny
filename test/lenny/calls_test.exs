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
      "CallSid" => "CAafa5",
      "From" => "+13125550002",
      "ForwardedFrom" => "+13125550001",
      "To" => "+19384653669"
    }

    call = Calls.create_from_twilio_params!(params)

    assert call.id != nil
    assert call.sid == "CAafa5"
    assert call.to == "+19384653669"
    assert call.from == "+13125550002"
    assert call.forwarded_from == "+13125550001"
    assert call.ended_at == nil
    assert call.params == params
  end

  test "create a call using twilio params for a direct call" do
    params = %{
      "CallSid" => "CA1e23",
      "From" => "+13125550001",
      "To" => "+19384653669"
    }

    call = Calls.create_from_twilio_params!(params)

    assert call.id != nil
    assert call.sid == "CA1e23"
    assert call.to == "+19384653669"
    assert call.from == "+13125550001"
    assert call.forwarded_from == nil
    assert call.ended_at == nil
    assert call.params == params
  end

  test "save_and_broadcast_call" do
    call =
      call_fixture(
        sid: "CA0d81",
        autopilot: true,
        speech: nil,
        ended_at: nil,
        iteration: 0
      )

    Phoenix.PubSub.subscribe(Lenny.PubSub, "call:CA0d81")

    Calls.save_and_broadcast_call(
      call,
      autopilot: false,
      speech: "hi",
      ended_at: ~N[2022-08-26 18:12:33],
      iteration: 1
    )

    call = Repo.reload!(call)

    assert call.autopilot == false
    assert call.speech == "hi"
    assert call.ended_at == ~N[2022-08-26 18:12:33]
    assert call.iteration == 1

    assert_received {
      :call,
      %Call{
        sid: "CA0d81",
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

    phone_number_fixture(u1, phone: "555-00U1")
    phone_number_fixture(u1, phone: "555-00U2", verified_at: nil)
    phone_number_fixture(u1, phone: "555-00U3", deleted_at: ~N[2022-08-26 21:33:16])
    phone_number_fixture(u2, phone: "555-00U2")
    phone_number_fixture(u3a, phone: "555-00U3")
    phone_number_fixture(u3b, phone: "555-00U3")
    phone_number_fixture(u4, phone: "555-00U4")
    phone_number_fixture(u5, phone: "555-00U5")

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA1-555-00U1",
      "From" => "555-00U1",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA1-555-00U2",
      "From" => "555-00U2",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA1-555-00U3",
      "From" => "555-00U3",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA1-555-00U4",
      "From" => "+15554443333",
      "ForwardedFrom" => "555-00U4",
      "To" => "+1888GOLENNY"
    })

    assert call_sids_for_user(u1) == ["CA1-555-00U1"]
    assert call_sids_for_user(u2) == ["CA1-555-00U2"]
    assert call_sids_for_user(u3a) == ["CA1-555-00U3"]
    assert call_sids_for_user(u3b) == ["CA1-555-00U3"]
    assert call_sids_for_user(u4) == ["CA1-555-00U4"]
    assert call_sids_for_user(u5) == []

    Repo.update_all(PhoneNumber, set: [deleted_at: ~N[2022-08-28 12:56:43]])

    phone_number_fixture(u1, phone: "555-00U5")
    phone_number_fixture(u2, phone: "555-00U4")
    phone_number_fixture(u3a, phone: "555-00U2")
    phone_number_fixture(u3b, phone: "555-00U2")
    phone_number_fixture(u4, phone: "555-00U3")
    phone_number_fixture(u5, phone: "555-00U1")

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA2-555-00U1",
      "From" => "555-00U1",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA2-555-00U2",
      "From" => "555-00U2",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA2-555-00U3",
      "From" => "555-00U3",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA2-555-00U4",
      "From" => "555-00U4",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA2-555-00U5",
      "From" => "555-00U5",
      "ForwardedFrom" => nil,
      "To" => "+1888GOLENNY"
    })

    assert call_sids_for_user(u1) == ["CA1-555-00U1", "CA2-555-00U5"]
    assert call_sids_for_user(u2) == ["CA1-555-00U2", "CA2-555-00U4"]
    assert call_sids_for_user(u3a) == ["CA1-555-00U3", "CA2-555-00U2"]
    assert call_sids_for_user(u3b) == ["CA1-555-00U3", "CA2-555-00U2"]
    assert call_sids_for_user(u4) == ["CA1-555-00U4", "CA2-555-00U3"]
    assert call_sids_for_user(u5) == ["CA2-555-00U1"]
  end

  test "when present, only consider ForwardedFrom when associating users to call" do
    u1 = user_fixture()
    u2 = user_fixture()

    phone_number_fixture(u1, phone: "+13125550001")
    phone_number_fixture(u2, phone: "+13125550002")

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA9171",
      "From" => "+13125550001",
      "ForwardedFrom" => "+13125550002",
      "To" => "+1888GOLENNY"
    })

    assert call_sids_for_user(u1) == []
    assert call_sids_for_user(u2) == ["CA9171"]
  end

  test "when only From is present, associate to users based on From" do
    u = user_fixture()
    phone_number_fixture(u, phone: "+13125550001")

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA911b",
      "From" => "+13125550001",
      "To" => "+1888GOLENNY"
    })

    assert call_sids_for_user(u) == ["CA911b"]
  end

  test "recorded flag in user_calls is set to the user's record_call setting at the time" do
    u1a = user_fixture(record_calls: true)
    u1b = user_fixture(record_calls: false)

    phone_number_fixture(u1a, phone: "+13125550001", verified_at: ~N[2022-08-27 17:46:20])
    phone_number_fixture(u1b, phone: "+13125550001", verified_at: ~N[2022-08-27 17:46:20])

    Calls.create_from_twilio_params!(%{
      "CallSid" => "CA8bcf",
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
      "CallSid" => "CAdd98",
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
        "CallSid" => "CA5c2b",
        "From" => "+13125550001",
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
        "CallSid" => "CA724a",
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
    call = call_fixture(sid: "CA166a")
    assert Calls.get_call_for_user!(nil, "CA166a") == call
  end

  test "anonyomus users can't access calls registered a user" do
    call = call_fixture(sid: "CA4bec")
    user = user_fixture()
    users_calls_fixture(user, call)
    assert catch_error(Calls.get_call_for_user!(nil, "CA4bec"))
  end

  test "users can access calls associated with them" do
    call = call_fixture(sid: "CA731b")
    user = user_fixture()
    users_calls_fixture(user, call)
    assert Calls.get_call_for_user!(user, "CA731b") == call
  end

  test "users can't access deleted calls associated with them" do
    call = call_fixture(sid: "CA7002")
    user = user_fixture()
    users_calls_fixture(user, call, deleted_at: ~N[2022-08-29 16:57:03])
    assert catch_error(Calls.get_call_for_user!(user, "CA7002"))
  end

  test "users can't access calls associated to other users but not them" do
    other_call = call_fixture(sid: "CAa467")
    other_user = user_fixture()
    users_calls_fixture(other_user, other_call, deleted_at: ~N[2022-08-29 16:57:03])
    user = user_fixture()
    assert catch_error(Calls.get_call_for_user!(user, "CAa467"))
  end

  test "sms messages are sent for calls not associated with any user" do
    call = call_fixture()
    assert Calls.should_send_sms?(call)
  end

  test "sms messages are not sent for calls when all associated users have send_sms enabled" do
    call = call_fixture()

    u1 = user_fixture(send_sms: false)
    u2 = user_fixture(send_sms: false)

    users_calls_fixture(u1, call)
    users_calls_fixture(u2, call)

    refute Calls.should_send_sms?(call)
  end

  test "sms messages are sent for calls when any associated user has send_sms enabled" do
    call = call_fixture()

    u1 = user_fixture(send_sms: false)
    u2 = user_fixture(send_sms: true)

    users_calls_fixture(u1, call)
    users_calls_fixture(u2, call)

    assert Calls.should_send_sms?(call)
  end

  test "calls not associated with any user do not require authentication" do
    call = call_fixture()
    assert Calls.user_can_access_call?(nil, call) == true
  end

  test "active calls do not require authentication when all associated users have skip_auth_for_active_calls enabled" do
    call = call_fixture(ended_at: nil)

    u1 = user_fixture(skip_auth_for_active_calls: true)
    u2 = user_fixture(skip_auth_for_active_calls: true)
    users_calls_fixture(u1, call)
    users_calls_fixture(u2, call)

    assert Calls.user_can_access_call?(nil, call) == true
  end

  test "finished calls associated to users always require authentication" do
    call = call_fixture(ended_at: ~N[2022-09-04 12:48:50])
    u1 = user_fixture(skip_auth_for_active_calls: true)
    u2 = user_fixture(skip_auth_for_active_calls: true)
    users_calls_fixture(u1, call)
    users_calls_fixture(u2, call)

    assert Calls.user_can_access_call?(nil, call) == false
  end

  test "calls require authentication when any associated user has skip_auth_for_active_calls disabled" do
    call = call_fixture()
    u1 = user_fixture(skip_auth_for_active_calls: false)
    u2 = user_fixture(skip_auth_for_active_calls: true)
    users_calls_fixture(u1, call)
    users_calls_fixture(u2, call)

    assert Calls.user_can_access_call?(nil, call) == false
  end

  defp call_sids_for_user(user) do
    Repo.all(
      from uc in UsersCalls,
        join: c in assoc(uc, :call),
        where: uc.user_id == ^user.id,
        order_by: uc.id,
        select: c.sid
    )
  end
end
