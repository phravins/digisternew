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
     |> assign(:register, nil)
     |> assign(:fields, [])
     |> assign(:all_entries, [])
     |> assign(:entries, [])
     |> assign(:file_index, %{})
     |> assign(:search, "")}
  end

  def handle_params(%{"org_id" => org_id, "register_id" => register_id}, _uri, socket) do
    org = Organisations.get_organisation!(org_id)
    register = Registers.get_register!(register_id)
    fields = Registers.list_fields(register_id)
    entries = Registers.list_entries(register_id)

    file_index =
      Registers.list_file_uploads(register_id)
      |> Map.new(fn u -> {{u.entry_id, u.field_key}, u.original_name} end)

    {:noreply,
     socket
     |> assign(:view, :entries)
     |> assign(:selected_org, org)
     |> assign(:register, register)
     |> assign(:fields, fields)
     |> assign(:all_entries, entries)
     |> assign(:entries, entries)
     |> assign(:file_index, file_index)
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

    case socket.assigns.view do
      :companies ->
        filtered =
          Enum.filter(socket.assigns.all_orgs, fn org ->
            String.contains?(String.downcase(org.name || ""), q) or
              String.contains?(String.downcase(org.slug || ""), q) or
              String.contains?(String.downcase(org.industry || ""), q)
          end)

        {:noreply, socket |> assign(:search, q) |> assign(:orgs, filtered)}

      :registers ->
        filtered =
          Enum.filter(socket.assigns.all_registers, fn r ->
            String.contains?(String.downcase(r.name || ""), q) or
              String.contains?(String.downcase(r.category || ""), q) or
              String.contains?(String.downcase(r.description || ""), q)
          end)

        {:noreply, socket |> assign(:search, q) |> assign(:registers, filtered)}

      :entries ->
        filtered =
          Enum.filter(socket.assigns.all_entries, fn entry ->
            (entry.data || %{})
            |> Map.values()
            |> Enum.any?(fn v -> String.contains?(String.downcase(to_string(v)), q) end)
            |> Kernel.or(String.contains?(String.downcase(entry.added_by_name || ""), q))
          end)

        {:noreply, socket |> assign(:search, q) |> assign(:entries, filtered)}
    end
  end

  defp fmt_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y")
  defp fmt_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y")
  defp fmt_date(_), do: "—"

  def render(assigns) do
    ~H"""
    <div>
      <%= cond do %>
        <% @view == :companies -> %>
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

        <%!-- Column header row --%>
        <div :if={@orgs != []} class="grid grid-cols-[2.5fr_1.5fr_1fr_1fr_auto] items-center gap-4 px-5 mb-2">
          <div class="text-xs font-medium text-gray-400">Company</div>
          <div class="text-xs font-medium text-gray-400">Industry</div>
          <div class="text-xs font-medium text-gray-400">Status</div>
          <div class="text-xs font-medium text-gray-400">Created</div>
          <div class="text-xs font-medium text-gray-400 text-right w-16">Regs</div>
        </div>

        <%= if @orgs == [] do %>
          <div class="bg-white rounded-xl border border-gray-200 px-6 py-16 text-center">
            <div class="flex flex-col items-center gap-3">
              <svg class="w-10 h-10 text-gray-300" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z" />
              </svg>
              <p class="text-sm font-medium text-gray-700">No companies found</p>
              <p class="text-xs text-gray-400">Create a company first, then add registers to it.</p>
            </div>
          </div>
        <% else %>
          <div class="space-y-3">
            <a :for={org <- @orgs} href={~p"/digisters/superadmin/registers/#{org.id}"}
              class="grid grid-cols-[2.5fr_1.5fr_1fr_1fr_auto] items-center gap-4 bg-white rounded-xl border border-gray-200 px-5 py-4 hover:border-gray-300 hover:shadow-sm transition-all group">
              <%!-- Company --%>
              <div class="flex items-center gap-3 min-w-0">
                <div class="w-9 h-9 rounded-lg bg-gray-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z" />
                  </svg>
                </div>
                <div class="min-w-0">
                  <p class="font-semibold text-gray-900 text-sm truncate">{org.name}</p>
                  <p class="text-xs text-gray-400 mt-0.5 truncate">{org.slug}</p>
                </div>
              </div>
              <%!-- Industry --%>
              <div class="text-sm text-gray-600 truncate">{org.industry || "—"}</div>
              <%!-- Status --%>
              <div>
                <span class={[
                  "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium",
                  if(org.is_active,
                    do: "bg-green-50 border-green-200 text-green-700",
                    else: "bg-gray-50 border-gray-200 text-gray-500")
                ]}>
                  {if org.is_active, do: "Active", else: "Inactive"}
                </span>
              </div>
              <%!-- Created --%>
              <div class="text-sm text-gray-500">{fmt_date(org.inserted_at)}</div>
              <%!-- Regs + chevron --%>
              <div class="flex items-center justify-end gap-3 w-16">
                <span class="text-sm font-semibold text-gray-900">{org.registers_count}</span>
                <svg class="w-4 h-4 text-gray-300 group-hover:text-gray-500 transition-colors" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </a>
          </div>
        <% end %>

        <% @view == :registers -> %>
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

        <%!-- Simple company header --%>
        <div class="mb-6 text-center">
          <h2 class="text-xl font-bold text-gray-900">{@selected_org.name}</h2>
          <p :if={@selected_org.industry not in [nil, ""]} class="text-sm text-gray-600 mt-1">{@selected_org.industry}</p>
          <p :if={@selected_org.country not in [nil, ""]} class="text-sm text-gray-500 mt-0.5">{@selected_org.country}</p>
        </div>

        <%= if @registers == [] do %>
          <div class="bg-white rounded-xl border border-gray-200 px-6 py-16 text-center">
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
          </div>
        <% else %>
          <div class="space-y-3">
            <a :for={reg <- @registers}
              href={~p"/digisters/superadmin/registers/#{@selected_org.id}/r/#{reg.id}"}
              class="flex items-center justify-between bg-white rounded-xl border border-gray-200 px-5 py-4 hover:border-gray-300 hover:shadow-sm transition-all">
              <%!-- Name + entries --%>
              <div class="min-w-0">
                <p class="font-semibold text-gray-900 text-sm truncate">{reg.name}</p>
                <p class="text-xs text-gray-400 mt-0.5">
                  {reg.entries_count} {if reg.entries_count == 1, do: "entry", else: "entries"} · {fmt_date(reg.inserted_at)}
                </p>
              </div>
              <%!-- Status --%>
              <span class={[
                "inline-flex flex-shrink-0 items-center rounded-full border px-2.5 py-0.5 text-xs font-medium",
                if(reg.is_active,
                  do: "bg-green-50 border-green-200 text-green-700",
                  else: "bg-gray-50 border-gray-200 text-gray-500")
              ]}>
                {if reg.is_active, do: "Active", else: "Inactive"}
              </span>
            </a>
          </div>
        <% end %>

        <% true -> %>
        <%!-- ── Register entries (read-only) view ── --%>
        <div class="flex items-center justify-between mb-6">
          <a href={~p"/digisters/superadmin/registers/#{@selected_org.id}"}
            class="flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-900 transition-colors font-medium">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
            </svg>
            Back to Registers
          </a>
        </div>

        <%!-- Register header card --%>
        <div class="bg-white rounded-xl border border-gray-200 px-6 py-5 mb-6">
          <div class="flex items-start gap-3">
            <div class="w-10 h-10 rounded-lg bg-gray-100 flex items-center justify-center flex-shrink-0">
              <svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4" />
              </svg>
            </div>
            <div class="min-w-0">
              <div class="flex items-center gap-2">
                <h2 class="text-lg font-bold text-gray-900">{@register.name}</h2>
                <span class={[
                  "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium",
                  if(@register.is_active,
                    do: "bg-green-50 border-green-200 text-green-700",
                    else: "bg-gray-50 border-gray-200 text-gray-500")
                ]}>
                  {if @register.is_active, do: "Published", else: "Draft"}
                </span>
              </div>
              <p class="text-sm text-gray-400 mt-0.5">{@register.description || "No description"}</p>
              <div class="flex items-center gap-4 mt-3 text-xs text-gray-500">
                <span>{length(@fields)} {if length(@fields) == 1, do: "field", else: "fields"}</span>
                <span>{length(@all_entries)} {if length(@all_entries) == 1, do: "entry", else: "entries"}</span>
                <span>Updated {fmt_date(@register.updated_at)}</span>
              </div>
            </div>
          </div>
        </div>

        <%!-- Entries table (read-only) --%>
        <div class="flex items-center justify-between mb-4">
          <div class="relative">
            <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input type="text" placeholder="Search entries..."
              phx-keyup="search" name="q" value={@search}
              class="border border-gray-200 rounded-lg pl-9 pr-4 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent bg-white w-72" />
          </div>
          <span class="text-xs text-gray-400">{length(@entries)} {if length(@entries) == 1, do: "entry", else: "entries"}</span>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-gray-100">
                <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">S No</th>
                <th :for={field <- @fields} class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider whitespace-nowrap">{field.label}</th>
                <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Added by</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <%= if @entries == [] do %>
                <tr>
                  <td colspan={length(@fields) + 2} class="px-6 py-16 text-center">
                    <p class="text-sm font-medium text-gray-700">No entries yet</p>
                    <p class="text-xs text-gray-400 mt-0.5">This register has no entries.</p>
                  </td>
                </tr>
              <% else %>
                <tr :for={{entry, idx} <- Enum.with_index(@entries, 1)} class="hover:bg-gray-50/60 transition-colors">
                  <td class="px-5 py-4 text-sm text-gray-400">{idx}</td>
                  <td :for={field <- @fields} class="px-5 py-4 text-sm text-gray-700 whitespace-nowrap">
                    {render_cell(assigns, entry, field)}
                  </td>
                  <td class="px-5 py-4">
                    <div class="flex items-center gap-2">
                      <span class="w-7 h-7 rounded-full bg-emerald-500 text-white text-xs font-semibold flex items-center justify-center flex-shrink-0">
                        {entry.added_by_name |> to_string() |> String.first() |> to_string() |> String.upcase()}
                      </span>
                      <span class="text-sm text-gray-700">{entry.added_by_name}</span>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

  # Renders a single read-only entry cell based on the field type.
  defp render_cell(assigns, entry, field) do
    value = Map.get(entry.data || %{}, field.field_key)

    assigns =
      assign(assigns, :value, value)
      |> assign(:field, field)
      |> assign(:filename, Map.get(assigns.file_index, {entry.id, field.field_key}))

    ~H"""
    <%= cond do %>
      <% @field.field_type == "file" and @filename not in [nil, ""] -> %>
        <span class="inline-flex items-center gap-1.5 text-indigo-600">
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
          </svg>
          {@filename}
        </span>
      <% @field.field_type == "url" and @value not in [nil, ""] -> %>
        <a href={@value} target="_blank" rel="noopener noreferrer"
          class="inline-flex items-center gap-1.5 text-indigo-600 hover:underline">
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
          </svg>
          {@value}
        </a>
      <% @field.field_type == "email" and @value not in [nil, ""] -> %>
        <a href={"mailto:#{@value}"} class="text-indigo-600 hover:underline">{@value}</a>
      <% is_list(@value) -> %>
        {Enum.join(@value, ", ")}
      <% @value in [nil, ""] -> %>
        <span class="text-gray-300">—</span>
      <% true -> %>
        {to_string(@value)}
    <% end %>
    """
  end
end
