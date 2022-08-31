defmodule LennyWeb.TwiML do
  alias LennyWeb.Router.Helpers, as: Routes
  alias LennyWeb.Endpoint
  alias LennyWeb.AudioFileUrls

  def lenny(i, autopilot) do
    """
    <Play>
      #{AudioFileUrls.lenny(i)}
    </Play>

    #{gather_after_audio(autopilot, i)}
    """
  end

  defp gather_after_audio(autopilot, i) do
    if not autopilot do
      """
      <Pause length="120" />
      """
    else
      """
      #{gather(7, i)}

      <Play>
        #{AudioFileUrls.hello()}
      </Play>

      #{gather(5, i)}

      <Play>
        #{AudioFileUrls.hello_are_you_there()}
      </Play>

      #{gather(120, i)}
      """
    end
  end

  def gather(timeout, i) do
    """
    <Gather
      input="speech"
      speechModel="phone_call"
      enhanced="true"
      timeout="#{timeout}"
      speechTimeout="auto"
      action="#{Routes.twilio_url(Endpoint, :gather, i)}"
    />
    """
  end
end
