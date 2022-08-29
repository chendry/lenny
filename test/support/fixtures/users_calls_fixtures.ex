defmodule Lenny.UsersCallsFixtures do
  alias Lenny.Repo
  alias Lenny.Accounts.User
  alias Lenny.Calls.Call
  alias Lenny.Calls.UsersCalls

  def users_calls_fixture(%User{} = user, %Call{} = call, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        recorded: false,
        seen_at: nil,
      })

    %UsersCalls{user_id: user.id, call_id: call.id}
    |> Ecto.Changeset.change(attrs)
    |> Repo.insert!()
  end
end
