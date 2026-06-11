defmodule DigisterWeb.SuperAdmin.SettingsLive do
  use DigisterWeb, :live_view

  on_mount {DigisterWeb.SuperAdminAuth, :require_super_admin}

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:page_title, "Account Settings")
     |> assign(:active_nav, :settings)
     |> assign(:user, user)
     |> assign(:saved, false)
     |> assign(:form, %{
       "full_name" => user.username || "",
       "email" => user.email || "",
       "job_title" => "",
       "department" => "",
       "email_notifications" => false,
       "push_notifications" => false,
       "sms_notifications" => false,
       "default_project_view" => "",
       "task_reminders" => "",
       "google_calendar" => true,
       "slack" => false,
       "github" => false,
       "theme" => "",
       "accent_color" => ""
     })}
  end

  def handle_event("save", params, socket) do
    {:noreply,
     socket
     |> assign(:saved, true)
     |> assign(:form, Map.merge(socket.assigns.form, params))}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/super-admin")}
  end

  def handle_event("toggle", %{"field" => field}, socket) do
    current = Map.get(socket.assigns.form, field, false)
    {:noreply, assign(socket, :form, Map.put(socket.assigns.form, field, !current))}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto">

      <div :if={@saved} class="mb-6 rounded-lg bg-green-50 border border-green-200 px-4 py-3 text-sm text-green-700">
        Settings saved successfully.
      </div>

      <.form for={%{}} phx-submit="save">

        <%!-- User Profile --%>
        <div class="mb-10">
          <h2 class="text-xl font-bold text-gray-900 mb-6">User Profile</h2>
          <div class="grid grid-cols-2 gap-5">
            <div>
              <label class="block text-sm text-gray-600 mb-1.5">Full Name</label>
              <input type="text" name="full_name" value={@form["full_name"]}
                class="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1.5">Email Address</label>
              <input type="email" name="email" value={@form["email"]}
                class="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1.5">Job Title</label>
              <input type="text" name="job_title" value={@form["job_title"]}
                class="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1.5">Department</label>
              <div class="relative">
                <select name="department"
                  class="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-900 appearance-none focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent bg-white">
                  <option value=""></option>
                  <option value="engineering">Engineering</option>
                  <option value="product">Product</option>
                  <option value="design">Design</option>
                  <option value="operations">Operations</option>
                </select>
                <svg class="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                </svg>
              </div>
            </div>
          </div>
        </div>

        <div class="border-t border-gray-100 mb-10"></div>

        <%!-- Notifications --%>
        <div class="mb-10">
          <h2 class="text-xl font-bold text-gray-900 mb-6">Notifications</h2>
          <div class="space-y-5">
            <label class="flex items-start gap-3 cursor-pointer">
              <input type="checkbox" name="email_notifications" value="true"
                checked={@form["email_notifications"]}
                class="mt-0.5 w-4 h-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-400 cursor-pointer" />
              <div>
                <p class="text-sm font-medium text-gray-800">Email Notifications</p>
                <p class="text-sm text-gray-400">Receive important updates and alerts via email</p>
              </div>
            </label>
            <label class="flex items-start gap-3 cursor-pointer">
              <input type="checkbox" name="push_notifications" value="true"
                checked={@form["push_notifications"]}
                class="mt-0.5 w-4 h-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-400 cursor-pointer" />
              <div>
                <p class="text-sm font-medium text-gray-800">Push Notifications</p>
                <p class="text-sm text-gray-400">Get instant notifications on your desktop or mobile device</p>
              </div>
            </label>
            <label class="flex items-start gap-3 cursor-pointer">
              <input type="checkbox" name="sms_notifications" value="true"
                checked={@form["sms_notifications"]}
                class="mt-0.5 w-4 h-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-400 cursor-pointer" />
              <div>
                <p class="text-sm font-medium text-gray-800">SMS Notifications</p>
                <p class="text-sm text-gray-400">Receive urgent alerts via text message on your phone</p>
              </div>
            </label>
          </div>
        </div>

        <div class="border-t border-gray-100 mb-10"></div>

        <%!-- Project Preferences --%>
        <div class="mb-10">
          <h2 class="text-xl font-bold text-gray-900 mb-6">Project Preferences</h2>
          <div class="grid grid-cols-2 gap-5">
            <div>
              <label class="block text-sm text-gray-600 mb-1.5">Default Project View</label>
              <div class="relative">
                <select name="default_project_view"
                  class="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-900 appearance-none focus:outline-none focus:ring-2 focus:ring-indigo-400 bg-white">
                  <option value=""></option>
                  <option value="list">List</option>
                  <option value="board">Board</option>
                  <option value="calendar">Calendar</option>
                </select>
                <svg class="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                </svg>
              </div>
              <p class="text-xs text-gray-400 mt-1.5">Choose how you want to view your projects by default</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1.5">Task Reminders</label>
              <div class="relative">
                <select name="task_reminders"
                  class="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-900 appearance-none focus:outline-none focus:ring-2 focus:ring-indigo-400 bg-white">
                  <option value=""></option>
                  <option value="15min">15 minutes before</option>
                  <option value="1hour">1 hour before</option>
                  <option value="1day">1 day before</option>
                </select>
                <svg class="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                </svg>
              </div>
              <p class="text-xs text-gray-400 mt-1.5">Set when you'd like to receive reminders for your tasks</p>
            </div>
          </div>
        </div>

        <div class="border-t border-gray-100 mb-10"></div>

        <%!-- Integration Settings --%>
        <div class="mb-10">
          <h2 class="text-xl font-bold text-gray-900 mb-6">Integration Settings</h2>
          <div class="space-y-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-800">Google Calendar</p>
                <p class="text-sm text-gray-400">Connect your Google Calendar to sync events and reminders</p>
              </div>
              <button type="button" phx-click="toggle" phx-value-field="google_calendar"
                class={[
                  "relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 focus:outline-none",
                  if(@form["google_calendar"], do: "bg-gray-900", else: "bg-gray-200")
                ]}>
                <span class={[
                  "pointer-events-none inline-block h-5 w-5 rounded-full bg-white shadow transform transition duration-200",
                  if(@form["google_calendar"], do: "translate-x-5", else: "translate-x-0")
                ]}></span>
              </button>
            </div>
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-800">Slack</p>
                <p class="text-sm text-gray-400">Connect your Slack to sync messages and notifications</p>
              </div>
              <button type="button" phx-click="toggle" phx-value-field="slack"
                class={[
                  "relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 focus:outline-none",
                  if(@form["slack"], do: "bg-gray-900", else: "bg-gray-200")
                ]}>
                <span class={[
                  "pointer-events-none inline-block h-5 w-5 rounded-full bg-white shadow transform transition duration-200",
                  if(@form["slack"], do: "translate-x-5", else: "translate-x-0")
                ]}></span>
              </button>
            </div>
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-800">GitHub</p>
                <p class="text-sm text-gray-400">Connect your GitHub to sync repositories and issues</p>
              </div>
              <button type="button" phx-click="toggle" phx-value-field="github"
                class={[
                  "relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 focus:outline-none",
                  if(@form["github"], do: "bg-gray-900", else: "bg-gray-200")
                ]}>
                <span class={[
                  "pointer-events-none inline-block h-5 w-5 rounded-full bg-white shadow transform transition duration-200",
                  if(@form["github"], do: "translate-x-5", else: "translate-x-0")
                ]}></span>
              </button>
            </div>
          </div>
        </div>

        <div class="border-t border-gray-100 mb-10"></div>

        <%!-- Appearance --%>
        <div class="mb-10">
          <h2 class="text-xl font-bold text-gray-900 mb-6">Appearance</h2>
          <div class="grid grid-cols-2 gap-5">
            <div>
              <label class="block text-sm text-gray-600 mb-1.5">Theme</label>
              <div class="relative">
                <select name="theme"
                  class="w-full border border-gray-200 rounded-lg px-3 py-2.5 text-sm text-gray-900 appearance-none focus:outline-none focus:ring-2 focus:ring-indigo-400 bg-white">
                  <option value=""></option>
                  <option value="light">Light</option>
                  <option value="dark">Dark</option>
                  <option value="system">System</option>
                </select>
                <svg class="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                </svg>
              </div>
              <p class="text-xs text-gray-400 mt-1.5">Choose your preferred theme for a more comfortable experience</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1.5">Accent Color</label>
              <div class="relative">
                <span class="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-gray-400">#</span>
                <input type="text" name="accent_color" value={@form["accent_color"]} placeholder=""
                  class="w-full border border-gray-200 rounded-lg pl-7 pr-3 py-2.5 text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent" />
              </div>
            </div>
          </div>
        </div>

        <%!-- Action buttons --%>
        <div class="flex items-center justify-end gap-3 pb-8">
          <button type="button" phx-click="cancel"
            class="px-5 py-2.5 rounded-lg border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors">
            Cancel
          </button>
          <button type="submit"
            class="px-5 py-2.5 rounded-lg bg-gray-900 hover:bg-gray-700 text-sm font-medium text-white transition-colors">
            Save Changes
          </button>
        </div>

      </.form>
    </div>
    """
  end
end
