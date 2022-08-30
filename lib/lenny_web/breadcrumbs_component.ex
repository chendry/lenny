defmodule LennyWeb.BreadcrumbsComponent do
  use LennyWeb, :component

  def breadcrumbs(assigns) do
    ~H"""
    <div id="breadcrumbs" class="bg-gray-100 border-b border-gray-400 font-bold py-2 px-4 flex flex-row space-x-2">
      <%= render_slot @inner_block %>
    </div>
    """
  end

  def breadcrumb_separator(assigns) do
    ~H"""
    <span class="text-gray-400">&gt;</span>
    """
  end

  def breadcrumb_link(assigns) do
    ~H"""
    <span class="text-blue-800">
      <%= render_slot @inner_block %>
    </span>
    """
  end
end
