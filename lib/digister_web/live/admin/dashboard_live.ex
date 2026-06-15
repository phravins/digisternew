defmodule DigisterWeb.Admin.DashboardLive do
  use DigisterWeb, :live_view

  alias Digister.Accounts
  alias Digister.Registers

  on_mount {DigisterWeb.Admin.AdminAuth, :require_admin}

  def mount(_params, _session, socket) do
    org = socket.assigns.current_organisation

    registers = Registers.list_registers(org.id)
    top_registers = registers |> Enum.sort_by(& &1.entries_count, :desc) |> Enum.take(5)

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:active_nav, :dashboard)
     |> assign(:total_registers, Registers.count_registers(org.id))
     |> assign(:total_entries, Registers.count_entries(org.id))
     |> assign(:total_users, length(Accounts.list_users_by_organisation(org.id)))
     |> assign(:recent_entries, Registers.list_recent_entries(org.id, 8))
     |> assign(:top_registers, top_registers)}
  end

  def render(assigns) do
    ~H"""
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-900">Dashboard</h1>
      <p class="text-sm text-gray-500 mt-0.5">{@current_organisation.name} workspace overview</p>
    </div>

    <%!-- Stat cards --%>
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">Registers</p>
        <p class="text-4xl font-bold text-gray-900">{@total_registers}</p>
        <p class="text-xs text-gray-400 mt-1">Active in this company</p>
      </div>
      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">Entries</p>
        <p class="text-4xl font-bold text-gray-900">{@total_entries}</p>
        <p class="text-xs text-gray-400 mt-1">Total submitted</p>
      </div>
      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">Team</p>
        <p class="text-4xl font-bold text-gray-900">{@total_users}</p>
        <p class="text-xs text-gray-400 mt-1">Members in this company</p>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
      <%!-- Latest entries --%>
      <div class="lg:col-span-2 bg-white rounded-xl border border-gray-200">
        <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <div>
            <p class="text-xs text-gray-400 font-medium">Recent activity</p>
            <h2 class="text-base font-semibold text-gray-900">Latest entries</h2>
          </div>
          <a href={~p"/digisters/#{@current_organisation.slug}/registers"} class="text-sm font-medium text-indigo-600 hover:underline">All registers</a>
        </div>
        <%= if @recent_entries == [] do %>
          <div class="px-6 py-16 text-center">
            <p class="text-sm font-medium text-gray-700">No entries yet</p>
            <p class="text-xs text-gray-400 mt-0.5">Entries will appear here as your team submits them.</p>
          </div>
        <% else %>
          <ul class="divide-y divide-gray-50">
            <li :for={e <- @recent_entries} class="px-6 py-3 flex items-center justify-between">
              <div class="min-w-0">
                <p class="text-sm font-medium text-gray-800 truncate">{e.register_name}</p>
                <p class="text-xs text-gray-400">by {e.added_by_name || "—"}</p>
              </div>
              <span class="text-xs text-gray-400 flex-shrink-0">{fmt_dt(e.inserted_at)}</span>
            </li>
          </ul>
        <% end %>
      </div>

      <%!-- Company + top registers --%>
      <div class="space-y-6">
        <div class="bg-white rounded-xl border border-gray-200 p-5">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-base font-semibold text-gray-900">Company details</h2>
            <span class={[
              "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium",
              if(@current_organisation.is_active, do: "bg-green-50 border-green-200 text-green-700", else: "bg-gray-50 border-gray-200 text-gray-500")
            ]}>
              {if @current_organisation.is_active, do: "Active", else: "Inactive"}
            </span>
          </div>
          <dl class="space-y-3 text-sm">
            <div>
              <dt class="text-xs text-gray-400">Company ID</dt>
              <dd class="text-gray-700 font-mono text-xs break-all">{@current_organisation.id}</dd>
            </div>
            <div>
              <dt class="text-xs text-gray-400">Link</dt>
              <dd class="text-gray-700">apps.realoffice.in/digisters/{@current_organisation.slug}</dd>
            </div>
            <div>
              <dt class="text-xs text-gray-400">Created</dt>
              <dd class="text-gray-700">{fmt_date(@current_organisation.inserted_at)}</dd>
            </div>
          </dl>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-5">
          <h2 class="text-base font-semibold text-gray-900 mb-3">Top registers</h2>
          <%= if @top_registers == [] do %>
            <p class="text-sm text-gray-400 text-center py-4">No registers yet</p>
          <% else %>
            <ul class="space-y-2">
              <li :for={r <- @top_registers} class="flex items-center justify-between text-sm">
                <span class="text-gray-700 truncate">{r.name}</span>
                <span class="text-gray-400 flex-shrink-0">{r.entries_count} {if r.entries_count == 1, do: "entry", else: "entries"}</span>
              </li>
            </ul>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp fmt_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y")
  defp fmt_date(_), do: "—"

  defp fmt_dt(%NaiveDateTime{} = dt) do
    ist = NaiveDateTime.add(dt, 19800, :second)
    Calendar.strftime(ist, "%d %b %Y · %I:%M %p")
  end
  defp fmt_dt(_), do: "—"
end
