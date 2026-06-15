defmodule DigisterWeb.Admin.SettingsLive do
  use DigisterWeb, :live_view

  on_mount {DigisterWeb.Admin.AdminAuth, :require_admin}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Settings")
     |> assign(:active_nav, :settings)}
  end

  def render(assigns) do
    ~H"""
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-900">Settings</h1>
      <p class="text-sm text-gray-500 mt-0.5">Your account and company details</p>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <h2 class="text-base font-semibold text-gray-900 mb-4">Company</h2>
        <dl class="space-y-3 text-sm">
          <div>
            <dt class="text-xs text-gray-400">Name</dt>
            <dd class="text-gray-700">{@current_organisation.name}</dd>
          </div>
          <div>
            <dt class="text-xs text-gray-400">Slug</dt>
            <dd class="text-gray-700">{@current_organisation.slug}</dd>
          </div>
          <div>
            <dt class="text-xs text-gray-400">Industry</dt>
            <dd class="text-gray-700">{@current_organisation.industry || "—"}</dd>
          </div>
          <div>
            <dt class="text-xs text-gray-400">Your role</dt>
            <dd class="text-gray-700">{if @current_role == "admin", do: "Admin", else: "User"}</dd>
          </div>
        </dl>
      </div>

      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <h2 class="text-base font-semibold text-gray-900 mb-4">Account</h2>
        <dl class="space-y-3 text-sm">
          <div>
            <dt class="text-xs text-gray-400">Username</dt>
            <dd class="text-gray-700">{@current_scope.user.username || "—"}</dd>
          </div>
          <div>
            <dt class="text-xs text-gray-400">Email</dt>
            <dd class="text-gray-700">{@current_scope.user.email}</dd>
          </div>
        </dl>
        <form action={~p"/users/log-out"} method="post" class="mt-5">
          <input type="hidden" name="_method" value="delete" />
          <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
          <button type="submit" class="text-sm font-medium text-red-600 hover:underline">Sign out</button>
        </form>
      </div>
    </div>
    """
  end
end
