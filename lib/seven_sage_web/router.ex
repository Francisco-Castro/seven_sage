defmodule SevenSageWeb.Router do
  use SevenSageWeb, :router

  import SevenSageWeb.StudentAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SevenSageWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_student
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SevenSageWeb do
    pipe_through [:browser, :require_authenticated_student]

    live "/records", RecordsLive
  end

  scope "/", SevenSageWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", SevenSageWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:seven_sage, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SevenSageWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", SevenSageWeb do
    pipe_through [:browser, :redirect_if_student_is_authenticated]

    live_session :redirect_if_student_is_authenticated,
      on_mount: [{SevenSageWeb.StudentAuth, :redirect_if_student_is_authenticated}] do
      live "/students/register", StudentRegistrationLive, :new
      live "/students/log_in", StudentLoginLive, :new
      live "/students/reset_password", StudentForgotPasswordLive, :new
      live "/students/reset_password/:token", StudentResetPasswordLive, :edit
    end

    post "/students/log_in", StudentSessionController, :create
  end

  scope "/", SevenSageWeb do
    pipe_through [:browser, :require_authenticated_student]

    live_session :require_authenticated_student,
      on_mount: [{SevenSageWeb.StudentAuth, :ensure_authenticated}] do
      live "/students/settings", StudentSettingsLive, :edit
      live "/students/settings/confirm_email/:token", StudentSettingsLive, :confirm_email
    end
  end

  scope "/", SevenSageWeb do
    pipe_through [:browser]

    delete "/students/log_out", StudentSessionController, :delete

    live_session :current_student,
      on_mount: [{SevenSageWeb.StudentAuth, :mount_current_student}] do
      live "/students/confirm/:token", StudentConfirmationLive, :edit
      live "/students/confirm", StudentConfirmationInstructionsLive, :new
    end
  end
end
