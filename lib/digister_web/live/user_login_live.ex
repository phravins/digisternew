defmodule DigisterWeb.UserLoginLive do
  use DigisterWeb, :live_view

  alias Digister.Accounts
  alias Phoenix.LiveView.JS

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Sign in")}
  end

  def render(assigns) do
    ~H"""
    <div class="w-full max-w-sm mx-auto">

      <div class="mb-8">
        <h1 class="text-2xl font-bold text-gray-900 leading-tight">Work in all dimensions.</h1>
        <p class="text-lg text-gray-400 mt-1">Welcome back to Digisters.</p>
      </div>

      <.form for={%{}} phx-submit="submit_login">

        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Email</label>
          <input
            type="email"
            name="email"
            placeholder="name@company.com"
            required
            autofocus
            class="w-full rounded-lg border border-gray-300 px-4 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-sky-400 focus:border-transparent transition"
          />
        </div>

        <div class="mb-1">
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Password</label>
          <div class="relative">
            <input
              id="login_password"
              type="password"
              name="password"
              placeholder="Enter password"
              required
              class="w-full rounded-lg border border-gray-300 px-4 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-sky-400 focus:border-transparent transition pr-10"
            />
            <button type="button"
              phx-click={
                JS.toggle_attribute({"type", "password", "text"}, to: "#login_password")
                |> JS.toggle(to: "#eye_open")
                |> JS.toggle(to: "#eye_closed")
              }
              class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
              <svg id="eye_open" class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
              </svg>
              <svg id="eye_closed" class="w-4 h-4 hidden" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
              </svg>
            </button>
          </div>
        </div>

        <div class="mb-5 flex items-center gap-2">
          <input
            type="checkbox"
            name="remember_me"
            id="remember_me"
            value="true"
            class="w-4 h-4 rounded border-gray-300 text-sky-500 focus:ring-sky-400 cursor-pointer"
          />
          <label for="remember_me" class="text-sm text-gray-600 cursor-pointer select-none">
            Remember me
          </label>
        </div>

        <button type="submit" class="w-full rounded-lg digister-btn-sky py-2.5 text-sm font-medium text-white transition hover:brightness-105 active:brightness-95 mb-5">
          Continue
        </button>

      </.form>

      <p class="text-center text-xs text-gray-400 leading-relaxed">
        By signing in, you understand and agree to<br />
        our <a href="#" class="underline text-gray-500 hover:text-gray-700">Terms of Service</a>
        and <a href="#" class="underline text-gray-500 hover:text-gray-700">Privacy Policy</a>.
      </p>

    </div>
    """
  end

  def handle_event("submit_login", %{"email" => email, "password" => password} = params, socket) do
    remember_me = Map.get(params, "remember_me") == "true"

    case Accounts.get_user_by_email_and_password(String.trim(email), password) do
      nil ->
        {:noreply, put_flash(socket, :error, "Invalid email or password.")}
      user ->
        token = Accounts.generate_user_session_token(user)
        encoded = Base.url_encode64(token, padding: false)
        path = if remember_me, do: ~p"/users/log-in/#{encoded}?remember_me=true", else: ~p"/users/log-in/#{encoded}"
        {:noreply, redirect(socket, to: path)}
    end
  end

end
