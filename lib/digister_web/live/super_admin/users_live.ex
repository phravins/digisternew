defmodule DigisterWeb.SuperAdmin.UsersLive do
  use DigisterWeb, :live_view

  alias Digister.Accounts

  on_mount {DigisterWeb.SuperAdminAuth, :require_super_admin}

  def mount(_params, _session, socket) do
    users = Accounts.list_users_with_orgs()

    {:ok,
     socket
     |> assign(:page_title, "All Users")
     |> assign(:active_nav, :users)
     |> assign(:users, users)
     |> assign(:all_users, users)
     |> assign(:search, "")}
  end

  def handle_event("search", %{"q" => q}, socket) do
    q = String.downcase(String.trim(q))
    filtered =
      socket.assigns.all_users
      |> Enum.filter(fn u ->
        String.contains?(String.downcase(u.username || ""), q) or
        String.contains?(String.downcase(u.email || ""), q) or
        String.contains?(String.downcase(u.org_name || ""), q)
      end)
    {:noreply, socket |> assign(:search, q) |> assign(:users, filtered)}
  end

  defp role_label(%{is_super_admin: true}), do: "Super Admin"
  defp role_label(%{role: "admin"}), do: "Admin"
  defp role_label(_), do: "User"

  defp role_color(%{is_super_admin: true}), do: "text-indigo-600 font-semibold"
  defp role_color(%{role: "admin"}), do: "text-green-600 font-medium"
  defp role_color(_), do: "text-gray-500"

  defp initials(user) do
    name = user.username || user.email || "?"
    name
    |> String.split()
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp fmt_dt(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y · %I:%M %p")
  defp fmt_dt(_), do: "—"

  def render(assigns) do
    ~H"""
    <div>
      <%!-- Header --%>
      <div class="flex items-start justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">All Users</h1>
          <p class="text-sm text-gray-400 mt-0.5">Cross-platform user directory</p>
        </div>
        <div class="flex items-center gap-2 text-sm text-gray-500 bg-white border border-gray-200 rounded-lg px-3 py-1.5">
          <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          <span>{Calendar.strftime(Date.utc_today(), "%d %b %Y")}</span>
        </div>
      </div>

      <%!-- Toolbar --%>
      <div class="flex items-center gap-3 mb-5">
        <div class="relative flex-1">
          <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input type="text" placeholder="Search users by name, email, or org..."
            phx-keyup="search" name="q" value={@search}
            class="w-full border border-gray-200 rounded-lg pl-9 pr-4 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent bg-white" />
        </div>
        <button type="button"
          class="flex items-center gap-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-700 px-4 py-2.5 text-sm font-medium text-white transition-colors">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
          </svg>
          Create Account
        </button>
        <button type="button"
          class="flex items-center gap-1.5 border border-gray-200 rounded-lg px-4 py-2.5 text-sm font-medium text-gray-600 bg-white hover:bg-gray-50 transition-colors">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
          </svg>
          Export
        </button>
      </div>

      <%!-- Table --%>
      <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-gray-100">
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider w-12">S.No</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">User</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Company</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Role</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Status</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Last Active</th>
              <th class="text-right px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= if @users == [] do %>
              <tr>
                <td colspan="7" class="px-5 py-12 text-center text-sm text-gray-400">No users found.</td>
              </tr>
            <% else %>
              <tr :for={{user, idx} <- Enum.with_index(@users, 1)} class="hover:bg-gray-50 transition-colors">
                <td class="px-5 py-4 text-sm text-gray-400">{idx}</td>
                <td class="px-5 py-4">
                  <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-full bg-indigo-100 flex items-center justify-center flex-shrink-0">
                      <span class="text-xs font-semibold text-indigo-600">{initials(user)}</span>
                    </div>
                    <div>
                      <p class="font-medium text-gray-900 text-sm">{user.username || "—"}</p>
                      <p class="text-xs text-gray-400 mt-0.5">{user.email}</p>
                    </div>
                  </div>
                </td>
                <td class="px-5 py-4 text-sm text-gray-700">{user.org_name || "—"}</td>
                <td class="px-5 py-4">
                  <span class={["text-sm", role_color(user)]}>{role_label(user)}</span>
                </td>
                <td class="px-5 py-4">
                  <span class={[
                    "inline-flex items-center gap-1.5 text-xs font-medium",
                    if(user.is_active, do: "text-green-600", else: "text-gray-400")
                  ]}>
                    <span class={[
                      "w-1.5 h-1.5 rounded-full",
                      if(user.is_active, do: "bg-green-500", else: "bg-gray-300")
                    ]}></span>
                    {if user.is_active, do: "Active", else: "Inactive"}
                  </span>
                </td>
                <td class="px-5 py-4 text-sm text-gray-600">{fmt_dt(user.signed_on)}</td>
                <td class="px-5 py-4">
                  <div class="flex items-center justify-end gap-3">
                    <button :if={!user.is_super_admin} type="button" class="text-gray-400 hover:text-gray-600 transition-colors">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                      </svg>
                    </button>
                    <button type="button" class="text-gray-400 hover:text-indigo-600 transition-colors">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                      </svg>
                    </button>
                    <button :if={!user.is_super_admin} type="button" class="text-gray-400 hover:text-red-500 transition-colors">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                      </svg>
                    </button>
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
