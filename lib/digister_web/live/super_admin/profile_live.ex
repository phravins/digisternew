defmodule DigisterWeb.SuperAdmin.ProfileLive do
  use DigisterWeb, :live_view

  on_mount {DigisterWeb.SuperAdminAuth, :require_super_admin}

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    organisation =
      if user.organisation_id do
        Digister.Organisations.get_organisation!(user.organisation_id)
      else
        nil
      end

    role_label =
      cond do
        user.role == "super_admin" -> "Super admin"
        user.role == "admin" -> "Admin"
        true -> user.role || "Member"
      end

    member_since =
      if user.inserted_at do
        Calendar.strftime(user.inserted_at, "%d %B %Y")
      else
        ""
      end

    {:ok,
     socket
     |> assign(:page_title, "Profile")
     |> assign(:active_nav, :profile)
     |> assign(:user, user)
     |> assign(:organisation, organisation)
     |> assign(:role_label, role_label)
     |> assign(:member_since, member_since)
     |> assign(:form, %{"full_name" => user.username || ""})}
  end

  def handle_event("save", %{"full_name" => name}, socket) do
    case Digister.Accounts.update_user_profile(socket.assigns.user, %{username: name}) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:user, updated_user)
         |> assign(:form, %{"full_name" => updated_user.username || ""})
         |> put_flash(:info, "Profile saved successfully.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save profile.")}
    end
  end

  def handle_event("discard", _params, socket) do
    {:noreply,
     socket
     |> assign(:form, %{"full_name" => socket.assigns.user.username || ""})}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto">

      <.form for={%{}} phx-submit="save">

        <%!-- Account Info --%>
        <div class="mb-10">
          <h2 class="text-xl font-bold text-gray-900 mb-6">Account Info</h2>

          <%!-- Profile Display --%>
          <div class="mb-8 w-full flex flex-col items-center gap-2">
            <div class="relative mb-1">
              <div class="w-20 h-20 rounded-full bg-gray-200 flex items-center justify-center overflow-hidden">
                <svg class="w-20 h-20 text-gray-400" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 12c2.7 0 4.8-2.1 4.8-4.8S14.7 2.4 12 2.4 7.2 4.5 7.2 7.2 9.3 12 12 12zm0 2.4c-3.2 0-9.6 1.6-9.6 4.8v2.4h19.2v-2.4c0-3.2-6.4-4.8-9.6-4.8z"/>
                </svg>
              </div>
              <span class="absolute bottom-1 right-1 w-4 h-4 bg-green-500 border-2 border-white rounded-full"></span>
            </div>
            <p class="text-base font-bold text-gray-900 text-center">{@user.username || (@user.email |> String.split("@") |> List.first())}</p>
            <p class="text-sm text-gray-500 text-center">{@user.email}</p>
            <span class="inline-flex items-center gap-1.5 rounded-full border border-blue-200 bg-blue-50 px-3 py-1 text-xs font-medium text-blue-700">
              <span class="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
              {@role_label}
            </span>
          </div>

          <div class="grid grid-cols-2 gap-5">
            <div>
              <label class="block text-sm text-gray-600 mb-1.5">Full Name</label>
              <input type="text" name="full_name" value={@form["full_name"]}
                class="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1.5">Email Address</label>
              <div class="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-500 bg-gray-50">
                {@user.email}
              </div>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1.5">Role</label>
              <div class="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-500 bg-gray-50 flex items-center justify-between">
                <span>{@role_label}</span>
                <span class="text-xs text-gray-400">Fixed</span>
              </div>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1.5">Company</label>
              <div class="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-500 bg-gray-50">
                {if @organisation, do: @organisation.name, else: "—"}
              </div>
            </div>
          </div>
          <div :if={@member_since != ""} class="mt-4 text-xs text-gray-400">
            Member since {@member_since}
          </div>
        </div>

        <div class="border-t border-gray-100 mb-10"></div>

        <%!-- Delete Account --%>
        <div class="mb-10">
          <div class="flex items-center justify-between rounded-lg border border-red-100 bg-red-50 px-5 py-4">
            <div class="flex items-center gap-3">
              <div class="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-lg bg-red-100">
                <svg class="h-4 w-4 text-red-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              </div>
              <div>
                <p class="text-sm font-medium text-gray-800">Delete Account</p>
                <p class="text-xs text-gray-500">Permanently delete your account and all associated data.</p>
              </div>
            </div>
            <button type="button"
              class="rounded-lg border border-red-300 px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-100 transition-colors">
              Delete Account
            </button>
          </div>
        </div>

        <%!-- Action buttons --%>
        <div class="flex items-center justify-end gap-3 pb-8">
          <button type="button" phx-click="discard"
            class="px-5 py-2.5 rounded-lg border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors">
            Discard
          </button>
          <button type="submit"
            class="px-5 py-2.5 rounded-lg bg-gray-900 hover:bg-gray-700 text-sm font-medium text-white transition-colors">
            Save changes
          </button>
        </div>

      </.form>
    </div>
    """
  end
end
