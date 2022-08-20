defmodule Lenny.Twilio do
  @callback verify_start(phone :: String.t(), channel :: String.t()) ::
              {:ok, String.t()} | {:error, String.t()}

  @callback verify_check(verification_sid :: String.t(), code :: String.t()) ::
              :ok | {:error, String.t()} | {:stop, String.t()}

  @callback verify_cancel(verification_sid :: String.t()) ::
              :ok | :not_found

  def verify_start(phone, channel), do: impl().verify_start(phone, channel)
  def verify_check(verification_sid, code), do: impl().verify_check(verification_sid, code)
  def verify_cancel(verification_sid), do: impl().verify_cancel(verification_sid)

  defp impl, do: Application.get_env(:lenny, :twilio, Lenny.TwilioImpl)
end
