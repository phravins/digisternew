defmodule DigisterWeb.Admin.SelectCompanyLive do
  use DigisterWeb, :live_view

  alias Digister.Accounts

  on_mount {DigisterWeb.Admin.AdminAuth, :require_user}

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    companies = Accounts.list_user_organisations(user.id)

    {:ok,
     socket
     |> assign(:page_title, "Select a company")
     |> assign(:user, user)
     |> assign(:companies, companies)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 flex items-center justify-center px-4 py-12">
      <div class="w-full max-w-sm bg-white rounded-2xl border border-gray-200 shadow-sm p-6">
        <%!-- Brand + heading --%>
        <div class="flex flex-col items-center text-center mb-6">
          <div class="w-11 h-11 rounded-xl digister-logo-bg flex items-center justify-center mb-3">
            <svg width="22" height="22" viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect x="4" y="4" width="8" height="8" rx="1.5" fill="white" fill-opacity="0.9"/>
              <rect x="16" y="4" width="8" height="8" rx="1.5" fill="white" fill-opacity="0.7"/>
              <rect x="4" y="16" width="8" height="8" rx="1.5" fill="white" fill-opacity="0.7"/>
              <rect x="16" y="16" width="8" height="8" rx="1.5" fill="white" fill-opacity="0.5"/>
            </svg>
          </div>
          <h1 class="text-lg font-bold text-gray-900">Select a company</h1>
          <p class="text-sm text-gray-500 mt-0.5">
            Welcome back, {@user.username || (@user.email |> String.split("@") |> List.first())}
          </p>
        </div>

        <%= if @companies == [] do %>
          <div class="text-center py-8">
            <p class="text-sm font-medium text-gray-700">No companies assigned</p>
            <p class="text-xs text-gray-400 mt-1">Ask your administrator to grant you access.</p>
          </div>
        <% else %>
          <div class="space-y-2">
            <a :for={c <- @companies} href={~p"/digisters/#{c.organisation.slug}/admin"}
              class="flex items-center justify-between gap-3 rounded-xl border border-gray-200 px-3.5 py-3 hover:border-indigo-300 hover:bg-indigo-50/40 transition-colors group">
              <div class="flex items-center gap-3 min-w-0">
                <div class="w-10 h-10 rounded-lg bg-indigo-600 text-white flex items-center justify-center font-bold flex-shrink-0">
                  {c.organisation.name |> to_string() |> String.first() |> to_string() |> String.upcase()}
                </div>
                <div class="min-w-0">
                  <p class="font-semibold text-gray-900 text-sm truncate">{c.organisation.name}</p>
                  <p class="text-xs text-gray-400">{if c.role == "admin", do: "Admin", else: "User"}</p>
                </div>
              </div>
              <svg class="w-4 h-4 text-gray-300 group-hover:text-indigo-500 transition-colors flex-shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
              </svg>
            </a>
          </div>
        <% end %>

        <div class="border-t border-gray-100 mt-6 pt-4 text-center">
          <form action={~p"/users/log-out"} method="post">
            <input type="hidden" name="_method" value="delete" />
            <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
            <button type="submit" class="text-xs font-medium text-gray-400 hover:text-gray-600 transition-colors">Sign out</button>
          </form>
        </div>
      </div>
    </div>
    """
  end
end
