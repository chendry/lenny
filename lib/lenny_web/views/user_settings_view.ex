defmodule LennyWeb.UserSettingsView do
  use LennyWeb, :view

  import LennyWeb.SettingsTabsComponent

  def breadcrumbs(assigns) do
    ~H"""
    <div id="breadcrumbs">
      <%= live_redirect "Calls", to: "/calls" %>
      <span class="breadcrumb-separator" />
      <span>Settings</span>
    </div>
    """
  end

  def tabs(assigns) do
    selected =
      case view_template(assigns.conn) do
        "edit_settings.html" -> :settings
        "edit_email.html" -> :email
        "edit_password.html" -> :password
      end
    
    ~H"""
    <.settings_tabs conn={@conn} selected={selected} />
    """
  end
end
