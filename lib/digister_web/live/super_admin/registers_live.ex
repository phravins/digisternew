defmodule DigisterWeb.SuperAdmin.RegistersLive do
  use DigisterWeb, :live_view

  alias Digister.Organisations
  alias Digister.Registers

  on_mount {DigisterWeb.SuperAdminAuth, :require_super_admin}

  def mount(_params, _session, socket) do
    orgs = Organisations.list_organisations_with_register_counts()

    {:ok,
     socket
     |> assign(:page_title, "Registers")
     |> assign(:active_nav, :registers)
     |> assign(:view, :companies)
     |> assign(:all_orgs, orgs)
     |> assign(:orgs, orgs)
     |> assign(:selected_org, nil)
     |> assign(:all_registers, [])
     |> assign(:registers, [])
     |> assign(:search, "")}
  end

  def handle_params(%{"org_id" => org_id}, _uri, socket) do
    org = Organisations.get_organisation!(org_id)
    registers = Registers.list_registers(org_id)

    {:noreply,
     socket
     |> assign(:view, :registers)
     |> assign(:selected_org, org)
     |> assign(:all_registers, registers)
     |> assign(:registers, registers)
     |> assign(:search, "")}
  end

  def handle_params(_params, _uri, socket) do
    orgs = Organisations.list_organisations_with_register_counts()

    {:noreply,
     socket
     |> assign(:view, :companies)
     |> assign(:all_orgs, orgs)
     |> assign(:orgs, orgs)
     |> assign(:selected_org, nil)
     |> assign(:all_registers, [])
     |> assign(:registers, [])
     |> assign(:search, "")}
  end

  def handle_event("search", %{"q" => q}, socket) do
    q = String.downcase(String.trim(q))

    filtered =
      if socket.assigns.view == :companies do
        Enum.filter(socket.assigns.all_orgs, fn org ->
          String.contains?(String.downcase(org.name || ""), q) or
            String.contains?(String.downcase(org.slug || ""), q) or
            String.contains?(String.downcase(org.industry || ""), q)
        end)
      else
        Enum.filter(socket.assigns.all_registers, fn r ->
          String.contains?(String.downcase(r.name || ""), q) or
            String.contains?(String.downcase(r.category || ""), q) or
            String.contains?(String.downcase(r.description || ""), q)
        end)
      end

    assign_key = if socket.assigns.view == :companies, do: :orgs, else: :registers

    {:noreply, socket |> assign(:search, q) |> assign(assign_key, filtered)}
  end

  defp fmt_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y")
  defp fmt_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y")
  defp fmt_date(_), do: "—"

  def render(assigns) do
    ~H"""
    <div>
      <%= if @view == :companies do %>
        <%!-- ── Company folder view ── --%>
        <div class="flex items-center justify-between mb-6">
          <h1 class="text-2xl font-bold text-gray-900">Registers</h1>
          <div class="flex items-center gap-3">
            <div class="relative">
              <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <input type="text" placeholder="Search registers..."
                phx-keyup="search" name="q" value={@search}
                class="border border-gray-200 rounded-lg pl-9 pr-4 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent bg-white w-64" />
            </div>
            <a href={~p"/digisters/superadmin/registers/new"}
              class="flex items-center gap-1.5 rounded-lg bg-gray-900 hover:bg-gray-700 px-4 py-2.5 text-sm font-medium text-white transition-colors">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
              </svg>
              New register
            </a>
          </div>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-gray-100">
                <th class="text-left px-6 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Company</th>
                <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Industry</th>
                <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Status</th>
                <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Created</th>
                <th class="text-right px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Regs</th>
                <th class="w-10"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <%= if @orgs == [] do %>
                <tr>
                  <td colspan="6" class="px-6 py-16 text-center">
                    <div class="flex flex-col items-center gap-3">
                      <svg class="w-10 h-10 text-gray-300" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z" />
                      </svg>
                      <p class="text-sm font-medium text-gray-700">No companies found</p>
                      <p class="text-xs text-gray-400">Create a company first, then add registers to it.</p>
                    </div>
                  </td>
                </tr>
              <% else %>
                <tr :for={org <- @orgs} class="hover:bg-gray-50/60 transition-colors group">
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-3">
                      <div class="w-9 h-9 rounded-lg bg-gray-100 flex items-center justify-center flex-shrink-0">
                        <svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z" />
                        </svg>
                      </div>
                      <div>
                        <p class="font-semibold text-gray-900 text-sm">{org.name}</p>
                        <p class="text-xs text-gray-400 mt-0.5">{org.slug}</p>
                      </div>
                    </div>
                  </td>
                  <td class="px-5 py-4 text-sm text-gray-600">{org.industry || "—"}</td>
                  <td class="px-5 py-4">
                    <span class={[
                      "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium",
                      if(org.is_active,
                        do: "bg-green-50 border-green-200 text-green-700",
                        else: "bg-gray-50 border-gray-200 text-gray-500")
                    ]}>
                      {if org.is_active, do: "Active", else: "Inactive"}
                    </span>
                  </td>
                  <td class="px-5 py-4 text-sm text-gray-500">{fmt_date(org.inserted_at)}</td>
                  <td class="px-5 py-4 text-right">
                    <span class="text-sm font-semibold text-gray-900">{org.registers_count}</span>
                  </td>
                  <td class="px-3 py-4 text-right">
                    <a href={~p"/digisters/superadmin/registers/#{org.id}"}
                      class="inline-flex items-center justify-center w-7 h-7 rounded-full text-gray-400 hover:text-gray-700 hover:bg-gray-100 transition-colors">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
                      </svg>
                    </a>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>

      <% else %>
        <%!-- ── Register drill-down view ── --%>
        <div class="flex items-center justify-between mb-6">
          <div class="flex items-center gap-2 text-sm">
            <a href={~p"/digisters/superadmin/registers"}
              class="flex items-center gap-1.5 text-gray-500 hover:text-gray-900 transition-colors font-medium">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              Registers
            </a>
            <span class="text-gray-300">/</span>
            <span class="text-gray-900 font-semibold">{@selected_org.name}</span>
          </div>
          <div class="flex items-center gap-3">
            <div class="relative">
              <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <input type="text" placeholder="Search registers..."
                phx-keyup="search" name="q" value={@search}
                class="border border-gray-200 rounded-lg pl-9 pr-4 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent bg-white w-64" />
            </div>
            <a href={~p"/digisters/superadmin/registers/new"}
              class="flex items-center gap-1.5 rounded-lg bg-gray-900 hover:bg-gray-700 px-4 py-2.5 text-sm font-medium text-white transition-colors">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
              </svg>
              New register
            </a>
          </div>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-gray-100">
                <th class="text-left px-6 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Name</th>
                <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Category</th>
                <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Entries</th>
                <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Status</th>
                <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Created</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <%= if @registers == [] do %>
                <tr>
                  <td colspan="5" class="px-6 py-16 text-center">
                    <div class="flex flex-col items-center gap-3">
                      <svg class="w-10 h-10 text-gray-300" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4" />
                      </svg>
                      <div>
                        <p class="text-sm font-medium text-gray-700">No registers yet</p>
                        <p class="text-xs text-gray-400 mt-0.5">Create the first register for {@selected_org.name}.</p>
                      </div>
                      <a href={~p"/digisters/superadmin/registers/new"}
                        class="mt-1 inline-flex items-center gap-1.5 rounded-lg border border-gray-300 px-3 py-1.5 text-xs font-medium text-gray-700 hover:bg-gray-50 transition-colors">
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                        </svg>
                        Create Register
                      </a>
                    </div>
                  </td>
                </tr>
              <% else %>
                <tr :for={reg <- @registers} class="hover:bg-gray-50/60 transition-colors">
                  <td class="px-6 py-4">
                    <p class="font-medium text-gray-900">{reg.name}</p>
                    <p :if={reg.description} class="text-xs text-gray-400 mt-0.5">{reg.description}</p>
                  </td>
                  <td class="px-5 py-4 text-sm text-gray-500">{reg.category || "—"}</td>
                  <td class="px-5 py-4 text-sm text-gray-700">{reg.entries_count}</td>
                  <td class="px-5 py-4">
                    <span class={[
                      "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium",
                      if(reg.is_active,
                        do: "bg-green-50 border-green-200 text-green-700",
                        else: "bg-gray-50 border-gray-200 text-gray-500")
                    ]}>
                      {if reg.is_active, do: "Active", else: "Inactive"}
                    </span>
                  </td>
                  <td class="px-5 py-4 text-sm text-gray-500">{fmt_date(reg.inserted_at)}</td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end
end
