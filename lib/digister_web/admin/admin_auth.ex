defmodule DigisterWeb.Admin.AdminAuth do
  @moduledoc """
  LiveView `on_mount` hooks for the company-scoped admin area.

  - `:require_user` — ensures someone is logged in (used by the company-selection page).
  - `:require_admin` — ensures the logged-in user has access to the company identified by
    the `:company_slug` route param, and assigns the current organisation + role.
  """
  use DigisterWeb, :verified_routes

  import Phoenix.Component, only: [assign: 3, assign_new: 3]
  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]

  alias Digister.Accounts
  alias Digister.Accounts.Scope
  alias Digister.Organisations

  def on_mount(:require_user, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if current_user(socket) do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: ~p"/users/log-in")}
    end
  end

  def on_mount(:require_admin, %{"company_slug" => slug}, session, socket) do
    socket = mount_current_user(socket, session)
    user = current_user(socket)

    cond do
      is_nil(user) ->
        {:halt, redirect(socket, to: ~p"/users/log-in")}

      true ->
        org = Organisations.get_organisation_by_slug(slug)
        membership = org && Accounts.get_user_organisation(user.id, org.id)

        cond do
          is_nil(org) or not org.is_active ->
            {:halt,
             socket
             |> put_flash(:error, "That company is not available.")
             |> redirect(to: ~p"/select-company")}

          # Access is granted ONLY via an explicit membership. Super admins have
          # their own area and cannot access company workspaces.
          membership ->
            {:cont,
             socket
             |> assign(:current_organisation, org)
             |> assign(:current_role, membership.role)}

          true ->
            {:halt,
             socket
             |> put_flash(:error, "You don't have access to that company.")
             |> redirect(to: ~p"/select-company")}
        end
    end
  end

  defp current_user(socket) do
    socket.assigns[:current_scope] && socket.assigns.current_scope.user
  end

  defp mount_current_user(socket, session) do
    assign_new(socket, :current_scope, fn ->
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
