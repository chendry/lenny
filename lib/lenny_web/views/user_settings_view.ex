defmodule LennyWeb.UserSettingsView do
  use LennyWeb, :view

  alias LennyWeb.Endpoint

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
    ~H"""
    <div id="tabs" class="flex flex-row justify-between sm:justify-start sm:space-x-4 mb-6 font-bold text-blue-600 space-x-2">
      <.tab active={selected_tab(@conn) == :settings} label="Settings" to={Routes.user_settings_path(Endpoint, :edit_settings)} />
      <.tab active={selected_tab(@conn) == :email} label="Email" to={Routes.user_settings_path(Endpoint, :edit_email)} />
      <.tab active={selected_tab(@conn) == :password} label="Password" to={Routes.user_settings_path(Endpoint, :edit_password)} />
      <.tab active={selected_tab(@conn) == :phone} label="Phone" to={Routes.user_settings_path(Endpoint, :edit_phone)} />
    </div>
    """
  end

  def selected_tab(conn) do
    case view_template(conn) do
      "edit_settings.html" -> :settings
      "edit_email.html" -> :email
      "edit_password.html" -> :password
      "edit_phone.html" -> :phone
    end
  end

  defp tab(assigns) do
    base_class = ~w{pb-0.5 rounded-t-md font-bold}

    class =
      if assigns.active do
        ~w{border-b-2 border-blue-600}
      else
        ~w{}
      end

    ~H"""
    <%= link(to: @to, class: base_class ++ class) do %>
      <%= @label %>
    <% end %>
    """
  end
end
