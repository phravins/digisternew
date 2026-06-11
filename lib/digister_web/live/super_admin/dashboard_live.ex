defmodule DigisterWeb.SuperAdmin.DashboardLive do
  use DigisterWeb, :live_view

  alias Digister.Accounts
  alias Digister.Organisations
  alias Digister.Registers

  on_mount {DigisterWeb.SuperAdminAuth, :require_super_admin}

  @orgs [
    %{initials: "AC", color: "bg-indigo-100 text-indigo-600", name: "Acme Corp", domain: "acme.digister.com", status: :active, users: 1_420, plan: "Enterprise", created: "Oct 12, 2023"},
    %{initials: "GL", color: "bg-blue-100 text-blue-600", name: "Global Logistics", domain: "globallog.digister.com", status: :active, users: 840, plan: "Pro", created: "Nov 03, 2023"},
    %{initials: "ST", color: "bg-orange-100 text-orange-600", name: "Stark Tech", domain: "stark.digister.com", status: :trial, users: 12, plan: "Starter", created: "Jan 15, 2024"}
  ]

  def mount(_params, _session, socket) do
    total_users = Accounts.count_users()
    total_orgs = Organisations.count_organisations()
    total_registers = Registers.count_registers()
    total_entries = Registers.count_entries()

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:active_nav, :dashboard)
     |> assign(:total_users, total_users)
     |> assign(:total_orgs, total_orgs)
     |> assign(:total_registers, total_registers)
     |> assign(:total_entries, total_entries)
     |> assign(:orgs, @orgs)}
  end

  def render(assigns) do
    ~H"""
    <%!-- Page heading --%>
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-900">Global Overview</h1>
      <p class="text-sm text-gray-500 mt-0.5">Monitor and manage your multi-tenant ecosystem.</p>
    </div>

    <%!-- Stat cards --%>
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">

      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <div class="flex items-start justify-between mb-4">
          <div class="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
            <svg class="w-5 h-5 text-blue-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          <span class="text-xs font-medium text-green-600 bg-green-50 px-2 py-0.5 rounded-full">+12%</span>
        </div>
        <p class="text-sm text-gray-500 mb-1">Total Tenants</p>
        <p class="text-3xl font-bold text-gray-900">{@total_orgs}</p>
      </div>

      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <div class="flex items-start justify-between mb-4">
          <div class="w-10 h-10 rounded-lg bg-indigo-50 flex items-center justify-center">
            <svg class="w-5 h-5 text-indigo-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </div>
          <span class="text-xs font-medium text-green-600 bg-green-50 px-2 py-0.5 rounded-full">+5.4%</span>
        </div>
        <p class="text-sm text-gray-500 mb-1">Active Users</p>
        <p class="text-3xl font-bold text-gray-900">{@total_users}</p>
      </div>

      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <div class="flex items-start justify-between mb-4">
          <div class="w-10 h-10 rounded-lg bg-purple-50 flex items-center justify-center">
            <svg class="w-5 h-5 text-purple-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
          <span class="text-xs font-medium text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full">Stable</span>
        </div>
        <p class="text-sm text-gray-500 mb-1">Registers Created</p>
        <p class="text-3xl font-bold text-gray-900">{@total_registers}</p>
      </div>

      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <div class="flex items-start justify-between mb-4">
          <div class="w-10 h-10 rounded-lg bg-orange-50 flex items-center justify-center">
            <svg class="w-5 h-5 text-orange-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
            </svg>
          </div>
          <span class="text-xs font-medium text-red-500 bg-red-50 px-2 py-0.5 rounded-full">-2%</span>
        </div>
        <p class="text-sm text-gray-500 mb-1">Avg. Completion</p>
        <p class="text-3xl font-bold text-gray-900">64.8%</p>
      </div>

    </div>

    <%!-- Recent organizations table --%>
    <div class="bg-white rounded-xl border border-gray-200">
      <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
        <h2 class="text-base font-semibold text-gray-900">Recent Organizations</h2>
        <div class="flex items-center gap-2">
          <%!-- Filter icon --%>
          <button class="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors" title="Filter">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2a1 1 0 01-.293.707L13 13.414V19a1 1 0 01-.553.894l-4 2A1 1 0 017 21v-7.586L3.293 6.707A1 1 0 013 6V4z" />
            </svg>
          </button>
          <%!-- Download icon --%>
          <button class="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors" title="Export">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
            </svg>
          </button>
        </div>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-gray-100">
              <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Organization</th>
              <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Status</th>
              <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Users</th>
              <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Plan</th>
              <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Created</th>
              <th class="px-6 py-3"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr :for={org <- @orgs} class="hover:bg-gray-50 transition-colors">
              <td class="px-6 py-4">
                <div class="flex items-center gap-3">
                  <div class={"w-8 h-8 rounded-lg flex items-center justify-center text-xs font-bold flex-shrink-0 #{org.color}"}>
                    {org.initials}
                  </div>
                  <div>
                    <p class="font-medium text-gray-900">{org.name}</p>
                    <p class="text-xs text-gray-400">{org.domain}</p>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4">
                <span class={[
                  "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                  if(org.status == :active, do: "bg-indigo-50 text-indigo-600", else: "bg-orange-50 text-orange-500")
                ]}>
                  {if org.status == :active, do: "Active", else: "Trial"}
                </span>
              </td>
              <td class="px-6 py-4 text-gray-600">
                {org.users |> Integer.to_string() |> then(&Regex.replace(~r/\B(?=(\d{3})+(?!\d))/, &1, ","))}
              </td>
              <td class="px-6 py-4 text-gray-600">{org.plan}</td>
              <td class="px-6 py-4 text-gray-400">{org.created}</td>
              <td class="px-6 py-4 text-right">
                <button class="text-gray-400 hover:text-gray-600 transition-colors" title="Actions">
                  <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 5a1.5 1.5 0 110-3 1.5 1.5 0 010 3zm0 7a1.5 1.5 0 110-3 1.5 1.5 0 010 3zm0 7a1.5 1.5 0 110-3 1.5 1.5 0 010 3z"/>
                  </svg>
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
