defmodule DigisterWeb.SuperAdmin.UsersLive do
  use DigisterWeb, :live_view

  alias Digister.Accounts
  alias Digister.Organisations

  on_mount {DigisterWeb.SuperAdminAuth, :require_super_admin}

  def mount(_params, _session, socket) do
    users = Accounts.list_users_with_orgs()

    {:ok,
     socket
     |> assign(:page_title, "All Users")
     |> assign(:active_nav, :users)
     |> assign(:users, users)
     |> assign(:all_users, users)
     |> assign(:orgs, Organisations.list_organisations())
     |> assign(:current_user_id, socket.assigns.current_scope.user.id)
     |> assign(:toggle_user, nil)
     |> assign(:edit_user, nil)
     |> assign(:delete_user, nil)
     |> assign(:form_errors, %{})
     |> assign(:form_data, %{})
     |> assign(:create_open, false)
     |> assign(:create_form, %{"username" => "", "email" => "", "password" => ""})
     |> assign(:show_password, false)
     |> assign(:company_dropdown_open, false)
     |> assign(:selected_companies, %{})
     |> assign(:create_errors, %{})
     |> assign(:search, "")}
  end

  defp filter_users(all_users, search) do
    q = String.downcase(String.trim(search || ""))

    Enum.filter(all_users, fn u ->
      q == "" or
        String.contains?(String.downcase(u.username || ""), q) or
        String.contains?(String.downcase(u.email || ""), q) or
        String.contains?(String.downcase(u.org_name || ""), q)
    end)
  end

  defp refresh_users(socket) do
    users = Accounts.list_users_with_orgs()

    socket
    |> assign(:all_users, users)
    |> assign(:users, filter_users(users, socket.assigns.search))
  end

  def handle_event("search", %{"q" => q}, socket) do
    {:noreply,
     socket
     |> assign(:search, q)
     |> assign(:users, filter_users(socket.assigns.all_users, q))}
  end

  # Create Account
  def handle_event("open_create", _params, socket) do
    {:noreply,
     socket
     |> assign(:create_open, true)
     |> assign(:create_form, %{"username" => "", "email" => "", "password" => ""})
     |> assign(:show_password, false)
     |> assign(:company_dropdown_open, false)
     |> assign(:selected_companies, %{})
     |> assign(:create_errors, %{})}
  end

  def handle_event("close_create", _params, socket) do
    {:noreply, socket |> assign(:create_open, false) |> assign(:create_errors, %{})}
  end

  def handle_event("toggle_password", _params, socket) do
    {:noreply, assign(socket, :show_password, !socket.assigns.show_password)}
  end

  def handle_event("toggle_company_dropdown", _params, socket) do
    {:noreply, assign(socket, :company_dropdown_open, !socket.assigns.company_dropdown_open)}
  end

  def handle_event("toggle_company", %{"id" => id}, socket) do
    selected = socket.assigns.selected_companies

    selected =
      if Map.has_key?(selected, id),
        do: Map.delete(selected, id),
        else: Map.put(selected, id, "member")

    {:noreply, assign(socket, :selected_companies, selected)}
  end

  def handle_event("set_company_role", %{"org_id" => id, "role" => role}, socket) do
    selected = socket.assigns.selected_companies

    selected =
      if Map.has_key?(selected, id), do: Map.put(selected, id, role), else: selected

    {:noreply, assign(socket, :selected_companies, selected)}
  end

  def handle_event("create_change", params, socket) do
    form = %{
      "username" => params["username"] || socket.assigns.create_form["username"],
      "email" => params["email"] || socket.assigns.create_form["email"],
      "password" => params["password"] || socket.assigns.create_form["password"]
    }

    {:noreply, assign(socket, :create_form, form)}
  end

  def handle_event("create_account", params, socket) do
    username = String.trim(params["username"] || "")
    email = String.trim(params["email"] || "")
    password = params["password"] || ""
    selected = socket.assigns.selected_companies

    errors =
      %{}
      |> then(fn e -> if username == "", do: Map.put(e, :username, "Username is required."), else: e end)
      |> then(fn e -> if email == "", do: Map.put(e, :email, "Login email is required."), else: e end)
      |> then(fn e -> if String.length(password) < 8, do: Map.put(e, :password, "Password must be at least 8 characters."), else: e end)
      |> then(fn e -> if selected == %{}, do: Map.put(e, :companies, "Select at least one company."), else: e end)

    if errors == %{} do
      memberships =
        Enum.map(selected, fn {org_id, role} -> %{organisation_id: org_id, role: role} end)

      attrs = %{username: username, email: email, password: password}

      case Accounts.create_account(attrs, memberships) do
        {:ok, _user} ->
          {:noreply,
           socket
           |> assign(:create_open, false)
           |> refresh_users()
           |> put_flash(:info, "Account created successfully.")}

        {:error, changeset} ->
          db_errors =
            Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
            |> Enum.map(fn {k, [v | _]} -> {k, v} end)
            |> Map.new()

          {:noreply, assign(socket, :create_errors, db_errors)}
      end
    else
      {:noreply, assign(socket, :create_errors, errors)}
    end
  end

  # Activate / deactivate
  def handle_event("confirm_toggle", %{"id" => id}, socket) do
    {:noreply, assign(socket, :toggle_user, Accounts.get_user!(id))}
  end

  def handle_event("cancel_toggle", _params, socket) do
    {:noreply, assign(socket, :toggle_user, nil)}
  end

  def handle_event("do_toggle", _params, socket) do
    user = socket.assigns.toggle_user
    {:ok, updated} = Accounts.set_user_active(user, !user.is_active)
    verb = if updated.is_active, do: "activated", else: "deactivated"

    {:noreply,
     socket
     |> assign(:toggle_user, nil)
     |> refresh_users()
     |> put_flash(:info, "User #{verb}.")}
  end

  # Edit
  def handle_event("open_edit", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    {:noreply,
     socket
     |> assign(:edit_user, user)
     |> assign(:form_errors, %{})
     |> assign(:form_data, %{
       "username" => user.username || "",
       "role" => user.role || "member",
       "organisation_id" => user.organisation_id || ""
     })}
  end

  def handle_event("close_edit", _params, socket) do
    {:noreply, socket |> assign(:edit_user, nil) |> assign(:form_errors, %{})}
  end

  def handle_event("update_user", %{"username" => username, "role" => role, "organisation_id" => org_id} = params, socket) do
    password = params["password"] || ""

    errors =
      %{}
      |> then(fn e -> if String.trim(username) == "", do: Map.put(e, :username, "Name is required."), else: e end)
      |> then(fn e -> if password != "" and String.length(password) < 8, do: Map.put(e, :password, "Password must be at least 8 characters."), else: e end)

    if errors == %{} do
      attrs = %{
        username: username,
        role: role,
        organisation_id: if(String.trim(org_id) == "", do: nil, else: org_id)
      }

      user = socket.assigns.edit_user

      with {:ok, _user} <- Accounts.admin_update_user(user, attrs),
           {:ok, _user} <- maybe_update_password(user, password) do
        {:noreply,
         socket
         |> assign(:edit_user, nil)
         |> refresh_users()
         |> put_flash(:info, "User updated successfully.")}
      else
        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to update user.")}
      end
    else
      {:noreply, assign(socket, :form_errors, errors)}
    end
  end

  # Soft delete
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, assign(socket, :delete_user, Accounts.get_user!(id))}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :delete_user, nil)}
  end

  def handle_event("do_delete", _params, socket) do
    Accounts.soft_delete_user(socket.assigns.delete_user)

    {:noreply,
     socket
     |> assign(:delete_user, nil)
     |> refresh_users()
     |> put_flash(:info, "User removed.")}
  end

  defp maybe_update_password(_user, ""), do: {:ok, :unchanged}
  defp maybe_update_password(user, password), do: Accounts.admin_update_user_password(user, password)

  defp company_select_label(selected) when map_size(selected) == 0, do: "Select companies..."
  defp company_select_label(selected) when map_size(selected) == 1, do: "1 company selected"
  defp company_select_label(selected), do: "#{map_size(selected)} companies selected"

  defp role_label(%{role: "super_admin"}), do: "Super Admin"
  defp role_label(%{role: "admin"}), do: "Admin"
  defp role_label(_), do: "User"

  defp role_color(%{role: "super_admin"}), do: "text-indigo-600 font-semibold"
  defp role_color(%{role: "admin"}), do: "text-green-600 font-medium"
  defp role_color(_), do: "text-gray-500"

  defp avatar_colors(%{role: "super_admin"}), do: "bg-indigo-100 text-indigo-600"
  defp avatar_colors(%{role: "admin"}), do: "bg-green-100 text-green-600"
  defp avatar_colors(_), do: "bg-gray-100 text-gray-600"

  defp initials(user) do
    name = user.username || user.email || "?"
    name
    |> String.split()
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp fmt_dt(%NaiveDateTime{} = dt) do
    ist = NaiveDateTime.add(dt, 19800, :second)
    Calendar.strftime(ist, "%d %b %Y · %I:%M %p")
  end
  defp fmt_dt(_), do: "Never"

  def render(assigns) do
    ~H"""
    <div>
      <%!-- Header --%>
      <div class="flex items-start justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">All Users</h1>
          <p class="text-sm text-gray-400 mt-0.5">Cross-platform user directory</p>
        </div>
      </div>

      <%!-- Toolbar --%>
      <div class="flex items-center gap-3 mb-5">
        <div class="relative flex-1">
          <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input type="text" placeholder="Search users by name, email, or org..."
            phx-keyup="search" name="q" value={@search}
            class="w-full border border-gray-200 rounded-lg pl-9 pr-4 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent bg-white" />
        </div>
        <button type="button" phx-click="open_create"
          class="flex items-center gap-1.5 rounded-lg bg-gray-900 hover:bg-gray-700 px-4 py-2.5 text-sm font-medium text-white transition-colors">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
          </svg>
          Create Account
        </button>
        <a href="/digisters/superadmin/users/export"
          class="flex items-center gap-1.5 border border-gray-200 rounded-lg px-4 py-2.5 text-sm font-medium text-gray-600 bg-white hover:bg-gray-50 transition-colors">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
          </svg>
          Export
        </a>
      </div>

      <%!-- Table --%>
      <div class="bg-white rounded-xl border border-gray-200 overflow-x-auto">
        <table class="w-full text-sm min-w-[800px]">
          <thead>
            <tr class="border-b border-gray-100">
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider w-12">S.No</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">User</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Company</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Role</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Status</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Last Active</th>
              <th class="text-right px-5 py-3.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= if @users == [] do %>
              <tr>
                <td colspan="7" class="px-5 py-16 text-center">
                  <div class="flex flex-col items-center gap-3">
                    <svg class="w-10 h-10 text-gray-300" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    <div>
                      <p class="text-sm font-medium text-gray-700">No users found</p>
                      <p class="text-xs text-gray-400 mt-0.5">Get started by adding your first user.</p>
                    </div>
                    <button type="button"
                      class="mt-1 inline-flex items-center gap-1.5 rounded-lg border border-gray-300 px-3 py-1.5 text-xs font-medium text-gray-700 hover:bg-gray-50 transition-colors">
                      <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                      </svg>
                      Add User
                    </button>
                  </div>
                </td>
              </tr>
            <% else %>
              <tr :for={{user, idx} <- Enum.with_index(@users, 1)} class="hover:bg-gray-50 transition-colors">
                <td class="px-5 py-4 text-sm text-gray-400">{idx}</td>
                <td class="px-5 py-4">
                  <div class="flex items-center gap-3">
                    <div class="w-9 h-9 rounded-full flex-shrink-0 overflow-hidden">
                      <%= if user.avatar do %>
                        <img src={"data:#{user.avatar_content_type};base64,#{Base.encode64(user.avatar)}"}
                          class="w-9 h-9 object-cover" />
                      <% else %>
                        <div class={["w-9 h-9 rounded-full flex items-center justify-center text-xs font-semibold", avatar_colors(user)]}>
                          {initials(user)}
                        </div>
                      <% end %>
                    </div>
                    <div>
                      <p class="font-medium text-gray-900 text-sm">{user.username || "—"}</p>
                      <p class="text-xs text-gray-400 mt-0.5">{user.email}</p>
                    </div>
                  </div>
                </td>
                <td class="px-5 py-4 text-sm text-gray-700">
                  {user.org_name || if(user.role == "super_admin", do: "Realoffice", else: "—")}
                </td>
                <td class="px-5 py-4">
                  <span class={["text-sm", role_color(user)]}>{role_label(user)}</span>
                </td>
                <td class="px-5 py-4">
                  <span class={[
                    "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium",
                    if(user.is_active,
                      do: "border-green-300 bg-green-50 text-green-700",
                      else: "border-gray-300 bg-gray-50 text-gray-500")
                  ]}>
                    {if user.is_active, do: "Active", else: "Inactive"}
                  </span>
                </td>
                <td class="px-5 py-4 text-sm text-gray-600">{fmt_dt(user.signed_on)}</td>
                <td class="px-5 py-4">
                  <div class="flex items-center justify-end gap-3">
                    <%!-- Key: activate / deactivate (not on own account) --%>
                    <button :if={user.id != @current_user_id} type="button"
                      phx-click="confirm_toggle" phx-value-id={user.id}
                      title={if user.is_active, do: "Deactivate", else: "Activate"}
                      class={[
                        "transition-colors",
                        if(user.is_active, do: "text-green-600 hover:text-green-700", else: "text-amber-500 hover:text-amber-600")
                      ]}>
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
                      </svg>
                    </button>
                    <%!-- Edit --%>
                    <button type="button"
                      phx-click="open_edit" phx-value-id={user.id}
                      title="Edit"
                      class="text-gray-400 hover:text-indigo-600 transition-colors">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                      </svg>
                    </button>
                    <%!-- Soft delete (not on own account) --%>
                    <button :if={user.id != @current_user_id} type="button"
                      phx-click="confirm_delete" phx-value-id={user.id}
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

      <%!-- Create Account Modal --%>
      <div :if={@create_open} class="fixed inset-0 z-50 flex items-center justify-center">
        <div class="absolute inset-0 bg-black/20" phx-click="close_create"></div>
        <div class="relative bg-white rounded-lg shadow-lg w-full max-w-md mx-4 max-h-[85vh] flex flex-col">
          <div class="flex items-start justify-between px-6 pt-6">
            <div>
              <h2 class="text-lg font-bold text-gray-900">Create Account</h2>
              <p class="text-sm text-gray-500 mt-0.5">New user or admin for a company</p>
            </div>
            <button type="button" phx-click="close_create" class="text-gray-400 hover:text-gray-600">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <form phx-submit="create_account" phx-change="create_change" class="px-6 pb-6 pt-4 overflow-y-auto space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Username</label>
              <input type="text" name="username" value={@create_form["username"]}
                placeholder="e.g. john_doe"
                class={[
                  "w-full border rounded-lg px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:border-transparent",
                  if(@create_errors[:username], do: "border-red-400 focus:ring-red-300", else: "border-gray-300 focus:ring-gray-400")
                ]} />
              <p :if={@create_errors[:username]} class="mt-1.5 text-xs text-red-500">{@create_errors[:username]}</p>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Login Email</label>
              <input type="text" name="email" value={@create_form["email"]}
                placeholder="user@company.in"
                class={[
                  "w-full border rounded-lg px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:border-transparent",
                  if(@create_errors[:email], do: "border-red-400 focus:ring-red-300", else: "border-gray-300 focus:ring-gray-400")
                ]} />
              <p :if={@create_errors[:email]} class="mt-1.5 text-xs text-red-500">{@create_errors[:email]}</p>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Password</label>
              <div class="relative">
                <input type={if @show_password, do: "text", else: "password"} name="password" value={@create_form["password"]}
                  placeholder="Min 8 characters"
                  class={[
                    "w-full border rounded-lg px-3 py-2.5 pr-10 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:border-transparent",
                    if(@create_errors[:password], do: "border-red-400 focus:ring-red-300", else: "border-gray-300 focus:ring-gray-400")
                  ]} />
                <button type="button" phx-click="toggle_password"
                  class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                </button>
              </div>
              <p :if={@create_errors[:password]} class="mt-1.5 text-xs text-red-500">{@create_errors[:password]}</p>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Company Access &amp; Roles</label>
              <button type="button" phx-click="toggle_company_dropdown"
                class={[
                  "w-full flex items-center justify-between border rounded-lg px-3 py-2.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-gray-400",
                  if(@create_errors[:companies], do: "border-red-400", else: "border-gray-300")
                ]}>
                <span class={if @selected_companies == %{}, do: "text-gray-400", else: "text-gray-900"}>
                  {company_select_label(@selected_companies)}
                </span>
                <svg class={["w-4 h-4 text-gray-400 transition-transform", if(@company_dropdown_open, do: "rotate-180", else: "")]} fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                </svg>
              </button>
              <p :if={@create_errors[:companies]} class="mt-1.5 text-xs text-red-500">{@create_errors[:companies]}</p>

              <div :if={@company_dropdown_open} class="mt-1.5 border border-gray-200 rounded-lg divide-y divide-gray-100 max-h-52 overflow-y-auto">
                <div :for={org <- @orgs} class={[
                  "flex items-center gap-3 px-3 py-2.5",
                  if(Map.has_key?(@selected_companies, org.id), do: "bg-gray-50", else: "")
                ]}>
                  <button type="button" phx-click="toggle_company" phx-value-id={org.id}
                    class="flex items-center gap-3 flex-1 min-w-0 text-left">
                    <span class={[
                      "w-4 h-4 rounded border flex items-center justify-center flex-shrink-0",
                      if(Map.has_key?(@selected_companies, org.id), do: "bg-indigo-600 border-indigo-600", else: "border-gray-300 bg-white")
                    ]}>
                      <svg :if={Map.has_key?(@selected_companies, org.id)} class="w-3 h-3 text-white" fill="none" stroke="currentColor" stroke-width="3" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                      </svg>
                    </span>
                    <span class="text-sm text-gray-800 truncate">{org.name}</span>
                  </button>
                  <div :if={Map.has_key?(@selected_companies, org.id)} class="flex items-center gap-1.5 flex-shrink-0">
                    <span class="text-xs text-gray-400">Role:</span>
                    <div class="flex rounded-md border border-gray-200 overflow-hidden">
                      <button type="button" phx-click="set_company_role" phx-value-org_id={org.id} phx-value-role="admin"
                        class={[
                          "px-2 py-1 text-xs font-medium transition-colors",
                          if(@selected_companies[org.id] == "admin", do: "bg-indigo-600 text-white", else: "bg-white text-gray-500 hover:bg-gray-50")
                        ]}>
                        Admin
                      </button>
                      <button type="button" phx-click="set_company_role" phx-value-org_id={org.id} phx-value-role="member"
                        class={[
                          "px-2 py-1 text-xs font-medium transition-colors border-l border-gray-200",
                          if(@selected_companies[org.id] == "member", do: "bg-indigo-600 text-white", else: "bg-white text-gray-500 hover:bg-gray-50")
                        ]}>
                        User
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="flex gap-3 pt-2">
              <button type="button" phx-click="close_create"
                class="flex-1 border border-gray-300 rounded-lg px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50">
                Cancel
              </button>
              <button type="submit"
                class="flex-1 bg-gray-900 hover:bg-gray-700 rounded-lg px-4 py-2.5 text-sm font-medium text-white">
                Create
              </button>
            </div>
          </form>
        </div>
      </div>

      <%!-- Edit User Modal --%>
      <div :if={@edit_user} class="fixed inset-0 z-50 flex items-center justify-center">
        <div class="absolute inset-0 bg-black/20" phx-click="close_edit"></div>
        <div class="relative bg-white rounded-lg shadow-lg w-full max-w-md mx-4 p-8">
          <h2 class="text-xl font-bold text-gray-900">Edit User</h2>
          <p class="text-sm text-gray-500 mt-1 mb-6">Update the user's details.</p>
          <form phx-submit="update_user" class="space-y-5">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">
                Full Name <span class="text-red-500">*</span>
              </label>
              <input type="text" name="username" value={@form_data["username"]}
                placeholder="Jane Doe"
                class={[
                  "w-full border rounded-lg px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:border-transparent",
                  if(@form_errors[:username], do: "border-red-400 focus:ring-red-300", else: "border-gray-300 focus:ring-gray-400")
                ]} />
              <p :if={@form_errors[:username]} class="mt-1.5 text-xs text-red-500">{@form_errors[:username]}</p>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1.5">Company</label>
                <%= if @edit_user.role == "super_admin" do %>
                  <input type="hidden" name="organisation_id" value={@form_data["organisation_id"]} />
                  <div class="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-500 bg-gray-100 cursor-not-allowed">
                    Realoffice
                  </div>
                <% else %>
                  <select name="organisation_id"
                    class="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-white focus:outline-none focus:ring-2 focus:ring-gray-400">
                    <option value="">No company</option>
                    <option :for={org <- @orgs} value={org.id} selected={@form_data["organisation_id"] == org.id}>{org.name}</option>
                  </select>
                <% end %>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1.5">Role</label>
                <%= if @edit_user.role == "super_admin" do %>
                  <input type="hidden" name="role" value="super_admin" />
                  <div class="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-500 bg-gray-100 cursor-not-allowed">
                    Super Admin
                  </div>
                <% else %>
                  <select name="role"
                    class="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm text-gray-700 bg-white focus:outline-none focus:ring-2 focus:ring-gray-400">
                    <option value="admin" selected={@form_data["role"] == "admin"}>Admin</option>
                    <option value="member" selected={@form_data["role"] == "member"}>User</option>
                  </select>
                <% end %>
              </div>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">New Password</label>
              <input type="password" name="password"
                placeholder="Leave blank to keep current"
                class={[
                  "w-full border rounded-lg px-3 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:border-transparent",
                  if(@form_errors[:password], do: "border-red-400 focus:ring-red-300", else: "border-gray-300 focus:ring-gray-400")
                ]} />
              <p :if={@form_errors[:password]} class="mt-1.5 text-xs text-red-500">{@form_errors[:password]}</p>
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
      <div :if={@toggle_user} class="fixed inset-0 z-50 flex items-center justify-center">
        <div class="absolute inset-0 bg-black/20" phx-click="cancel_toggle"></div>
        <div class="relative bg-white rounded-lg shadow-lg w-full max-w-sm mx-4 p-6">
          <h3 class="text-base font-semibold text-gray-900 mb-1">
            {if @toggle_user.is_active, do: "Deactivate user?", else: "Activate user?"}
          </h3>
          <p class="text-sm text-gray-500 mb-5">
            <%= if @toggle_user.is_active do %>
              "{@toggle_user.username || @toggle_user.email}" will be deactivated and won't be able to log in until reactivated. Other accounts are unaffected.
            <% else %>
              "{@toggle_user.username || @toggle_user.email}" will be reactivated and able to log in again.
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
                if(@toggle_user.is_active, do: "bg-red-600 hover:bg-red-700", else: "bg-green-600 hover:bg-green-700")
              ]}>
              {if @toggle_user.is_active, do: "Deactivate", else: "Activate"}
            </button>
          </div>
        </div>
      </div>

      <%!-- Delete (soft) Confirm Modal --%>
      <div :if={@delete_user} class="fixed inset-0 z-50 flex items-center justify-center">
        <div class="absolute inset-0 bg-black/20" phx-click="cancel_delete"></div>
        <div class="relative bg-white rounded-lg shadow-lg w-full max-w-sm mx-4 p-6">
          <h3 class="text-base font-semibold text-gray-900 mb-1">Remove user?</h3>
          <p class="text-sm text-gray-500 mb-5">
            "{@delete_user.username || @delete_user.email}" will be removed from the directory. The record is kept and can be restored later.
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
