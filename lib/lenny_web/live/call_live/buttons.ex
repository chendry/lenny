defmodule LennyWeb.CallLive.Buttons do
  def audio_class() do
    shared() ++ ~w{border-blue-600 from-blue-400 to-blue-600 text-white}
  end

  def say_attrs(iteration, i) do
    %{
      "id" => "say_" <> String.pad_leading("#{i}", 2, "0"),
      "class" => say_class(i == iteration),
      "phx-click" => "say",
      "value" => i
    }
  end

  defp say_class(active) do
    text_color =
      if active,
        do: "text-blue-600",
        else: "text-slate-700"

    shared() ++ [text_color] ++ ~w{border-gray-600 from-slate-200 to-slate-300}
  end

  def dtmf_class,
    do: shared() ++ ~w{w-10 m-1 border-gray-600 from-slate-200 to-slate-300}

  def hangup_class do
    shared() ++ ~w{border-red-500 from-red-400 to-red-600 text-white font-extrabold}
  end

  defp shared() do
    ~w{rounded-lg border-2 px-2 py-1 font-bold bg-gradient-to-b}
  end
end
