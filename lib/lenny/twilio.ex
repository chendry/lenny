defmodule Lenny.Twilio do
  def start_new_verification(phone, channel) when channel in ["call", "sms"] do
    url = "https://verify.twilio.com/v2/Services/#{verification_service_sid()}/Verifications"

    query = [
      ServiceSid: verification_service_sid(),
      To: phone,
      Channel: channel
    ]

    {:ok, %{status_code: status_code, body: body}} =
      HTTPoison.post(url, URI.encode_query(query), headers())

    case {status_code, Jason.decode!(body)} do
      {201, %{"status" => "pending", "sid" => sid}} -> {:ok, sid}
      {400, %{"code" => 60200}} -> {:error, "invalid phone number"}
      {429, %{"code" => 60203}} -> {:error, "max send attempts reached"}
      {403, %{"code" => 60205}} -> {:error, "phone number does not support SMS"}
      {status_code, %{"code" => code}} -> {:error, "unknown error: #{status_code}-#{code}"}
      {status_code, _} -> {:error, "unknown error: #{status_code}"}
    end
  end

  def check_verification(sid, code) do
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

  def cancel_verification(sid) do
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

  defp headers do
    credentials = Base.encode64("#{account_sid()}:#{auth_token()}")

    [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Basic #{credentials}"}
    ]
  end

  defp account_sid, do: Application.get_env(:lenny, __MODULE__)[:account_sid]
  defp auth_token, do: Application.get_env(:lenny, __MODULE__)[:auth_token]

  defp verification_service_sid,
    do: Application.get_env(:lenny, __MODULE__)[:verification_service_sid]
end
