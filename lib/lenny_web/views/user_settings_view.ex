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

  def settings_section(assigns) do
    ~H"""
    <h3 class="text-lg font-bold"><%= @title %></h3>
    <div class="mt-2 bg-gray-100 border border-gray-600 rounded-lg p-6 pt-4">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
