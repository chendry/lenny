defmodule Lenny.RecordingsFixtures do
  alias Lenny.Repo
  alias Lenny.Recordings.Recording

  def recordings_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        sid: random_sid(),
        status: "in-progress",
        url: "https://example.com/recording",
        params: %{}
      })

    %Recording{}
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
end
