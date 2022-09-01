defmodule LennyWeb.TwiML do
  alias LennyWeb.Router.Helpers, as: Routes
  alias LennyWeb.Endpoint
  alias LennyWeb.AudioFileUrls

  def lenny(i, autopilot) do
    if autopilot do
      """
      <Play>
        #{AudioFileUrls.lenny(i)}
      </Play>
      #{gather(120, i)}
      """
    else
      """
      <Play>
        #{AudioFileUrls.lenny(i)}
      </Play>
      <Pause length="120" />
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
