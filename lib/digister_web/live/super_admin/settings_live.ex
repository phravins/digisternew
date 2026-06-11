defmodule DigisterWeb.SuperAdmin.SettingsLive do
  use DigisterWeb, :live_view

  on_mount {DigisterWeb.SuperAdminAuth, :require_super_admin}

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    sessions = Digister.Accounts.list_user_sessions(user.id)

    {:ok,
     socket
     |> assign(:page_title, "Account Settings")
     |> assign(:active_nav, :settings)
     |> assign(:user, user)
     |> assign(:sessions, sessions)
     |> assign(:show_new_pw, false)
     |> assign(:show_confirm_pw, false)}
  end

  def handle_event("toggle_new_pw", _params, socket) do
    {:noreply, assign(socket, :show_new_pw, !socket.assigns.show_new_pw)}
  end

  def handle_event("toggle_confirm_pw", _params, socket) do
    {:noreply, assign(socket, :show_confirm_pw, !socket.assigns.show_confirm_pw)}
  end

  def handle_event("update_password", %{"new_password" => pw, "confirm_password" => confirm}, socket) do
    cond do
      String.length(pw) < 12 ->
        {:noreply, put_flash(socket, :error, "Password must be at least 12 characters.")}
      pw != confirm ->
        {:noreply, put_flash(socket, :error, "Passwords do not match.")}
      true ->
        {:noreply, put_flash(socket, :info, "Password updated successfully.")}
    end
  end

  def handle_event("revoke_session", %{"id" => id}, socket) do
    Digister.Accounts.revoke_user_session(String.to_integer(id))
    sessions = Digister.Accounts.list_user_sessions(socket.assigns.user.id)
    {:noreply, assign(socket, :sessions, sessions)}
  end

  defp fmt_dt(%DateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y · %I:%M %p")
  defp fmt_dt(_), do: "—"

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto">

      <%!-- Change Password --%>
      <div class="mb-10">
        <h2 class="text-xl font-bold text-gray-900 mb-1">Change Password</h2>
        <p class="text-sm text-gray-400 mb-6">Update your password to keep your account secure</p>

        <form phx-submit="update_password">
          <div class="flex gap-5 items-end">
            <div class="flex-1">
              <label class="block text-sm text-gray-600 mb-1.5">New Password</label>
              <div class="relative">
                <input type={if @show_new_pw, do: "text", else: "password"} name="new_password"
                  class="w-full border border-gray-200 rounded-lg px-3 py-2.5 pr-10 text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent" />
                <button type="button" phx-click="toggle_new_pw"
                  class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                  <svg :if={!@show_new_pw} class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                  <svg :if={@show_new_pw} class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                  </svg>
                </button>
              </div>
            </div>
            <div class="flex-1">
              <label class="block text-sm text-gray-600 mb-1.5">Confirm Password</label>
              <div class="relative">
                <input type={if @show_confirm_pw, do: "text", else: "password"} name="confirm_password"
                  class="w-full border border-gray-200 rounded-lg px-3 py-2.5 pr-10 text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent" />
                <button type="button" phx-click="toggle_confirm_pw"
                  class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                  <svg :if={!@show_confirm_pw} class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                  <svg :if={@show_confirm_pw} class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                  </svg>
                </button>
              </div>
            </div>
            <div class="flex-shrink-0">
              <button type="submit"
                class="px-5 py-2.5 rounded-lg bg-gray-900 hover:bg-gray-700 text-sm font-medium text-white transition-colors whitespace-nowrap">
                Update Password
              </button>
            </div>
          </div>
        </form>
      </div>

      <div class="border-t border-gray-100 mb-10"></div>

      <%!-- Two-Factor Authentication --%>
      <div class="mb-10">
        <h2 class="text-xl font-bold text-gray-900 mb-1">Two-Factor Authentication</h2>
        <p class="text-sm text-gray-400 mb-6">Add an extra layer of security to your account</p>
        <div class="flex items-center justify-between">
          <p class="text-sm text-gray-600">
            Status: <span class="font-medium text-gray-800">{if @user.two_fa_enabled, do: "Enabled", else: "Not enabled"}</span>
          </p>
          <div class="flex items-center gap-3">
            <span class="rounded-lg border border-gray-200 px-3 py-1.5 text-xs font-medium text-gray-500">
              Recommended
            </span>
            <button type="button"
              class="px-5 py-2.5 rounded-lg bg-gray-900 hover:bg-gray-700 text-sm font-medium text-white transition-colors">
              {if @user.two_fa_enabled, do: "Disable", else: "Enable"}
            </button>
          </div>
        </div>
      </div>

      <div class="border-t border-gray-100 mb-10"></div>

      <%!-- Active Sessions --%>
      <div class="mb-10">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-xl font-bold text-gray-900">Active Sessions</h2>
          <span class="rounded-full border border-gray-200 px-3 py-1 text-xs font-medium text-gray-500">
            {length(@sessions)} Active
          </span>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-gray-100">
                <th class="text-left pb-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Device / Browser</th>
                <th class="text-left pb-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Location / IP</th>
                <th class="text-left pb-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Last Activity</th>
                <th class="text-left pb-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Action</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
              <%= if @sessions == [] do %>
                <tr>
                  <td colspan="4" class="py-10 text-center text-sm text-gray-400">No active sessions.</td>
                </tr>
              <% else %>
                <tr :for={session <- @sessions} class="hover:bg-gray-50 transition-colors">
                  <td class="py-4 pr-4">
                    <div class="flex items-center gap-3">
                      <div class="w-8 h-8 rounded-lg border border-gray-200 flex items-center justify-center flex-shrink-0">
                        <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                        </svg>
                      </div>
                      <div>
                        <p class="text-sm font-medium text-gray-800">Web Session</p>
                        <p class="text-xs text-gray-400">Browser</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 pr-4 text-sm text-gray-500">—</td>
                  <td class="py-4 pr-4 text-sm text-gray-700">{fmt_dt(session.authenticated_at || session.inserted_at)}</td>
                  <td class="py-4">
                    <button type="button"
                      phx-click="revoke_session"
                      phx-value-id={session.id}
                      class="flex items-center gap-1.5 text-sm text-gray-400 hover:text-red-500 transition-colors">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                      </svg>
                      Revoke
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>

    </div>
    """
  end
end
