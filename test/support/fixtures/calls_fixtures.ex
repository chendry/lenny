defmodule Lenny.CallsFixtures do
  alias Lenny.Repo
  alias Lenny.Calls.Call

  def call_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        sid: random_sid(),
        from: random_phone_number(),
        to: random_phone_number(),
        autopilot: true,
        ended_at: nil,
        params: %{}
      })

    %Call{}
    |> Ecto.Changeset.change(attrs)
    |> Repo.insert!()
  end

  defp random_sid do
    random =
      1..34
      |> Enum.map(fn _ -> Enum.random('0123456789abcdef') end)
      |> List.to_string()

    "CA#{random}"
  end

  defp random_phone_number do
    digits =
      1..10
      |> Enum.map(fn _ -> Enum.random(0..9) end)
      |> Enum.join()

    "+1#{digits}"
  end
end
