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

  def hello(iteration, autopilot) do
      """
      <Play>
        #{AudioFileUrls.hello()}
      </Play>
      #{gather_or_pause(autopilot, iteration)}
      """
  end

  def hello_are_you_there(iteration, autopilot) do
      """
      <Play>
        #{AudioFileUrls.hello_are_you_there()}
      </Play>
      #{gather_or_pause(autopilot, iteration)}
      """
  end

  defp gather_or_pause(autopilot, iteration) do
    if autopilot do
      gather(120, iteration)
    else
      ~s(<Pause length="120" />)
    end
  end
end
