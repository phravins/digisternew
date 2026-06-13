defmodule DigisterWeb.SuperAdmin.CompaniesLive do
  use DigisterWeb, :live_view

  alias Digister.Organisations
  alias Digister.Activities

  on_mount {DigisterWeb.SuperAdminAuth, :require_super_admin}

  @industries ["Agriculture", "Automotive", "Consulting & Advisory", "Education", "Energy",
               "Finance & Banking", "Healthcare & Medical", "Hospitality & Tourism", "Legal",
               "Manufacturing", "Media & Entertainment", "Real Estate", "Retail", "Technology"]

  @countries ["India", "United States", "United Kingdom", "Canada", "Australia",
              "Germany", "France", "Singapore", "UAE", "Other"]

  def mount(_params, _session, socket) do
    orgs = Organisations.list_organisations()

    {:ok,
     socket
     |> assign(:page_title, "Companies")
     |> assign(:active_nav, :companies)
     |> assign(:orgs, orgs)
     |> assign(:all_orgs, orgs)
     |> assign(:search, "")
     |> assign(:filter, "all")
     |> assign(:show_modal, false)
     |> assign(:modal_step, 1)
     |> assign(:industries, @industries)
     |> assign(:countries, @countries)
     |> assign(:form_data, %{"name" => "", "slug" => "", "industry" => "", "country" => ""})}
  end

  def handle_event("search", %{"q" => q}, socket) do
    q = String.downcase(String.trim(q))
    filtered =
      socket.assigns.all_orgs
      |> Enum.filter(fn org ->
        String.contains?(String.downcase(org.name || ""), q) or
        String.contains?(String.downcase(org.industry || ""), q) or
        String.contains?(String.downcase(org.owner || ""), q)
      end)
    {:noreply, socket |> assign(:search, q) |> assign(:orgs, filtered)}
  end

  def handle_event("filter", %{"status" => status}, socket) do
    filtered =
      case status do
        "active" -> Enum.filter(socket.assigns.all_orgs, & &1.is_active)
        "inactive" -> Enum.filter(socket.assigns.all_orgs, &(!&1.is_active))
        _ -> socket.assigns.all_orgs
      end
    {:noreply, socket |> assign(:filter, status) |> assign(:orgs, filtered)}
  end

  def handle_event("open_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_modal, true)
     |> assign(:modal_step, 1)
     |> assign(:form_data, %{"name" => "", "slug" => "", "industry" => "", "country" => ""})}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  def handle_event("next_step", %{"name" => name, "slug" => slug, "industry" => industry, "country" => country}, socket) do
    cond do
      String.trim(name) == "" ->
        {:noreply, put_flash(socket, :error, "Company name is required.")}
      String.trim(slug) == "" ->
        {:noreply, put_flash(socket, :error, "Link is required.")}
      true ->
        {:noreply,
         socket
         |> assign(:modal_step, 2)
         |> assign(:form_data, %{"name" => name, "slug" => slug, "industry" => industry, "country" => country})}
    end
  end

  def handle_event("create_company", %{"admin_first_name" => first, "admin_last_name" => last, "admin_email" => admin_email} = params, socket) do
    data = socket.assigns.form_data
    admin_name = String.trim("#{first} #{last}")
    admin_phone = Map.get(params, "admin_phone", "")
    cond do
      String.trim(admin_email) == "" ->
        {:noreply, put_flash(socket, :error, "Admin email is required.")}
      true ->
        case Organisations.create_organisation(%{
          name: data["name"],
          slug: data["slug"],
          industry: data["industry"],
          country: data["country"],
          owner: admin_name,
          owner_email: admin_email,
          owner_phone: admin_phone
        }) do
          {:ok, org} ->
            Activities.log(%{user_name: "Admin", action: "created company #{org.name}"})
            orgs = Organisations.list_organisations()
            {:noreply,
             socket
             |> assign(:orgs, orgs)
             |> assign(:all_orgs, orgs)
             |> assign(:show_modal, false)
             |> put_flash(:info, "Company created successfully.")}
          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to create company. Check the link is unique.")}
        end
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    org = Organisations.get_organisation!(id)
    Organisations.delete_organisation(org)
    orgs = Organisations.list_organisations()
    {:noreply, socket |> assign(:orgs, orgs) |> assign(:all_orgs, orgs) |> put_flash(:error, "Company deactivated.")}
  end

  defp fmt_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y")
  defp fmt_date(_), do: "—"

  def render(assigns) do
    ~H"""
    <div>
      <%!-- Header --%>
      <div class="flex items-start justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Companies</h1>
          <p class="text-sm text-gray-400 mt-0.5">Manage and monitor all tenant workspaces</p>
        </div>
      </div>

      <%!-- Toolbar --%>
      <div class="flex items-center gap-3 mb-5">
        <div class="relative flex-1">
          <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input type="text" placeholder="Search by name, industry, or admin..."
            phx-keyup="search" phx-value-q="" name="q"
            value={@search}
            class="w-full border border-gray-200 rounded-lg pl-9 pr-4 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent bg-white" />
        </div>
        <div class="relative">
          <select phx-change="filter" name="status"
            class="border border-gray-200 rounded-lg pl-3 pr-8 py-2.5 text-sm text-gray-700 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-400 appearance-none cursor-pointer">
            <option value="all">All &nbsp;{length(@all_orgs)}</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
          <svg class="absolute right-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400 pointer-events-none" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
          </svg>
        </div>
        <a href="/super-admin/companies/export"
          class="flex items-center gap-1.5 border border-gray-200 rounded-lg px-4 py-2.5 text-sm font-medium text-gray-600 bg-white hover:bg-gray-50 transition-colors">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
          </svg>
          Export
        </a>
        <button type="button" phx-click="open_modal"
          class="flex items-center gap-1.5 rounded-lg bg-gray-900 hover:bg-gray-700 px-4 py-2.5 text-sm font-medium text-white transition-colors">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
          </svg>
          New company
        </button>
      </div>

      <%!-- Table --%>
      <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-gray-100">
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider w-12">S.No</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Company</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Industry</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Created</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Status</th>
              <th class="text-right px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <%= if @orgs == [] do %>
              <tr>
                <td colspan="6" class="px-5 py-12 text-center text-sm text-gray-400">No companies found.</td>
              </tr>
            <% else %>
              <tr :for={{org, idx} <- Enum.with_index(@orgs, 1)} class="hover:bg-gray-50 transition-colors">
                <td class="px-5 py-4 text-sm text-gray-400">{idx}</td>
                <td class="px-5 py-4">
                  <p class="font-medium text-gray-900">{org.name}</p>
                  <p class="text-xs text-gray-400 mt-0.5">{org.slug}</p>
                </td>
                <td class="px-5 py-4 text-sm text-gray-600">{org.industry || "—"}</td>
                <td class="px-5 py-4 text-sm text-gray-600">{fmt_date(org.inserted_at)}</td>
                <td class="px-5 py-4">
                  <span class={[
                    "inline-flex items-center gap-1.5 text-xs font-medium",
                    if(org.is_active, do: "text-green-600", else: "text-gray-400")
                  ]}>
                    <span class={[
                      "w-1.5 h-1.5 rounded-full",
                      if(org.is_active, do: "bg-green-500", else: "bg-gray-300")
                    ]}></span>
                    {if org.is_active, do: "Active", else: "Inactive"}
                  </span>
                </td>
                <td class="px-5 py-4">
                  <div class="flex items-center justify-end gap-3">
                    <button type="button" class="text-gray-400 hover:text-gray-600 transition-colors">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                      </svg>
                    </button>
                    <button type="button" class="text-gray-400 hover:text-indigo-600 transition-colors">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                      </svg>
                    </button>
                    <button type="button"
                      phx-click="delete"
                      phx-value-id={org.id}
                      data-confirm="Deactivate this company?"
                      class="text-gray-400 hover:text-red-500 transition-colors">
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
      <%!-- New Company Modal --%>
      <div :if={@show_modal} class="fixed inset-0 z-50 flex items-center justify-center">
        <div class="absolute inset-0 bg-black/20" phx-click="close_modal"></div>
        <div class="relative bg-white rounded-lg shadow-lg w-full max-w-md mx-4 p-8">

          <%!-- Step 1 — Company Details --%>
          <div :if={@modal_step == 1}>
            <h2 class="text-xl font-bold text-gray-900">Create Company</h2>
            <p class="text-sm text-gray-500 mt-1 mb-6">Set up the company workspace details.</p>
            <form phx-submit="next_step" class="space-y-5">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1.5">Company Name</label>
                <input type="text" name="name" value={@form_data["name"]}
                  placeholder="Acme Inc."
                  class="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:border-transparent" />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1.5">
                  Workspace Link
                  <span class="ml-1 text-xs text-gray-400 font-normal">Used in workspace URL</span>
                </label>
                <div class="flex items-stretch border border-gray-300 rounded-lg overflow-hidden focus-within:ring-2 focus-within:ring-gray-400">
                  <span class="px-3 py-2.5 bg-gray-50 text-xs text-gray-400 border-r border-gray-300 flex items-center whitespace-nowrap">
                    digisters.in/
                  </span>
                  <input type="text" name="slug" value={@form_data["slug"]}
                    placeholder="acme-inc"
                    class="flex-1 px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none bg-white" />
                </div>
              </div>

              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1.5">Industry</label>
                  <select name="industry"
                    class="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-white focus:outline-none focus:ring-2 focus:ring-gray-400">
                    <option value="">Select industry</option>
                    <option :for={ind <- @industries} value={ind} selected={@form_data["industry"] == ind}>{ind}</option>
                  </select>
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1.5">Country</label>
                  <select name="country"
                    class="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-white focus:outline-none focus:ring-2 focus:ring-gray-400">
                    <option value="">Select country</option>
                    <option :for={c <- @countries} value={c} selected={@form_data["country"] == c}>{c}</option>
                  </select>
                </div>
              </div>

              <div class="flex gap-3 pt-2">
                <button type="button" phx-click="close_modal"
                  class="flex-1 border border-gray-300 rounded-lg px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50">
                  Cancel
                </button>
                <button type="submit"
                  class="flex-1 bg-gray-900 hover:bg-gray-700 rounded-lg px-4 py-2.5 text-sm font-medium text-white">
                  Continue
                </button>
              </div>
            </form>
          </div>

          <%!-- Step 2 — Admin Account --%>
          <div :if={@modal_step == 2}>
            <h2 class="text-xl font-bold text-gray-900">Admin Account</h2>
            <p class="text-sm text-gray-500 mt-1 mb-6">Who will manage this company workspace?</p>
            <form phx-submit="create_company" class="space-y-5">
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1.5">First Name</label>
                  <input type="text" name="admin_first_name" placeholder="First name"
                    class="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-400" />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1.5">Last Name</label>
                  <input type="text" name="admin_last_name" placeholder="Last name"
                    class="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-400" />
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1.5">Email</label>
                <input type="email" name="admin_email" placeholder="admin@company.com"
                  class="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-400" />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1.5">
                  Phone Number
                  <span class="ml-1 text-xs text-gray-400 font-normal">(optional)</span>
                </label>
                <div class="flex items-stretch border border-gray-300 rounded-lg overflow-hidden focus-within:ring-2 focus-within:ring-gray-400">
                  <select class="px-3 py-2.5 bg-gray-50 text-sm text-gray-600 border-r border-gray-300 focus:outline-none">
                    <option>+91</option><option>+1</option><option>+44</option><option>+61</option><option>+971</option>
                  </select>
                  <input type="tel" name="admin_phone" placeholder="98765 43210"
                    class="flex-1 px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none bg-white" />
                </div>
              </div>

              <div class="flex gap-3 pt-2">
                <button type="button" phx-click="close_modal"
                  class="flex-1 border border-gray-300 rounded-lg px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50">
                  Cancel
                </button>
                <button type="submit"
                  class="flex-1 bg-gray-900 hover:bg-gray-700 rounded-lg px-4 py-2.5 text-sm font-medium text-white">
                  Create Company
                </button>
              </div>
            </form>
          </div>

        </div>
      </div>

    </div>
    """
  end
end
