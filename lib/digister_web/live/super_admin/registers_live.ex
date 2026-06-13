defmodule DigisterWeb.SuperAdmin.RegistersLive do
  use DigisterWeb, :live_view

  import Ecto.Query, warn: false
  alias Digister.Repo
  alias Digister.Registers.Register
  alias Digister.Organisations

  on_mount {DigisterWeb.SuperAdminAuth, :require_super_admin}

  def mount(_params, _session, socket) do
    registers = list_all_registers()
    orgs = Organisations.list_organisations()

    {:ok,
     socket
     |> assign(:page_title, "Registers")
     |> assign(:active_nav, :registers)
     |> assign(:registers, registers)
     |> assign(:orgs, orgs)
     |> assign(:search, "")
     |> assign(:show_modal, false)
     |> assign(:form_errors, %{})
     |> assign(:form_data, %{"name" => "", "description" => "", "category" => "", "organisation_id" => ""})}
  end

  def handle_event("search", %{"q" => q}, socket) do
    q = String.downcase(String.trim(q))
    filtered =
      list_all_registers()
      |> Enum.filter(fn r ->
        String.contains?(String.downcase(r.name || ""), q) or
        String.contains?(String.downcase(r.category || ""), q) or
        String.contains?(String.downcase(r.org_name || ""), q)
      end)
    {:noreply, socket |> assign(:search, q) |> assign(:registers, filtered)}
  end

  def handle_event("open_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_modal, true)
     |> assign(:form_errors, %{})
     |> assign(:form_data, %{"name" => "", "description" => "", "category" => "", "organisation_id" => ""})}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, socket |> assign(:show_modal, false) |> assign(:form_errors, %{})}
  end

  def handle_event("create_register", %{"name" => name, "description" => desc, "category" => cat, "organisation_id" => org_id}, socket) do
    errors =
      %{}
      |> then(fn e -> if String.trim(name) == "", do: Map.put(e, :name, "Register name is required."), else: e end)
      |> then(fn e -> if String.trim(org_id) == "", do: Map.put(e, :organisation_id, "Company is required."), else: e end)

    if errors == %{} do
      case Digister.Registers.create_register(%{
        name: name,
        description: desc,
        category: cat,
        organisation_id: org_id
      }) do
        {:ok, _register} ->
          {:noreply,
           socket
           |> assign(:registers, list_all_registers())
           |> assign(:show_modal, false)
           |> put_flash(:info, "Register created successfully.")}
        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to create register.")}
      end
    else
      {:noreply, assign(socket, :form_errors, errors)}
    end
  end

  defp list_all_registers do
    Repo.all(
      from r in Register,
        left_join: o in Digister.Organisations.Organisation, on: r.organisation_id == o.id,
        where: is_nil(r.deleted_at),
        order_by: [desc: r.inserted_at],
        select: %{
          id: r.id,
          name: r.name,
          description: r.description,
          category: r.category,
          is_active: r.is_active,
          entries_count: r.entries_count,
          inserted_at: r.inserted_at,
          org_name: o.name
        }
    )
  end

  defp fmt_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y")
  defp fmt_date(_), do: "—"

  def render(assigns) do
    ~H"""
    <div>
      <div class="flex items-start justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Registers</h1>
          <p class="text-sm text-gray-400 mt-0.5">All data registers across organisations</p>
        </div>
      </div>

      <%!-- Toolbar --%>
      <div class="flex items-center gap-3 mb-5">
        <div class="relative flex-1">
          <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input type="text" placeholder="Search by name, category, or company..."
            phx-keyup="search" name="q" value={@search}
            class="w-full border border-gray-200 rounded-lg pl-9 pr-4 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent bg-white" />
        </div>
        <a href={~p"/digisters/superadmin/registers/new"}
          class="flex items-center gap-1.5 rounded-lg bg-gray-900 hover:bg-gray-700 px-4 py-2.5 text-sm font-medium text-white transition-colors">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
          </svg>
          New Register
        </a>
      </div>

      <%!-- Table --%>
      <div class="bg-white rounded-xl border border-gray-200 overflow-x-auto">
        <table class="w-full text-sm min-w-[700px]">
          <thead>
            <tr class="border-b border-gray-100">
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider w-12">S.No</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Name</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Company</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Category</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Entries</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Status</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Created</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= if @registers == [] do %>
              <tr>
                <td colspan="7" class="px-5 py-12 text-center text-sm text-gray-400">No registers found.</td>
              </tr>
            <% else %>
              <tr :for={{reg, idx} <- Enum.with_index(@registers, 1)} class="hover:bg-gray-50 transition-colors">
                <td class="px-5 py-4 text-sm text-gray-400">{idx}</td>
                <td class="px-5 py-4">
                  <p class="font-medium text-gray-900">{reg.name}</p>
                  <p :if={reg.description} class="text-xs text-gray-400 mt-0.5">{reg.description}</p>
                </td>
                <td class="px-5 py-4 text-sm text-gray-700">{reg.org_name || "—"}</td>
                <td class="px-5 py-4 text-sm text-gray-600">{reg.category || "—"}</td>
                <td class="px-5 py-4 text-sm text-gray-600">{reg.entries_count}</td>
                <td class="px-5 py-4">
                  <span class={[
                    "inline-flex items-center gap-1.5 text-xs font-medium",
                    if(reg.is_active, do: "text-green-600", else: "text-gray-400")
                  ]}>
                    <span class={[
                      "w-1.5 h-1.5 rounded-full",
                      if(reg.is_active, do: "bg-green-500", else: "bg-gray-300")
                    ]}></span>
                    {if reg.is_active, do: "Active", else: "Inactive"}
                  </span>
                </td>
                <td class="px-5 py-4 text-sm text-gray-600">{fmt_date(reg.inserted_at)}</td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>

      <%!-- New Register Modal --%>
      <div :if={@show_modal} class="fixed inset-0 z-50 flex items-center justify-center">
        <div class="absolute inset-0 bg-black/20" phx-click="close_modal"></div>
        <div class="relative bg-white rounded-lg shadow-lg w-full max-w-md mx-4 p-8">
          <h2 class="text-xl font-bold text-gray-900">New Register</h2>
          <p class="text-sm text-gray-500 mt-1 mb-6">Create a data register for a company.</p>
          <form phx-submit="create_register" class="space-y-5">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">
                Register Name <span class="text-red-500">*</span>
              </label>
              <input type="text" name="name" value={@form_data["name"]}
                placeholder="e.g. Employee Records"
                class={[
                  "w-full border rounded-lg px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:border-transparent",
                  if(@form_errors[:name], do: "border-red-400 focus:ring-red-300", else: "border-gray-300 focus:ring-gray-400")
                ]} />
              <p :if={@form_errors[:name]} class="mt-1.5 text-xs text-red-500">{@form_errors[:name]}</p>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">
                Company <span class="text-red-500">*</span>
              </label>
              <select name="organisation_id"
                class={[
                  "w-full border rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-white focus:outline-none focus:ring-2 focus:border-transparent",
                  if(@form_errors[:organisation_id], do: "border-red-400 focus:ring-red-300", else: "border-gray-300 focus:ring-gray-400")
                ]}>
                <option value="">Select company</option>
                <option :for={org <- @orgs} value={org.id}>{org.name}</option>
              </select>
              <p :if={@form_errors[:organisation_id]} class="mt-1.5 text-xs text-red-500">{@form_errors[:organisation_id]}</p>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Category</label>
              <input type="text" name="category" value={@form_data["category"]}
                placeholder="e.g. HR, Finance"
                class="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:border-transparent" />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Description</label>
              <textarea name="description" rows="2"
                placeholder="Optional description..."
                class="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:border-transparent resize-none">{@form_data["description"]}</textarea>
            </div>

            <div class="flex gap-3 pt-2">
              <button type="button" phx-click="close_modal"
                class="flex-1 border border-gray-300 rounded-lg px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50">
                Cancel
              </button>
              <button type="submit"
                class="flex-1 bg-gray-900 hover:bg-gray-700 rounded-lg px-4 py-2.5 text-sm font-medium text-white">
                Create Register
              </button>
            </div>
          </form>
        </div>
      </div>

    </div>
    """
  end
end
