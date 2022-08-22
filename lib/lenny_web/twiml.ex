defmodule LennyWeb.TwiML do
  alias LennyWeb.Router.Helpers, as: Routes
  alias LennyWeb.Endpoint
  alias LennyWeb.AudioFileUrls

  def autopilot_iteration(i) do
    next_action_path = Routes.autopilot_path(Endpoint, :iteration, i + 1)

    """
    <Play>
      #{AudioFileUrls.lenny(i)}
    </Play>

    <Gather
      input="speech"
      speechModel="phone_call"
      enhanced="true"
      timeout="7"
      speechTimeout="auto"
      action="#{next_action_path}"
    />

    <Play>
      #{AudioFileUrls.hello}
    </Play>

    <Gather
      input="speech"
      speechModel="phone_call"
      enhanced="true"
      timeout="5"
      speechTimeout="auto"
      action="#{next_action_path}"
    />

    <Play>
      #{AudioFileUrls.hello_are_you_there}
    </Play>

    <Gather
      input="speech"
      speechModel="phone_call"
      enhanced="true"
      timeout="5"
      speechTimeout="auto"
      action="#{next_action_path}"
    />
    """
  end
end
