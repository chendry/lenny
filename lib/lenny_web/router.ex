defmodule LennyWeb.Router do
  use LennyWeb, :router

  import LennyWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LennyWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LennyWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/", PageController, :index
  end

  scope "/", LennyWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/calls", CallsLive
  end

  scope "/", LennyWeb do
    pipe_through [:browser]

    live "/calls/:sid", CallLive
  end

  # Other scopes may use custom stacks.
  scope "/", LennyWeb do
    pipe_through :api

    post "/twilio/incoming", TwilioController, :incoming
    post "/twilio/status/call", TwilioController, :call_status
    post "/twilio/status/recording", TwilioController, :recording_status
    post "/twilio/gather/:i", TwilioController, :gather
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LennyWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", LennyWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", LennyWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/email", UserSettingsController, :edit_email
    put "/users/email", UserSettingsController, :update_email
    get "/users/email/confirm/:token", UserSettingsController, :confirm_email

    get "/users/password", UserSettingsController, :edit_password
    put "/users/password", UserSettingsController, :update_password

    get "/users/settings", UserSettingsController, :edit_settings
    put "/users/settings", UserSettingsController, :update_settings

    get "/users/phone", UserSettingsController, :edit_phone
  end

  scope "/", LennyWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end
