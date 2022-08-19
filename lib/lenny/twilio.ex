defmodule Lenny.Twilio do
  @callback verify_start(phone :: String.t(), channel :: String.t()) ::
              {:ok, String.t()} | {:error, String.t()}

  @callback verify_check(verification_sid :: String.t(), code :: String.t()) ::
              :ok | {:error, String.t()} | {:stop, String.t()}

  @callback verify_cancel(verification_sid :: String.t()) ::
              :ok | :not_found

  @default_impl Application.get_env(:lenny, :twilio, Lenny.TwilioImpl)

  defdelegate verify_start(phone, channel), to: @default_impl
  defdelegate verify_check(verification_sid, code), to: @default_impl
  defdelegate verify_cancel(verification_sid), to: @default_impl
end
