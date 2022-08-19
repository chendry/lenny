defmodule LennyWeb.LennyLive do
  use LennyWeb, :live_view

  alias Lenny.Accounts
  alias Lenny.PhoneNumbers
  alias Lenny.PhoneNumbers.PhoneNumber
  alias Lenny.PhoneNumbers.VerificationForm

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:phone_number_changeset, PhoneNumber.changeset())
     |> assign(:verification_changeset, VerificationForm.changeset())
     |> assign(:pending_phone_number, PhoneNumbers.get_pending_phone_number(user))
     |> assign(:approved_phone_number, PhoneNumbers.get_approved_phone_number(user))}
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
         |> assign(:approved_phone_number, phone_number)}

      {:error, changeset} ->
        {:noreply, assign(socket, :verification_changeset, changeset)}

      {:stop, message} ->
        PhoneNumbers.soft_delete_phone_number(socket.assigns.pending_phone_number)

        {:noreply,
         socket
         |> assign(:pending_phone_number, nil)
         |> put_flash(:error, message)}
    end
  end

  @impl true
  def handle_event("delete_pending_phone_number", _params, socket) do
    PhoneNumbers.soft_delete_phone_number(socket.assigns.pending_phone_number)
    {:noreply, assign(socket, :pending_phone_number, nil)}
  end
end
