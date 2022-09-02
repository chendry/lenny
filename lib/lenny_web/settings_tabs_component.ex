defmodule LennyWeb.SettingsTabsComponent do
  use LennyWeb, :component

  alias LennyWeb.Endpoint

  def settings_tabs(assigns) do
    ~H"""
    <div id="tabs" class="flex flex-row justify-between sm:justify-start sm:space-x-4 mb-4 font-bold text-blue-600 space-x-2">
      <.tab active={@selected == :settings} label="Settings" to={Routes.user_settings_path(Endpoint, :edit_settings)} />
      <.tab active={@selected == :email} label="Email" to={Routes.user_settings_path(Endpoint, :edit_email)} />
      <.tab active={@selected == :password} label="Password" to={Routes.user_settings_path(Endpoint, :edit_password)} />
      <.tab active={@selected == :phone} label="Phone" to={Routes.user_settings_path(Endpoint, :edit_phone)} />
    </div>
    """
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
