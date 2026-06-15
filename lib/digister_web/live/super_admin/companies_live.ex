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
     |> assign(:edit_org, nil)
     |> assign(:toggle_org, nil)
     |> assign(:delete_org, nil)
     |> assign(:form_errors, %{})
     |> assign(:industries, @industries)
     |> assign(:countries, @countries)
     |> assign(:form_data, %{"name" => "", "slug" => "", "industry" => "", "country" => ""})}
  end

  defp empty_filter_message("active"), do: "No active companies"
  defp empty_filter_message("inactive"), do: "No inactive companies"
  defp empty_filter_message(_), do: "No companies match your search"

  defp apply_filters(all_orgs, search, filter) do
    q = String.downcase(String.trim(search || ""))

    all_orgs
    |> Enum.filter(fn org ->
      case filter do
        "active" -> org.is_active
        "inactive" -> !org.is_active
        _ -> true
      end
    end)
    |> Enum.filter(fn org ->
      q == "" or
        String.contains?(String.downcase(org.name || ""), q) or
        String.contains?(String.downcase(org.industry || ""), q)
    end)
  end

  defp refresh_orgs(socket) do
    orgs = Organisations.list_organisations()

    socket
    |> assign(:all_orgs, orgs)
    |> assign(:orgs, apply_filters(orgs, socket.assigns.search, socket.assigns.filter))
  end

  def handle_event("search", %{"q" => q}, socket) do
    {:noreply,
     socket
     |> assign(:search, q)
     |> assign(:orgs, apply_filters(socket.assigns.all_orgs, q, socket.assigns.filter))}
  end

  def handle_event("filter", %{"status" => status}, socket) do
    {:noreply,
     socket
     |> assign(:filter, status)
     |> assign(:orgs, apply_filters(socket.assigns.all_orgs, socket.assigns.search, status))}
  end

  def handle_event("open_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_modal, true)
     |> assign(:form_errors, %{})
     |> assign(:form_data, %{"name" => "", "slug" => "", "industry" => "", "country" => ""})}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, socket |> assign(:show_modal, false) |> assign(:form_errors, %{})}
  end

  def handle_event("slugify_name", %{"value" => name}, socket) do
    slug =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9\s]/, "")
      |> String.replace(~r/\s+/, "-")
      |> String.replace(~r/-+/, "-")
      |> String.trim("-")

    form_data = Map.merge(socket.assigns.form_data, %{"name" => name, "slug" => slug})
    errors = Map.delete(socket.assigns.form_errors, :name)
    {:noreply, socket |> assign(:form_data, form_data) |> assign(:form_errors, errors)}
  end

  def handle_event("create_company", %{"name" => name, "slug" => slug, "industry" => industry, "country" => country}, socket) do
    errors =
      %{}
      |> then(fn e -> if String.trim(name) == "", do: Map.put(e, :name, "Company name is required."), else: e end)
      |> then(fn e -> if String.trim(slug) == "", do: Map.put(e, :slug, "Workspace link is required."), else: e end)

    if errors == %{} do
      case Organisations.create_organisation(%{name: name, slug: slug, industry: industry, country: country}) do
        {:ok, org} ->
          user = socket.assigns.current_scope.user
          actor = user.username || String.split(user.email, "@") |> List.first()
          Activities.log(%{user_name: actor, action: "created company \"#{org.name}\""})
          {:noreply,
           socket
           |> refresh_orgs()
           |> assign(:show_modal, false)
           |> put_flash(:info, "Company created successfully.")}
        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to create company. Check the link is unique.")}
      end
    else
      {:noreply, assign(socket, :form_errors, errors)}
    end
  end

  # Activate / deactivate toggle
  def handle_event("confirm_toggle", %{"id" => id}, socket) do
    {:noreply, assign(socket, :toggle_org, Organisations.get_organisation!(id))}
  end

  def handle_event("cancel_toggle", _params, socket) do
    {:noreply, assign(socket, :toggle_org, nil)}
  end

  def handle_event("do_toggle", _params, socket) do
    org = socket.assigns.toggle_org
    {:ok, updated} = Organisations.set_active(org, !org.is_active)

    user = socket.assigns.current_scope.user
    actor = user.username || String.split(user.email, "@") |> List.first()
    verb = if updated.is_active, do: "activated", else: "deactivated"
    Activities.log(%{user_name: actor, action: "#{verb} company \"#{org.name}\""})

    {:noreply,
     socket
     |> assign(:toggle_org, nil)
     |> refresh_orgs()
     |> put_flash(:info, "Company #{verb}.")}
  end

  # Edit company
  def handle_event("open_edit", %{"id" => id}, socket) do
    org = Organisations.get_organisation!(id)

    {:noreply,
     socket
     |> assign(:edit_org, org)
     |> assign(:form_errors, %{})
     |> assign(:form_data, %{
       "name" => org.name || "",
       "slug" => org.slug || "",
       "industry" => org.industry || "",
       "country" => org.country || ""
     })}
  end

  def handle_event("close_edit", _params, socket) do
    {:noreply, socket |> assign(:edit_org, nil) |> assign(:form_errors, %{})}
  end

  def handle_event("update_company", %{"name" => name, "slug" => slug, "industry" => industry, "country" => country}, socket) do
    errors =
      %{}
      |> then(fn e -> if String.trim(name) == "", do: Map.put(e, :name, "Company name is required."), else: e end)
      |> then(fn e -> if String.trim(slug) == "", do: Map.put(e, :slug, "Workspace link is required."), else: e end)

    if errors == %{} do
      case Organisations.update_organisation(socket.assigns.edit_org, %{name: name, slug: slug, industry: industry, country: country}) do
        {:ok, _org} ->
          {:noreply,
           socket
           |> assign(:edit_org, nil)
           |> refresh_orgs()
           |> put_flash(:info, "Company updated successfully.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to update company. Check the link is unique.")}
      end
    else
      {:noreply, assign(socket, :form_errors, errors)}
    end
  end

  # Delete company (permanent)
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, assign(socket, :delete_org, Organisations.get_organisation!(id))}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :delete_org, nil)}
  end

  def handle_event("do_delete", _params, socket) do
    org = socket.assigns.delete_org
    Organisations.purge_organisation(org)

    user = socket.assigns.current_scope.user
    actor = user.username || String.split(user.email, "@") |> List.first()
    Activities.log(%{user_name: actor, action: "deleted company \"#{org.name}\""})

    {:noreply,
     socket
     |> assign(:delete_org, nil)
     |> refresh_orgs()
     |> put_flash(:info, "Company deleted permanently.")}
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
          <input type="text" placeholder="Search by name or industry..."
            phx-keyup="search" phx-value-q="" name="q"
            value={@search}
            class="w-full border border-gray-200 rounded-lg pl-9 pr-4 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent bg-white" />
        </div>
        <form phx-change="filter" class="relative">
          <select name="status"
            class="border border-gray-200 rounded-lg pl-3 pr-8 py-2.5 text-sm text-gray-700 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-400 appearance-none cursor-pointer">
            <option value="all" selected={@filter == "all"}>All &nbsp;{length(@all_orgs)}</option>
            <option value="active" selected={@filter == "active"}>Active</option>
            <option value="inactive" selected={@filter == "inactive"}>Inactive</option>
          </select>
          <svg class="absolute right-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400 pointer-events-none" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
          </svg>
        </form>
        <a href="/digisters/superadmin/companies/export"
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
      <div class="bg-white rounded-xl border border-gray-200 overflow-x-auto">
        <table class="w-full text-sm min-w-[700px]">
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
                <td colspan="6" class="px-5 py-16 text-center">
                  <div class="flex flex-col items-center gap-3">
                    <svg class="w-10 h-10 text-gray-300" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                    </svg>
                    <%= if @all_orgs == [] do %>
                      <div>
                        <p class="text-sm font-medium text-gray-700">No companies found</p>
                        <p class="text-xs text-gray-400 mt-0.5">Get started by adding your first company.</p>
                      </div>
                      <button type="button" phx-click="open_modal"
                        class="mt-1 inline-flex items-center gap-1.5 rounded-lg border border-gray-300 px-3 py-1.5 text-xs font-medium text-gray-700 hover:bg-gray-50 transition-colors">
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                        </svg>
                        Add Company
                      </button>
                    <% else %>
                      <div>
                        <p class="text-sm font-medium text-gray-700">{empty_filter_message(@filter)}</p>
                      </div>
                    <% end %>
                  </div>
                </td>
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
                    <%!-- Key: activate / deactivate --%>
                    <button type="button"
                      phx-click="confirm_toggle" phx-value-id={org.id}
                      title={if org.is_active, do: "Deactivate", else: "Activate"}
                      class={[
                        "transition-colors",
                        if(org.is_active, do: "text-green-600 hover:text-green-700", else: "text-amber-500 hover:text-amber-600")
                      ]}>
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
                      </svg>
                    </button>
                    <%!-- Edit --%>
                    <button type="button"
                      phx-click="open_edit" phx-value-id={org.id}
                      title="Edit"
                      class="text-gray-400 hover:text-indigo-600 transition-colors">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                      </svg>
                    </button>
                    <%!-- Delete (permanent) --%>
                    <button type="button"
                      phx-click="confirm_delete" phx-value-id={org.id}
                      title="Delete"
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

          <div>
            <h2 class="text-xl font-bold text-gray-900">Create Company</h2>
            <p class="text-sm text-gray-500 mt-1 mb-6">Set up the company workspace details.</p>
            <form phx-submit="create_company" class="space-y-5">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1.5">
                  Company Name <span class="text-red-500">*</span>
                </label>
                <input type="text" name="name" value={@form_data["name"]}
                  placeholder="Acme Inc."
                  phx-keyup="slugify_name"
                  class={[
                    "w-full border rounded-lg px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:border-transparent",
                    if(@form_errors[:name], do: "border-red-400 focus:ring-red-300", else: "border-gray-300 focus:ring-gray-400")
                  ]} />
                <p :if={@form_errors[:name]} class="mt-1.5 text-xs text-red-500">{@form_errors[:name]}</p>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1.5">
                  Workspace Link <span class="text-red-500">*</span>
                  <span class="ml-1 text-xs text-gray-400 font-normal">Used in workspace URL</span>
                </label>
                <div class={[
                  "flex items-stretch border rounded-lg overflow-hidden focus-within:ring-2",
                  if(@form_errors[:slug], do: "border-red-400 focus-within:ring-red-300", else: "border-gray-300 focus-within:ring-gray-400")
                ]}>
                  <span class="px-3 py-2.5 bg-gray-50 text-xs text-gray-400 border-r border-gray-300 flex items-center whitespace-nowrap">
                    apps.realoffice.in/digister/
                  </span>
                  <input type="text" name="slug" value={@form_data["slug"]}
                    placeholder="acme-inc"
                    class="flex-1 px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none bg-white" />
                </div>
                <p :if={@form_errors[:slug]} class="mt-1.5 text-xs text-red-500">{@form_errors[:slug]}</p>
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
                  Create Company
                </button>
              </div>
            </form>
          </div>

        </div>
      </div>

      <%!-- Edit Company Modal --%>
      <div :if={@edit_org} class="fixed inset-0 z-50 flex items-center justify-center">
        <div class="absolute inset-0 bg-black/20" phx-click="close_edit"></div>
        <div class="relative bg-white rounded-lg shadow-lg w-full max-w-md mx-4 p-8">
          <h2 class="text-xl font-bold text-gray-900">Edit Company</h2>
          <p class="text-sm text-gray-500 mt-1 mb-6">Update the company workspace details.</p>
          <form phx-submit="update_company" class="space-y-5">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">
                Company Name <span class="text-red-500">*</span>
              </label>
              <input type="text" name="name" value={@form_data["name"]}
                placeholder="Acme Inc."
                class={[
                  "w-full border rounded-lg px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:border-transparent",
                  if(@form_errors[:name], do: "border-red-400 focus:ring-red-300", else: "border-gray-300 focus:ring-gray-400")
                ]} />
              <p :if={@form_errors[:name]} class="mt-1.5 text-xs text-red-500">{@form_errors[:name]}</p>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">
                Workspace Link <span class="text-red-500">*</span>
                <span class="ml-1 text-xs text-gray-400 font-normal">Used in workspace URL</span>
              </label>
              <div class={[
                "flex items-stretch border rounded-lg overflow-hidden focus-within:ring-2",
                if(@form_errors[:slug], do: "border-red-400 focus-within:ring-red-300", else: "border-gray-300 focus-within:ring-gray-400")
              ]}>
                <span class="px-3 py-2.5 bg-gray-50 text-xs text-gray-400 border-r border-gray-300 flex items-center whitespace-nowrap">
                  apps.realoffice.in/digister/
                </span>
                <input type="text" name="slug" value={@form_data["slug"]}
                  placeholder="acme-inc"
                  class="flex-1 px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none bg-white" />
              </div>
              <p :if={@form_errors[:slug]} class="mt-1.5 text-xs text-red-500">{@form_errors[:slug]}</p>
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
              <button type="button" phx-click="close_edit"
                class="flex-1 border border-gray-300 rounded-lg px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50">
                Cancel
              </button>
              <button type="submit"
                class="flex-1 bg-gray-900 hover:bg-gray-700 rounded-lg px-4 py-2.5 text-sm font-medium text-white">
                Save Changes
              </button>
            </div>
          </form>
        </div>
      </div>

      <%!-- Activate / Deactivate Confirm Modal --%>
      <div :if={@toggle_org} class="fixed inset-0 z-50 flex items-center justify-center">
        <div class="absolute inset-0 bg-black/20" phx-click="cancel_toggle"></div>
        <div class="relative bg-white rounded-lg shadow-lg w-full max-w-sm mx-4 p-6">
          <h3 class="text-base font-semibold text-gray-900 mb-1">
            {if @toggle_org.is_active, do: "Deactivate company?", else: "Activate company?"}
          </h3>
          <p class="text-sm text-gray-500 mb-5">
            <%= if @toggle_org.is_active do %>
              "{@toggle_org.name}" will be deactivated. Its users and admins won't be able to log in until it is reactivated.
            <% else %>
              "{@toggle_org.name}" will be reactivated. Its users and admins will be able to log in again.
            <% end %>
          </p>
          <div class="flex items-center justify-end gap-2">
            <button type="button" phx-click="cancel_toggle"
              class="px-4 py-2 rounded-lg border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              Cancel
            </button>
            <button type="button" phx-click="do_toggle"
              class={[
                "px-4 py-2 rounded-lg text-sm font-medium text-white transition-colors",
                if(@toggle_org.is_active, do: "bg-red-600 hover:bg-red-700", else: "bg-green-600 hover:bg-green-700")
              ]}>
              {if @toggle_org.is_active, do: "Deactivate", else: "Activate"}
            </button>
          </div>
        </div>
      </div>

      <%!-- Delete Confirm Modal --%>
      <div :if={@delete_org} class="fixed inset-0 z-50 flex items-center justify-center">
        <div class="absolute inset-0 bg-black/20" phx-click="cancel_delete"></div>
        <div class="relative bg-white rounded-lg shadow-lg w-full max-w-sm mx-4 p-6">
          <h3 class="text-base font-semibold text-gray-900 mb-1">Delete company?</h3>
          <p class="text-sm text-gray-500 mb-5">
            "{@delete_org.name}" will be permanently deleted along with its data. This cannot be undone.
          </p>
          <div class="flex items-center justify-end gap-2">
            <button type="button" phx-click="cancel_delete"
              class="px-4 py-2 rounded-lg border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              Cancel
            </button>
            <button type="button" phx-click="do_delete"
              class="px-4 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-sm font-medium text-white transition-colors">
              Delete
            </button>
          </div>
        </div>
      </div>

    </div>
    """
  end
end
