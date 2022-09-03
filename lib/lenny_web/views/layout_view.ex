defmodule LennyWeb.LayoutView do
  use LennyWeb, :view

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def flash(assigns) do
    ~H"""
    <%= if @msg do %>
      <div class={@class} {click_handler_attrs(@live)}>
        <span class="float-right ml-2 mb-1">
          <.x_mark_svg />
        </span>
        <%= @msg %>
      </div>
    <% end %>
    """
  end

  defp click_handler_attrs(live) do
    if live,
      do: %{"phx-click" => "lv:clear-flash"},
      else: %{"onclick" => "javascript:this.remove()"}
  end

  defp x_mark_svg(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
    </svg>
    """
  end
end
