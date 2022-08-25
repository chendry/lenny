defmodule LennyWeb.TwiML do
  alias LennyWeb.Router.Helpers, as: Routes
  alias LennyWeb.Endpoint
  alias LennyWeb.AudioFileUrls

  def autopilot_iteration(i) do
    next_action_url = Routes.autopilot_url(Endpoint, :iteration, i + 1)

    """
    <Play>
      #{AudioFileUrls.lenny(i)}
    </Play>

    #{gather(7, next_action_url)}

    <Play>
      #{AudioFileUrls.hello()}
    </Play>

    #{gather(5, next_action_url)}

    <Play>
      #{AudioFileUrls.hello_are_you_there()}
    </Play>

    #{gather(5, next_action_url)}
    """
  end

  def gather(timeout, action) do
    """
    <Gather
      input="speech"
      speechModel="phone_call"
      enhanced="true"
      timeout="#{timeout}"
      speechTimeout="auto"
      action="#{action}"
    />
    """
  end
end
