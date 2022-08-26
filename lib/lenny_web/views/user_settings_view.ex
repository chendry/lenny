defmodule LennyWeb.UserSettingsView do
  use LennyWeb, :view

  def settings_section(assigns) do
    ~H"""
    <div class="mt-8 bg-gray-100 border border-gray-600 rounded-lg p-6 pt-4">
      <h3 class="text-lg font-bold mb-4"><%= @title %></h3>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
