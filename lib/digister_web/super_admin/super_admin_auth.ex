defmodule DigisterWeb.SuperAdminAuth do
  import Plug.Conn
  import Phoenix.Controller

  use DigisterWeb, :verified_routes

  alias Digister.Accounts
  alias Digister.Accounts.Scope

  def require_super_admin(conn, _opts) do
    user = conn.assigns[:current_scope] && conn.assigns.current_scope.user

    if user && user.is_super_admin do
      conn
    else
      conn
      |> put_flash(:error, "You must be a super admin to access this area.")
      |> redirect(to: ~p"/users/log-in")
      |> halt()
    end
  end

  def on_mount(:require_super_admin, _params, session, socket) do
    socket = mount_current_user(socket, session)
    user = socket.assigns[:current_scope] && socket.assigns.current_scope.user

    if user && user.is_super_admin do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must be a super admin to access this area.")
        |> Phoenix.LiveView.redirect(to: ~p"/users/log-in")

      {:halt, socket}
    end
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_scope, fn ->
      user =
        with token when is_binary(token) <- session["user_token"],
             {user, _inserted_at} <- Accounts.get_user_by_session_token(token) do
          user
        else
          _ -> nil
        end

      Scope.for_user(user)
    end)
  end
end
