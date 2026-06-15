defmodule DigisterWeb.Admin.ProfileLive do
  use DigisterWeb, :live_view

  alias Digister.Accounts

  on_mount {DigisterWeb.Admin.AdminAuth, :require_admin}

  def mount(_params, _session, socket) do
    user = Accounts.get_user!(socket.assigns.current_scope.user.id)
    role_label = if socket.assigns.current_role == "admin", do: "Admin", else: "User"

    member_since =
      if user.inserted_at, do: Calendar.strftime(user.inserted_at, "%d %B %Y"), else: ""

    {:ok,
     socket
     |> assign(:page_title, "Profile")
     |> assign(:active_nav, :profile)
     |> assign(:user, user)
     |> assign(:role_label, role_label)
     |> assign(:member_since, member_since)
     |> assign(:form, %{"full_name" => user.username || ""})
     |> assign(:show_avatar_modal, false)
     |> allow_upload(:avatar,
         accept: ~w(.jpg .jpeg .png .gif .webp),
         max_entries: 1,
         max_file_size: 5_000_000)}
  end

  def handle_event("validate", params, socket) do
    socket =
      if match?(["avatar" | _], params["_target"]) and socket.assigns.uploads.avatar.entries != [] do
        put_flash(socket, :info, "Photo selected — click Save changes to apply.")
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("save", %{"full_name" => name}, socket) do
    avatar_results =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        {:ok, {File.read!(path), entry.client_type}}
      end)

    attrs =
      case avatar_results do
        [{data, ct} | _] -> %{username: name, avatar: data, avatar_content_type: ct}
        [] -> %{username: name}
      end

    case Accounts.update_user_profile(socket.assigns.user, attrs) do
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

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  def handle_event("discard", _params, socket) do
    {:noreply,
     socket
     |> assign(:form, %{"full_name" => socket.assigns.user.username || ""})
     |> put_flash(:info, "Changes discarded.")}
  end

  def handle_event("show_avatar_modal", _params, socket) do
    {:noreply, assign(socket, :show_avatar_modal, true)}
  end

  def handle_event("hide_avatar_modal", _params, socket) do
    {:noreply, assign(socket, :show_avatar_modal, false)}
  end

  def render(assigns) do
    ~H"""
    <%!-- Avatar preview modal --%>
    <div
      :if={@show_avatar_modal && @user.avatar != nil}
      class="fixed inset-0 z-50"
      phx-window-keydown="hide_avatar_modal"
      phx-key="Escape">
      <div class="absolute inset-0 bg-black/70" phx-click="hide_avatar_modal"></div>
      <div class="relative z-10 h-full flex items-center justify-center px-4">
        <div class="relative">
          <button type="button" phx-click="hide_avatar_modal"
            class="absolute -top-3 -right-3 w-8 h-8 flex items-center justify-center rounded-full bg-white shadow-lg text-gray-600 hover:text-gray-900 transition-colors">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
          <img src={"data:#{@user.avatar_content_type};base64,#{Base.encode64(@user.avatar)}"}
            class="max-w-[80vw] max-h-[80vh] rounded-xl shadow-2xl object-contain bg-white" />
        </div>
      </div>
    </div>

    <div class="max-w-3xl mx-auto">
      <.form for={%{}} phx-submit="save" phx-change="validate">

        <%!-- Account Info --%>
        <div class="mb-10">
          <h2 class="text-xl font-bold text-gray-900 mb-6">Account Info</h2>

          <%!-- Avatar --%>
          <div class="mb-8 w-full flex flex-col items-center gap-3">
            <div class="relative mb-1">
              <div class="w-20 h-20 rounded-full bg-gray-200 flex items-center justify-center overflow-hidden">
                <%= cond do %>
                  <% @uploads.avatar.entries != [] -> %>
                    <%= for entry <- @uploads.avatar.entries do %>
                      <.live_img_preview entry={entry} class="w-20 h-20 object-cover" />
                    <% end %>
                  <% @user.avatar != nil -> %>
                    <img src={"data:#{@user.avatar_content_type};base64,#{Base.encode64(@user.avatar)}"}
                      phx-click="show_avatar_modal"
                      title="Click to view photo"
                      class="w-20 h-20 object-cover cursor-pointer" />
                  <% true -> %>
                    <svg class="w-20 h-20 text-gray-400" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M12 12c2.7 0 4.8-2.1 4.8-4.8S14.7 2.4 12 2.4 7.2 4.5 7.2 7.2 9.3 12 12 12zm0 2.4c-3.2 0-9.6 1.6-9.6 4.8v2.4h19.2v-2.4c0-3.2-6.4-4.8-9.6-4.8z"/>
                    </svg>
                <% end %>
              </div>
              <span class="absolute bottom-1 right-1 w-4 h-4 bg-green-500 border-2 border-white rounded-full"></span>
            </div>
            <p class="text-base font-bold text-gray-900 text-center">{@user.username || (@user.email |> String.split("@") |> List.first())}</p>
            <p class="text-sm text-gray-500 text-center">{@user.email}</p>
            <span class="inline-flex items-center gap-1.5 rounded-full border border-blue-200 bg-blue-50 px-3 py-1 text-xs font-medium text-blue-700">
              <span class="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
              {@role_label}
            </span>
            <label for={@uploads.avatar.ref}
              class="cursor-pointer flex items-center gap-1.5 text-xs font-medium text-indigo-600 hover:text-indigo-700 border border-indigo-200 hover:border-indigo-300 rounded-lg px-3 py-1.5 transition-colors bg-white">
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              Change photo
            </label>
            <.live_file_input upload={@uploads.avatar} class="hidden" />
            <%= for entry <- @uploads.avatar.entries do %>
              <%= for err <- upload_errors(@uploads.avatar, entry) do %>
                <p class="text-xs text-red-500">{error_to_string(err)}</p>
              <% end %>
            <% end %>
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
                {@current_organisation.name}
              </div>
            </div>
          </div>
          <div :if={@member_since != ""} class="mt-4 text-xs text-gray-400">
            Member since {@member_since}
          </div>
        </div>

        <div class="border-t border-gray-100 mb-10"></div>

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

  defp error_to_string(:too_large), do: "File is too large (max 5MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted (use JPG, PNG, GIF, WEBP)"
  defp error_to_string(:too_many_files), do: "Too many files"
  defp error_to_string(_), do: "Upload error"
end
