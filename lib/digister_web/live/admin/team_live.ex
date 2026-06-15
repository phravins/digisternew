defmodule DigisterWeb.Admin.TeamLive do
  use DigisterWeb, :live_view

  alias Digister.Accounts

  on_mount {DigisterWeb.Admin.AdminAuth, :require_admin}

  def mount(_params, _session, socket) do
    org = socket.assigns.current_organisation
    members = Accounts.list_users_by_organisation(org.id)

    {:ok,
     socket
     |> assign(:page_title, "Team")
     |> assign(:active_nav, :team)
     |> assign(:members, members)}
  end

  def render(assigns) do
    ~H"""
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-900">Team</h1>
      <p class="text-sm text-gray-500 mt-0.5">People with access to {@current_organisation.name}</p>
    </div>

    <div class="bg-white rounded-xl border border-gray-200 overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-gray-100">
            <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">User</th>
            <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Email</th>
            <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Role</th>
            <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Status</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <%= if @members == [] do %>
            <tr>
              <td colspan="4" class="px-5 py-16 text-center">
                <p class="text-sm font-medium text-gray-700">No members yet</p>
              </td>
            </tr>
          <% else %>
            <tr :for={m <- @members} class="hover:bg-gray-50/60 transition-colors">
              <td class="px-5 py-4 font-medium text-gray-900">{m.username || "—"}</td>
              <td class="px-5 py-4 text-gray-600">{m.email}</td>
              <td class="px-5 py-4">
                <span class="text-gray-700">{if m.role == "admin", do: "Admin", else: "User"}</span>
              </td>
              <td class="px-5 py-4">
                <span class={[
                  "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium",
                  if(m.is_active, do: "bg-green-50 border-green-200 text-green-700", else: "bg-gray-50 border-gray-200 text-gray-500")
                ]}>
                  {if m.is_active, do: "Active", else: "Inactive"}
                </span>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end
