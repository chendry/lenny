defmodule LennyWeb.UserSettingsView do
  use LennyWeb, :view

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
    <div id="tabs" class="flex flex-row mb-4 font-bold text-blue-600 border-b-2 border-blue-600 space-x-3">
      <.tab conn={@conn} label="Settings" view_template="edit_settings.html" to={Routes.user_settings_path(@conn, :edit_settings)} />
      <.tab conn={@conn} label="Email" view_template="edit_email.html" to={Routes.user_settings_path(@conn, :edit_email)} />
      <.tab conn={@conn} label="Password" view_template="edit_password.html" to={Routes.user_settings_path(@conn, :edit_password)} />
    </div>
    """
  end

  def tab(assigns) do
    base_class = ~w{px-2 py-1 border-2 border-b-0 border-blue-600 rounded-t-md font-bold}

    class =
      if view_template(assigns.conn) == assigns.view_template do
        ~w{text-white bg-blue-600}
      else
        ~w{text-blue-600}
      end

    ~H"""
    <%= link(to: @to, class: base_class ++ class) do %>
      <%= @label %>
    <% end %>
    """
  end
end
