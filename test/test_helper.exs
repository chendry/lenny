ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Lenny.Repo, :manual)

Mox.defmock(Lenny.TwilioMock, for: Lenny.Twilio)
Application.put_env(:lenny, :twilio, Lenny.TwilioMock)
