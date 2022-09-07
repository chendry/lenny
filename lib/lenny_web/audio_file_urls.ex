defmodule LennyWeb.AudioFileUrls do
  alias LennyWeb.Router.Helpers, as: Routes

  alias LennyWeb.Endpoint

  def lenny(iteration) do
    case rem(iteration, 19) do
      00 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_00.mp3")
      01 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_01.mp3")
      02 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_02.mp3")
      03 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_03.mp3")
      04 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_04.mp3")
      05 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_05.mp3")
      06 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_06.mp3")
      07 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_07.mp3")
      08 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_08.mp3")
      09 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_09.mp3")
      10 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_10.mp3")
      11 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_11.mp3")
      12 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_12.mp3")
      13 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_13.mp3")
      14 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_14.mp3")
      15 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_15.mp3")
      16 -> Routes.static_url(Endpoint, "/audio/lenny/lenny_16.mp3")
    end
  end

  def hello, do: Routes.static_url(Endpoint, "/audio/lenny/hello.mp3")
  def hello_are_you_there, do: Routes.static_url(Endpoint, "/audio/lenny/hello_are_you_there.mp3")
end
