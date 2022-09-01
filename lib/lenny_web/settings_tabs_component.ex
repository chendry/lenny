defmodule LennyWeb.SettingsTabsComponent do
  use LennyWeb, :component

  alias LennyWeb.Endpoint

  def settings_tabs(assigns) do
    ~H"""
    <div id="tabs" class="flex flex-row mb-4 font-bold text-blue-600 border-b-2 border-blue-600 space-x-3">
      <.tab active={@selected == :settings} label="Settings" to={Routes.user_settings_path(Endpoint, :edit_settings)} />
      <.tab active={@selected == :email} label="Email" to={Routes.user_settings_path(Endpoint, :edit_email)} />
      <.tab active={@selected == :password} label="Password" to={Routes.user_settings_path(Endpoint, :edit_password)} />
      <.tab active={@selected == :phone} label="Phone Number" to={Routes.phone_number_path(Endpoint, :new)} />
    </div>
    """
  end

  defp tab(assigns) do
    base_class = ~w{px-2 py-1 border-2 border-b-0 border-blue-600 rounded-t-md font-bold}

    class =
      if assigns.active do
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
