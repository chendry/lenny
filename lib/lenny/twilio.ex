defmodule Lenny.Twilio do
  def account_sid, do: Application.get_env(:lenny, __MODULE__)[:account_sid]
  def auth_token, do: Application.get_env(:lenny, __MODULE__)[:auth_token]
  def verification_service_sid, do: Application.get_env(:lenny, __MODULE__)[:verification_service_sid]
end
