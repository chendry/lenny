defmodule Lenny.TwilioImpl do
  @behaviour Lenny.Twilio

  require Logger

  alias LennyWeb.Router.Helpers, as: Routes

  @impl true
  def verify_start(phone, channel) when channel in ["call", "sms"] do
    url = "https://verify.twilio.com/v2/Services/#{verification_service_sid()}/Verifications"

    query = [
      ServiceSid: verification_service_sid(),
      To: phone,
      Channel: channel
    ]

    {:ok, %{status_code: status_code, body: body}} =
      HTTPoison.post(url, URI.encode_query(query), headers())

    case {status_code, Jason.decode!(body)} do
      {201, %{"status" => "pending", "sid" => sid, "lookup" => %{"carrier" => carrier}}} ->
        {:ok, %{sid: sid, carrier: carrier}}

      {400, %{"code" => 60200}} ->
        {:error, "invalid phone number"}

      {429, %{"code" => 60203}} ->
        {:error, "max send attempts reached"}

      {403, %{"code" => 60205}} ->
        {:error, "phone number does not support SMS"}

      {status_code, %{"code" => code}} ->
        {:error, "unknown error: #{status_code}-#{code}"}

      {status_code, _} ->
        {:error, "unknown error: #{status_code}"}
    end
  end

  @impl true
  def verify_check(sid, code) do
    url = "https://verify.twilio.com/v2/Services/#{verification_service_sid()}/VerificationCheck"

    query = [
      ServiceSid: verification_service_sid(),
      VerificationSid: sid,
      Code: code
    ]

    {:ok, %{status_code: status_code, body: body}} =
      HTTPoison.post(url, URI.encode_query(query), headers())

    case {status_code, Jason.decode!(body)} do
      {200, %{"status" => "approved"}} -> :ok
      {200, %{"status" => "pending"}} -> {:error, "incorrect code"}
      {200, %{"status" => "canceled"}} -> {:stop, "verification canceled"}
      {400, %{"code" => 60200}} -> {:error, "code is invalid"}
      {429, %{"code" => 60202}} -> {:stop, "max attempts reached"}
      {404, _} -> {:stop, "code has expired"}
      {status_code, %{"code" => code}} -> {:error, "unknown error: #{status_code}-#{code}"}
      {status_code, _} -> {:error, "unknown error: #{status_code}"}
    end
  end

  @impl true
  def verify_cancel(sid) do
    url =
      "https://verify.twilio.com/v2/Services/#{verification_service_sid()}/Verifications/#{sid}"

    query = [
      ServiceSid: verification_service_sid(),
      Sid: sid,
      Status: "canceled"
    ]

    {:ok, %{status_code: status_code, body: body}} =
      HTTPoison.post(url, URI.encode_query(query), headers())

    case {status_code, Jason.decode!(body)} do
      {404, %{"code" => 20404}} -> :not_found
      {200, %{"status" => "canceled"}} -> :ok
    end
  end

  @impl true
  def modify_call(sid, twiml) do
    url = "https://api.twilio.com/2010-04-01/Accounts/#{account_sid()}/Calls/#{sid}.json"

    query = [
      Twiml: twiml
    ]

    {:ok, %{status_code: 200}} =
      HTTPoison.post(
        url,
        URI.encode_query(query),
        headers()
      )

    :ok
  end

  @impl true
  def start_recording(sid) do
    spawn(fn ->
      [0, 100, 250, 750, 2000, 3000]
      |> Enum.reduce_while(nil, fn delay, _acc ->
        :timer.sleep(delay)

        case try_start_recording(sid) do
          :ok -> {:halt, :ok}
          error -> {:cont, error}
        end
      end)
      |> case do
        :ok ->
          Logger.info("#{__MODULE__}: recording #{sid}")

        {:error, error} ->
          Logger.error("#{__MODULE__}: error recording #{sid}: #{inspect(error)}")
      end
    end)

    :ok
  end

  defp try_start_recording(sid) do
    url =
      "https://api.twilio.com/2010-04-01/Accounts/#{account_sid()}/Calls/#{sid}/Recordings.json"

    query = [
      RecordingStatusCallback: Routes.twilio_url(LennyWeb.Endpoint, :recording_status),
      RecordingStatusCallbackEvent: "in-progress completed absent"
    ]

    HTTPoison.post(
      url,
      URI.encode_query(query),
      headers()
    )
    |> case do
      {:ok, %{status_code: 200}} -> :ok
      {:ok, %{status_code: 201}} -> :ok
      error -> {:error, error}
    end
  end

  @impl true
  def send_sms(to, body) do
    url = "https://api.twilio.com/2010-04-01/Accounts/#{account_sid()}/Messages.json"

    query = [
      From: "+19384653669",
      To: to,
      Body: body
    ]

    {:ok, %{status_code: 201}} =
      HTTPoison.post(
        url,
        URI.encode_query(query),
        headers()
      )

    :ok
  end

  def lookup(phone) do
    query =
      [
        Type: "carrier"
      ]
      |> URI.encode_query()

    url = "https://lookups.twilio.com/v1/PhoneNumbers/#{phone}?#{query}"

    {:ok, %{status_code: 200, body: body}} =
      HTTPoison.get(
        url,
        headers()
      )

    Jason.decode!(body)
  end

  def list_calls do
    url = "https://api.twilio.com/2010-04-01/Accounts/#{account_sid()}/Calls.json"

    {:ok, %{status_code: 200, body: body}} =
      HTTPoison.get(
        url,
        headers()
      )

    Jason.decode!(body)
  end

  def delete_call(sid) do
    url = "https://api.twilio.com/2010-04-01/Accounts/#{account_sid()}/Calls/#{sid}.json"

    {:ok, %{status_code: 204}} =
      HTTPoison.delete(
        url,
        headers()
      )
  end

  def delete_all_calls! do
    case list_calls() do
      %{"calls" => []} ->
        nil

      %{"calls" => calls} ->
        Enum.each(calls, fn %{"sid" => sid, "date_created" => date_created} ->
          IO.puts(date_created)
          delete_call(sid)
        end)

        delete_all_calls!()
    end
  end

  def list_recordings do
    url = "https://api.twilio.com/2010-04-01/Accounts/#{account_sid()}/Recordings.json"

    {:ok, %{status_code: 200, body: body}} =
      HTTPoison.get(
        url,
        headers()
      )

    Jason.decode!(body)
  end

  def delete_recording(sid) do
    url = "https://api.twilio.com/2010-04-01/Accounts/#{account_sid()}/Recordings/#{sid}.json"

    {:ok, %{status_code: 204}} =
      HTTPoison.delete(
        url,
        headers()
      )
  end

  def delete_all_recordings! do
    case list_recordings() do
      %{"recordings" => []} ->
        nil

      %{"recordings" => recordings} ->
        Enum.each(recordings, fn %{"sid" => sid, "date_created" => date_created} ->
          IO.puts(date_created)
          delete_recording(sid)
        end)

        delete_all_recordings!()
    end
  end

  defp headers do
    credentials = Base.encode64("#{account_sid()}:#{auth_token()}")

    [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Basic #{credentials}"}
    ]
  end

  def account_sid, do: Application.get_env(:lenny, Lenny.Twilio)[:account_sid]
  def auth_token, do: Application.get_env(:lenny, Lenny.Twilio)[:auth_token]

  defp verification_service_sid,
    do: Application.get_env(:lenny, Lenny.Twilio)[:verification_service_sid]
end
