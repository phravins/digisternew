defmodule DigisterWeb.Router do
  use DigisterWeb, :router

  import DigisterWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DigisterWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :auth_layout do
    plug :put_root_layout, html: {DigisterWeb.Layouts, :auth}
  end

  pipeline :super_admin_layout do
    plug :put_root_layout, html: {DigisterWeb.Layouts, :super_admin}
    plug :put_layout, false
  end

  pipeline :admin_layout do
    plug :put_root_layout, html: {DigisterWeb.Layouts, :admin}
    plug :put_layout, false
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DigisterWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", DigisterWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:digister, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DigisterWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", DigisterWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", DigisterWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", DigisterWeb do
    pipe_through [:browser, :auth_layout]

    live "/users/log-in", UserLoginLive, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  ## Super admin routes
  scope "/digisters/superadmin", DigisterWeb.SuperAdmin do
    pipe_through [:browser, :super_admin_layout]

    live "/", DashboardLive, :index
    live "/companies", CompaniesLive, :index
    live "/users", UsersLive, :index
    live "/profile", ProfileLive, :index
    live "/settings", SettingsLive, :index
    live "/registers", RegistersLive, :index
    live "/registers/new", CreateRegisterLive, :new
    live "/registers/:register_id/edit", CreateRegisterLive, :edit
    live "/registers/:org_id", RegistersLive, :show
    live "/registers/:org_id/r/:register_id", RegistersLive, :entries
    live "/templates", TemplatesLive, :index
    live "/bin", BinLive, :index

    get "/companies/export", ExportController, :companies
    get "/users/export", ExportController, :users
    get "/registers/:register_id/export", ExportController, :register
  end

  ## Company-selection page (after login, for admin/member users)
  scope "/", DigisterWeb.Admin do
    pipe_through [:browser, :auth_layout]

    live "/select-company", SelectCompanyLive, :index
  end

  ## Company-scoped admin area (defined AFTER the super-admin scope so that
  ## /digisters/superadmin keeps matching the super-admin routes).
  scope "/digisters/:company_slug/admin", DigisterWeb.Admin do
    pipe_through [:browser, :admin_layout]

    live "/", DashboardLive, :index
    live "/registers", RegistersLive, :index
    live "/team", TeamLive, :index
    live "/settings", SettingsLive, :index
  end
end
