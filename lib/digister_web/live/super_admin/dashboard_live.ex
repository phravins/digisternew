defmodule DigisterWeb.SuperAdmin.DashboardLive do
  use DigisterWeb, :live_view

  alias Digister.Accounts
  alias Digister.Activities
  alias Digister.Organisations
  alias Digister.Registers

  on_mount {DigisterWeb.SuperAdminAuth, :require_super_admin}

  def mount(_params, _session, socket) do
    total_users = Accounts.count_users()
    total_orgs = Organisations.count_organisations()
    total_registers = Registers.count_registers()
    total_entries = Registers.count_entries()
    orgs = Organisations.list_organisations_with_register_counts()
    activity = Activities.list_recent(10)

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:active_nav, :dashboard)
     |> assign(:total_users, total_users)
     |> assign(:total_orgs, total_orgs)
     |> assign(:total_registers, total_registers)
     |> assign(:total_entries, total_entries)
     |> assign(:orgs, orgs)
     |> assign(:activity, activity)}
  end

  def handle_event("clear_activity", _params, socket) do
    Activities.clear_all()
    {:noreply, assign(socket, :activity, [])}
  end

  defp fmt_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y")
  defp fmt_time(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%I:%M %p")
  defp fmt_dt(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y - %I:%M %p")

  def render(assigns) do
    ~H"""
    <%!-- Page heading --%>
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-900">Platform overview</h1>
      <p class="text-sm text-gray-500 mt-0.5">How Digisters is doing today</p>
    </div>

    <%!-- Stat cards --%>
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">

      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <div class="flex items-start justify-between mb-3">
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider">Companies</p>
          <div class="w-8 h-8 rounded-lg border border-gray-200 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
        </div>
        <p class="text-4xl font-bold text-gray-900 mb-1">{@total_orgs}</p>
        <p class="text-xs text-green-600 font-medium">Total across platform</p>
      </div>

      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <div class="flex items-start justify-between mb-3">
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider">Users</p>
          <div class="w-8 h-8 rounded-lg border border-gray-200 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </div>
        </div>
        <p class="text-4xl font-bold text-gray-900 mb-1">{@total_users}</p>
        <p class="text-xs text-green-600 font-medium">Registered users</p>
      </div>

      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <div class="flex items-start justify-between mb-3">
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider">Registers</p>
          <div class="w-8 h-8 rounded-lg border border-gray-200 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
        </div>
        <p class="text-4xl font-bold text-gray-900 mb-1">{@total_registers}</p>
        <p class="text-xs text-gray-400">Total across platform</p>
      </div>

      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <div class="flex items-start justify-between mb-3">
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider">Total Entries</p>
          <div class="w-8 h-8 rounded-lg border border-gray-200 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
            </svg>
          </div>
        </div>
        <p class="text-4xl font-bold text-gray-900 mb-1">{@total_entries}</p>
        <p class="text-xs text-green-600 font-medium">Live data</p>
      </div>

    </div>

    <%!-- Two-column layout --%>
    <div class="flex gap-6 items-start">

      <%!-- Left column --%>
      <div class="flex-1 min-w-0 space-y-6">

        <%!-- Recent Companies table --%>
        <div class="bg-white rounded-xl border border-gray-200">
          <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
            <div>
              <p class="text-xs text-gray-400 font-medium mb-0.5">Recent</p>
              <h2 class="text-base font-semibold text-gray-900">Companies</h2>
            </div>
            <a href={~p"/super-admin/companies"} class="text-sm text-indigo-600 hover:text-indigo-700 font-medium flex items-center gap-1">
              View all
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
              </svg>
            </a>
          </div>
          <div class="overflow-x-auto overflow-y-auto min-h-[320px] max-h-[420px]">
            <table class="w-full text-sm">
              <thead class="sticky top-0 bg-white z-10">
                <tr class="border-b border-gray-100">
                  <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">S No</th>
                  <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Company</th>
                  <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Created</th>
                  <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Registers</th>
                  <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Entries</th>
                  <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Status</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-50">
                <%= if @orgs == [] do %>
                  <tr>
                    <td colspan="6" class="px-6 py-10 text-center text-sm text-gray-400">
                      No companies yet.
                    </td>
                  </tr>
                <% else %>
                  <tr :for={{org, idx} <- Enum.with_index(@orgs, 1)} class="hover:bg-gray-50 transition-colors">
                    <td class="px-6 py-3 text-sm text-gray-400">{idx}</td>
                    <td class="px-6 py-3">
                      <p class="font-medium text-gray-900 text-sm">{org.name}</p>
                      <p class="text-xs text-gray-400">{org.industry || "—"}</p>
                    </td>
                    <td class="px-6 py-3">
                      <p class="text-sm text-gray-700">{fmt_date(org.inserted_at)}</p>
                      <p class="text-xs text-gray-400">{fmt_time(org.inserted_at)}</p>
                    </td>
                    <td class="px-6 py-3 text-sm text-gray-700">{org.registers_count}</td>
                    <td class="px-6 py-3 text-sm text-gray-700">{org.entries_count}</td>
                    <td class="px-6 py-3">
                      <span class={[
                        "inline-flex items-center gap-1.5 text-xs font-medium",
                        if(org.is_active, do: "text-green-700", else: "text-gray-400")
                      ]}>
                        <span class={[
                          "w-1.5 h-1.5 rounded-full flex-shrink-0",
                          if(org.is_active, do: "bg-green-500", else: "bg-gray-300")
                        ]}></span>
                        {if org.is_active, do: "Active", else: "Inactive"}
                      </span>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>

        <%!-- Platform Activity --%>
        <div class="bg-white rounded-xl border border-gray-200">
          <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
            <div>
              <h2 class="text-base font-semibold text-gray-900">Platform Activity</h2>
              <p class="text-xs text-gray-400 mt-0.5">Daily logins and new companies</p>
            </div>
            <div class="flex items-center gap-2">
              <select class="text-xs border border-gray-200 rounded-lg px-2.5 py-1.5 text-gray-600 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-400">
                <option>January</option><option>February</option><option>March</option>
                <option>April</option><option>May</option><option selected>June</option>
                <option>July</option><option>August</option><option>September</option>
                <option>October</option><option>November</option><option>December</option>
              </select>
              <select class="text-xs border border-gray-200 rounded-lg px-2.5 py-1.5 text-gray-600 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-400">
                <option selected>2026</option><option>2025</option>
              </select>
              <div class="flex items-center gap-3 ml-2">
                <span class="flex items-center gap-1.5 text-xs text-gray-500">
                  <span class="w-2.5 h-2.5 rounded-full bg-indigo-400 inline-block"></span>
                  Active Users
                </span>
                <span class="flex items-center gap-1.5 text-xs text-gray-500">
                  <span class="w-2.5 h-2.5 rounded-full bg-blue-200 inline-block"></span>
                  New Companies
                </span>
              </div>
            </div>
          </div>
          <div class="px-6 py-5">
            <div class="flex items-end gap-1.5 h-48">
              <div :for={h <- [20, 45, 30, 70, 55, 80, 40, 90, 60, 35, 65, 50, 75, 45, 55, 85, 40, 70, 30, 60, 50, 80, 65, 35, 55, 75, 45, 60, 70, 40]} class="flex-1 bg-indigo-100 rounded-t-sm" style={"height: #{h}%"}></div>
            </div>
            <div class="flex justify-between mt-2 text-xs text-gray-400">
              <span>1</span><span>5</span><span>10</span><span>15</span><span>20</span><span>25</span><span>30</span>
            </div>
          </div>
        </div>

      </div>

      <%!-- Right column --%>
      <div class="w-96 flex-shrink-0 space-y-4">

        <%!-- Activity feed --%>
        <div class="bg-white rounded-xl border border-gray-200">
          <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
            <h3 class="text-sm font-semibold text-gray-900">Activity</h3>
            <div class="flex items-center gap-1.5">
              <button phx-click="clear_activity" data-confirm="Clear all activity? This cannot be undone."
                class="text-xs font-medium text-red-600 hover:text-red-700 border border-red-200 hover:border-red-300 hover:bg-red-50 rounded px-2.5 py-1 transition-colors">
                Clear
              </button>
              <span class="inline-flex items-center gap-1 text-xs font-medium text-green-600 bg-green-50 border border-green-200 rounded px-2.5 py-1">
                <span class="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse"></span>
                Live
              </span>
            </div>
          </div>
          <div class="px-5 py-4 space-y-5 min-h-[480px] max-h-[560px] overflow-y-auto">
            <%= if @activity == [] do %>
              <p class="text-xs text-gray-400 text-center py-6">No activity yet.</p>
            <% else %>
              <div :for={item <- @activity} class="flex items-start gap-3">
                <div class="w-7 h-7 rounded-full bg-indigo-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <svg class="w-3.5 h-3.5 text-indigo-600" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 12c2.7 0 4.8-2.1 4.8-4.8S14.7 2.4 12 2.4 7.2 4.5 7.2 7.2 9.3 12 12 12zm0 2.4c-3.2 0-9.6 1.6-9.6 4.8v2.4h19.2v-2.4c0-3.2-6.4-4.8-9.6-4.8z"/>
                  </svg>
                </div>
                <div class="min-w-0">
                  <p class="text-sm text-gray-700 leading-snug">
                    <span :if={item.user_name} class="font-medium">{item.user_name}</span>
                    {item.action}
                  </p>
                  <p class="text-xs text-gray-400 mt-0.5">{fmt_dt(item.inserted_at)}</p>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <%!-- Quick actions --%>
        <div class="bg-white rounded-xl border border-gray-200">
          <div class="px-5 py-4 border-b border-gray-100">
            <h3 class="text-sm font-semibold text-gray-900">Quick actions</h3>
          </div>
          <div class="p-5 grid grid-cols-2 gap-4">
            <a href={~p"/super-admin/companies"} class="flex items-center gap-3 px-4 py-4 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors text-sm font-medium text-gray-700 w-full">
              <svg class="w-5 h-5 text-indigo-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3m0 0v3m0-3h3m-3 0H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              + New org
            </a>
            <a href={~p"/super-admin/users"} class="flex items-center gap-3 px-4 py-4 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors text-sm font-medium text-gray-700 w-full">
              <svg class="w-5 h-5 text-blue-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              Users
            </a>
            <a href={~p"/super-admin/settings"} class="flex items-center gap-3 px-4 py-4 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors text-sm font-medium text-gray-700 w-full">
              <svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              Settings
            </a>
            <a href={~p"/super-admin/registers"} class="flex items-center gap-3 px-4 py-4 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors text-sm font-medium text-gray-700 w-full">
              <svg class="w-5 h-5 text-orange-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
              Register
            </a>
          </div>
        </div>

      </div>

    </div>
    """
  end
end
