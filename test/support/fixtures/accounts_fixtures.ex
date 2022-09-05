defmodule Lenny.AccountsFixtures do
  import Ecto.Query
  import Ecto.Changeset

  alias Lenny.Accounts.User
  alias Lenny.Repo

  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lenny.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      record_calls: false
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Lenny.Accounts.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Lenny.Accounts.register_user()

    user
    |> change(confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> Repo.update!()
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
