defmodule LennyWeb.RegisterPhoneNumberLive do
  use LennyWeb, :live_component

  alias Lenny.Twilio
  alias Lenny.PhoneNumbers
  alias Lenny.PhoneNumbers.PhoneNumber
  alias Lenny.PhoneNumbers.VerificationForm

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:register_changeset, PhoneNumber.changeset())
     |> assign(:verify_changeset, VerificationForm.changeset())}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:pending_phone_number, PhoneNumbers.get_pending_phone_number(assigns.user))}
  end
  

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @pending_phone_number == nil do %>

        <.form for={@register_changeset} let={f} phx-target={@myself} phx-submit="register_phone_number">
          <div class="mt-4 flex flex-col space-y-2">
            <%= label f, :phone do %>
              Phone Number
            <% end %>
            <%= telephone_input f, :phone, placeholder: "5554443333" %>
            <%= error_tag f, :phone %>
          </div>

          <div class="mt-6">
            <%= submit "Submit", class: "btn btn-blue" %>
          </div>
        </.form>

      <% else %>

        <p class="mt-2">
          We sent a code to
          <span class="font-bold">
            <span id="pending-number"><%= @pending_phone_number.phone %></span>
          </span>.
          Please enter that code to verify your phone number:
        </p>

        <.form for={@verify_changeset} let={f} phx-target={@myself} phx-submit="verify_phone_number">
          <div class="mt-4 flex flex-col space-y-2">
            <%= label f, :code %>
            <%= text_input f, :code %>
            <%= error_tag f, :code %>
          </div>

          <div class="mt-6">
            <%= submit "Submit", class: "btn btn-blue" %>
            <a href="#" phx-click="cancel_verification" phx-target={@myself} class="ml-4 text-blue-600">
              Cancel
            </a>
          </div>
        </.form>

      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("register_phone_number", %{"phone_number" => phone_number_params}, socket) do
    PhoneNumbers.register_phone_number_and_start_verification(
      socket.assigns.user,
      phone_number_params
    )
    |> case do
      {:ok, phone_number} ->
        {:noreply, assign(socket, :pending_phone_number, phone_number)}

      {:error, changeset} ->
        {:noreply, assign(socket, :register_changeset, changeset)}
    end
  end

  @impl true
  def handle_event(
        "verify_phone_number",
        %{"verification_form" => verification_form_params},
        socket
      ) do
    PhoneNumbers.verify_phone_number(
      socket.assigns.pending_phone_number,
      verification_form_params
    )
    |> case do
      {:ok, _phone_number} ->
        {:noreply, push_redirect(socket, to: "/calls")}

      {:error, changeset} ->
        {:noreply, assign(socket, :verify_changeset, changeset)}

      {:stop, message} ->
        PhoneNumbers.soft_delete_phone_number(socket.assigns.pending_phone_number)

        {:noreply,
         socket
         |> put_flash(:error, message)
         |> assign(:pending_phone_number, nil)}
    end
  end

  @impl true
  def handle_event("cancel_verification", _params, socket) do
    phone_number = socket.assigns.pending_phone_number

    if phone_number do
      Twilio.verify_cancel(phone_number.sid)
      PhoneNumbers.soft_delete_phone_number(phone_number)
    end

    {:noreply, push_redirect(socket, to: "/calls")}
  end
end