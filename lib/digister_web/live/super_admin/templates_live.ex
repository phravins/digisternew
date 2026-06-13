defmodule DigisterWeb.SuperAdmin.TemplatesLive do
  use DigisterWeb, :live_view

  alias Digister.Registers
  alias Digister.Organisations

  on_mount {DigisterWeb.SuperAdminAuth, :require_super_admin}

  def mount(_params, _session, socket) do
    templates = Registers.list_templates()
    orgs = Organisations.list_organisations()

    {:ok,
     socket
     |> assign(:page_title, "Templates")
     |> assign(:active_nav, :templates)
     |> assign(:all_templates, templates)
     |> assign(:templates, templates)
     |> assign(:orgs, orgs)
     |> assign(:applying, nil)
     |> assign(:apply_org_id, "")
     |> assign(:search, "")}
  end

  def handle_event("search", %{"q" => q}, socket) do
    q = String.downcase(q)
    filtered = Enum.filter(socket.assigns.all_templates, fn t ->
      String.contains?(String.downcase(t.name), q) ||
        String.contains?(String.downcase(t.description || ""), q)
    end)
    {:noreply, assign(socket, templates: filtered, search: q)}
  end

  def handle_event("open_apply", %{"id" => id}, socket) do
    {:noreply, assign(socket, applying: id, apply_org_id: "")}
  end

  def handle_event("cancel_apply", _params, socket) do
    {:noreply, assign(socket, applying: nil, apply_org_id: "")}
  end

  def handle_event("select_org", params, socket) do
    org_id = params["org_id"] || params["value"] || ""
    {:noreply, assign(socket, apply_org_id: org_id)}
  end

  def handle_event("confirm_apply", _params, socket) do
    template_id = socket.assigns.applying
    org_id = socket.assigns.apply_org_id

    if org_id == "" do
      {:noreply, put_flash(socket, :error, "Please select a company first.")}
    else
      case Registers.apply_template(template_id, org_id) do
        {:ok, _register} ->
          org = Enum.find(socket.assigns.orgs, &(&1.id == org_id))
          org_name = if org, do: org.name, else: "selected company"
          {:noreply,
           socket
           |> assign(applying: nil, apply_org_id: "")
           |> put_flash(:info, "Template applied to \"#{org_name}\" successfully.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to apply template. Please try again.")}
      end
    end
  end

  def handle_event("delete_template", %{"id" => id}, socket) do
    register = Registers.get_register!(id)
    Registers.soft_delete_register(register)
    templates = Registers.list_templates()
    {:noreply,
     socket
     |> assign(:all_templates, templates)
     |> assign(:templates, templates)
     |> put_flash(:info, "Template moved to Bin.")}
  end

  defp fmt_date(%NaiveDateTime{} = dt) do
    ist = NaiveDateTime.add(dt, 19800, :second)
    Calendar.strftime(ist, "%d %b %Y")
  end
  defp fmt_date(_), do: "—"

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-5">
      <div>
        <h1 class="text-xl font-bold text-gray-900">Templates</h1>
        <p class="text-sm text-gray-500 mt-0.5">Reusable register structures — apply to any company</p>
      </div>
      <a href={~p"/digisters/superadmin/registers/new"}
        class="flex items-center gap-2 bg-gray-900 hover:bg-gray-700 text-white px-4 py-2 rounded-lg text-sm font-semibold transition-colors">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
        </svg>
        New Template
      </a>
    </div>

    <%!-- Search --%>
    <div class="mb-4">
      <div class="relative max-w-sm">
        <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        <input type="text" value={@search} phx-keyup="search" phx-value-q="" phx-debounce="200"
          placeholder="Search templates..."
          class="w-full pl-9 pr-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" />
      </div>
    </div>

    <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
      <%= if @templates == [] do %>
        <div class="flex flex-col items-center justify-center py-16 text-center">
          <svg class="w-12 h-12 text-gray-200 mb-3" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
          </svg>
          <p class="text-sm font-medium text-gray-400">No templates yet</p>
          <p class="text-xs text-gray-300 mt-1">Create a register and check "Save as Template"</p>
        </div>
      <% else %>
        <table class="w-full text-sm">
          <thead class="bg-gray-50 border-b border-gray-100">
            <tr>
              <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Template</th>
              <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Fields</th>
              <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Created</th>
              <th class="text-right px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr :for={t <- @templates} class="hover:bg-gray-50 transition-colors">
              <td class="px-6 py-4">
                <div class="flex items-center gap-3">
                  <div class="w-8 h-8 rounded-lg bg-indigo-50 flex items-center justify-center flex-shrink-0">
                    <svg class="w-4 h-4 text-indigo-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                    </svg>
                  </div>
                  <div>
                    <p class="font-medium text-gray-900">{t.name}</p>
                    <p :if={t.description} class="text-xs text-gray-400 mt-0.5">{t.description}</p>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4">
                <span class="inline-flex items-center gap-1 text-xs font-medium text-gray-600 bg-gray-100 rounded-full px-2.5 py-0.5">
                  {length(t.fields)} fields
                </span>
              </td>
              <td class="px-6 py-4 text-sm text-gray-500">{fmt_date(t.inserted_at)}</td>
              <td class="px-6 py-4">
                <%= if @applying == t.id do %>
                  <%!-- Inline apply panel --%>
                  <div class="flex items-center gap-2 justify-end flex-wrap">
                    <select
                      class="text-xs border border-gray-200 rounded-lg px-2.5 py-1.5 bg-white text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-400"
                      phx-change="select_org"
                      name="org_id">
                      <option value="">Select company...</option>
                      <option :for={org <- @orgs} value={org.id}
                        selected={@apply_org_id == org.id}>{org.name}</option>
                    </select>
                    <button type="button" phx-click="confirm_apply"
                      class="text-xs px-3 py-1.5 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors">
                      Apply
                    </button>
                    <button type="button" phx-click="cancel_apply"
                      class="text-xs px-3 py-1.5 border border-gray-200 text-gray-500 rounded-lg hover:bg-gray-50 transition-colors">
                      Cancel
                    </button>
                  </div>
                <% else %>
                  <div class="flex items-center gap-2 justify-end">
                    <button type="button" phx-click="open_apply" phx-value-id={t.id}
                      class="text-xs px-3 py-1.5 bg-indigo-50 text-indigo-600 border border-indigo-200 rounded-lg font-medium hover:bg-indigo-100 transition-colors whitespace-nowrap">
                      Apply to Company
                    </button>
                    <button type="button" phx-click="delete_template" phx-value-id={t.id}
                      class="text-xs px-3 py-1.5 border border-gray-200 text-gray-400 rounded-lg hover:text-red-500 hover:border-red-200 transition-colors">
                      Delete
                    </button>
                  </div>
                <% end %>
              </td>
            </tr>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end
end
