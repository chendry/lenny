defmodule LennyWeb.LennyLive do
  use LennyWeb, :live_view

  alias Lenny.Accounts
  alias Lenny.Twilio
  alias Lenny.PhoneNumbers
  alias Lenny.PhoneNumbers.PhoneNumber
  alias Lenny.PhoneNumbers.VerificationForm

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)
    {:ok, assign(socket, :user, user)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    user = socket.assigns.user

    {:noreply,
     socket
     |> assign(:pending_phone_number, PhoneNumbers.get_pending_phone_number(user))
     |> assign(:approved_phone_number, PhoneNumbers.get_approved_phone_number(user))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    cond do
      socket.assigns.approved_phone_number == nil ->
        push_patch(socket, to: "/lenny/new")

      socket.assigns.pending_phone_number ->
        push_patch(socket, to: "/lenny/verify")

      true ->
        socket
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:changeset, PhoneNumber.changeset())
  end

  defp apply_action(socket, :verify, _params) do
    socket
    |> assign(:changeset, VerificationForm.changeset())
  end

  @impl true
  def handle_event("register_phone_number", %{"phone_number" => phone_number_params}, socket) do
    PhoneNumbers.register_phone_number_and_start_verification(
      socket.assigns.user,
      phone_number_params
    )
    |> case do
      {:ok, _phone_number} ->
        {:noreply, push_patch(socket, to: "/lenny/verify")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
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
        {:noreply, push_patch(socket, to: "/lenny")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}

      {:stop, message} ->
        PhoneNumbers.soft_delete_phone_number(socket.assigns.pending_phone_number)

        {:noreply,
         socket
         |> put_flash(:error, message)
         |> push_patch(to: "/lenny")}
    end
  end

  @impl true
  def handle_event("cancel_verification", _params, socket) do
    phone_number = socket.assigns.pending_phone_number

    if phone_number do
      Twilio.verify_cancel(phone_number.verification_sid)
      PhoneNumbers.soft_delete_phone_number(phone_number)
    end
    
    {:noreply, push_patch(socket, to: "/lenny")}
  end
end
