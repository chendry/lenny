defmodule LennyWeb.PhoneSettingLive do
  use LennyWeb, :live_view

  alias Lenny.Accounts
  alias Lenny.PhoneNumbers
  alias LennyWeb.PhoneNumberLive

  @impl true
  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    user = Accounts.get_user_by_session_token(user_token)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:verified_phone_number, PhoneNumbers.get_verified_phone_number(user))}
  end

  def breadcrumbs(assigns) do
    ~H"""
    <div id="breadcrumbs">
      <%= live_redirect "Calls", to: "/calls" %>
      <span class="breadcrumb-separator" />
      <span>Settings</span>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
      <LennyWeb.UserSettingsView.tabs conn={@socket} />

      <h2 class="text-xl font-lg font-bold mb-4">
        <%= if @verified_phone_number do %>
          Change Your Phone Number
        <% else %>
          Register Your Phone Number
        <% end %>
      </h2>

      <.live_component
        module={PhoneNumberLive}
        id="phone-number-live"
        user={@user}
      />
    """
  end
end
