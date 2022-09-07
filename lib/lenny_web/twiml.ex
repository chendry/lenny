defmodule LennyWeb.TwiML do
  alias LennyWeb.Router.Helpers, as: Routes
  alias LennyWeb.Endpoint
  alias LennyWeb.AudioFileUrls

  def lenny(iteration, autopilot) do
    """
    <Play>
      #{AudioFileUrls.lenny(iteration)}
    </Play>
    #{gather_or_pause(autopilot, iteration)}
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

  defp gather_or_pause(autopilot, iteration) do
    if autopilot do
      gather(120, iteration)
    else
      ~s(<Pause length="120" />)
    end
  end
end
