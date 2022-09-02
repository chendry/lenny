defmodule LennyWeb.CallLive.Buttons do
  alias Lenny.Calls.Call

  def audio_class() do
    shared() ++ ~w{border-blue-600 from-blue-400 to-blue-600 text-white}
  end

  def say_attrs(%Call{} = call, i) do
    %{
      "id" => "say_" <> String.pad_leading("#{i}", 2, "0"),
      "class" => say_class(i == call.iteration),
      "phx-click" => "say",
      "value" => i
    }
  end

  defp say_class(active) do
    extra =
      if active do
        ~w{border-green-700 text-green-700 active-say-button}
      else
        ~w{border-gray-600 text-slate-700}
      end

    shared() ++ ~w{from-slate-200 to-slate-300} ++ extra
  end

  def dtmf_class,
    do: shared() ++ ~w{w-10 m-1 border-gray-600 from-slate-200 to-slate-300}

  def hangup_class do
    shared() ++ ~w{border-red-500 from-red-400 to-red-600 text-white font-extrabold}
  end

  def wait_for_another_call_class do
    shared() ++ ~w{border-gray-600 from-slate-100 to-slate-200 text-gray-700}
  end

  def confirm_delete_yes_class do
    shared() ++ ~w{w-20 border-red-500 from-red-400 to-red-600 text-white font-extrabold}
  end

  def confirm_delete_no_class do
    shared() ++ ~w{w-20 border-blue-500 from-blue-400 to-blue-600 text-white font-extrabold}
  end

  defp shared() do
    ~w{rounded-lg border-2 px-2 py-1 font-bold bg-gradient-to-b}
  end
end
