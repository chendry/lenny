defmodule Lenny.Repo do
  use Ecto.Repo,
    otp_app: :lenny,
    adapter: Ecto.Adapters.Postgres
end
