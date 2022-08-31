defmodule Lenny.Twilio do
  @callback verify_start(phone :: String.t(), channel :: String.t()) ::
              {:ok, %{sid: String.t(), carrier: map()}} | {:error, String.t()}

  @callback verify_check(sid :: String.t(), code :: String.t()) ::
              :ok | {:error, String.t()} | {:stop, String.t()}

  @callback verify_cancel(sid :: String.t()) ::
              :ok | :not_found

  @callback modify_call(sid :: String.t(), twiml :: String.t()) :: :ok

  @callback start_recording(sid :: String.t()) :: :ok

  @callback send_sms(to :: String.t(), body :: String.t()) :: :ok

  def verify_start(phone, channel), do: impl().verify_start(phone, channel)
  def verify_check(sid, code), do: impl().verify_check(sid, code)
  def verify_cancel(sid), do: impl().verify_cancel(sid)
  def modify_call(sid, twiml), do: impl().modify_call(sid, twiml)
  def start_recording(sid), do: impl().start_recording(sid)
  def send_sms(to, body), do: impl().send_sms(to, body)

  defp impl, do: Application.get_env(:lenny, :twilio, Lenny.TwilioImpl)
end
