defmodule LennyWeb.LennyLive do
  use LennyWeb, :live_view

  alias Lenny.Accounts
  alias Lenny.PhoneNumbers
  alias Lenny.PhoneNumbers.PhoneNumber
  alias Lenny.PhoneNumbers.VerificationForm

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)

    pending_phone_number = PhoneNumbers.get_pending_phone_number(user)
    approved_phone_number = PhoneNumbers.get_approved_phone_number(user)

    phone_number_changeset =
      if pending_phone_number == nil and approved_phone_number == nil do
        PhoneNumber.changeset()
      end

    verification_changeset =
      if pending_phone_number != nil do
        VerificationForm.changeset()
      end

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:pending_phone_number, pending_phone_number)
     |> assign(:approved_phone_number, approved_phone_number)
     |> assign(:phone_number_changeset, phone_number_changeset)
     |> assign(:verification_changeset, verification_changeset)}
  end

  @impl true
  def handle_event("register_phone_number", %{"phone_number" => phone_number_params}, socket) do
    PhoneNumbers.register_phone_number_and_start_verification(
      socket.assigns.user,
      phone_number_params
    )
    |> case do
      {:ok, phone_number} ->
        {:noreply,
         socket
         |> assign(:pending_phone_number, phone_number)
         |> assign(:phone_number_changeset, nil)
         |> assign(:verification_changeset, VerificationForm.changeset())}

      {:error, changeset} ->
        {:noreply, assign(socket, :phone_number_changeset, changeset)}
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
      {:ok, phone_number} ->
        {:noreply,
         socket
         |> assign(:pending_phone_number, nil)
         |> assign(:verification_changeset, nil)
         |> assign(:approved_phone_number, phone_number)}

      {:error, changeset} ->
        {:noreply, assign(socket, :verification_changeset, changeset)}

      {:stop, message} ->
        PhoneNumbers.soft_delete_phone_number(socket.assigns.pending_phone_number)

        {:noreply,
         socket
         |> assign(:pending_phone_number, nil)
         |> assign(:verification_changeset, nil)
         |> put_flash(:error, message)}
    end
  end

  @impl true
  def handle_event("cancel_registration", _params, socket) do
    {:noreply, assign(socket, :phone_number_changeset, nil)}
  end

  @impl true
  def handle_event("cancel_verification", _params, socket) do
    Lenny.Twilio.cancel_verification(socket.assigns.pending_phone_number.verification_sid)
    PhoneNumbers.soft_delete_phone_number(socket.assigns.pending_phone_number)

    {:noreply,
     socket
     |> assign(:pending_phone_number, nil)
     |> assign(:verification_changeset, nil)}
  end

  @impl true
  def handle_event("change_phone_number", _params, socket) do
    {:noreply, assign(socket, :phone_number_changeset, PhoneNumber.changeset())}
  end
end
