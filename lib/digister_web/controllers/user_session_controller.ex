defmodule DigisterWeb.UserSessionController do
  use DigisterWeb, :controller

  alias Digister.Accounts
  alias DigisterWeb.UserAuth

  # magic link login
  def create(conn, %{"user" => %{"token" => token} = user_params} = params) do
    info =
      case params do
        %{"_action" => "confirmed"} -> "User confirmed successfully."
        _ -> "Welcome back!"
      end

    case Accounts.login_user_by_magic_link(token) do
      {:ok, {user, _expired_tokens}} ->
        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> render(:new, form: Phoenix.Component.to_form(%{}, as: "user"))
    end
  end

  # email + password login
  def create(conn, %{"user" => %{"email" => email, "password" => password} = user_params}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> UserAuth.log_in_user(user, user_params)
    else
      form = Phoenix.Component.to_form(user_params, as: "user")

      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> render(:new, form: form)
    end
  end

  # magic link request
  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    conn
    |> put_flash(:info, info)
    |> redirect(to: ~p"/users/log-in")
  end

  def confirm(conn, %{"token" => token} = params) do
    remember_me = Map.get(params, "remember_me") == "true"

    with {:ok, raw} <- Base.url_decode64(token, padding: false),
         {user, _inserted_at} when not is_nil(user) <- Accounts.get_user_by_session_token(raw) do
      user_params = if remember_me, do: %{"remember_me" => "true"}, else: %{}

      conn
      |> put_flash(:info, "Welcome back!")
      |> UserAuth.log_in_user(user, user_params)
    else
      _ ->
        if user = Accounts.get_user_by_magic_link_token(token) do
          form = Phoenix.Component.to_form(%{"token" => token}, as: "user")

          conn
          |> assign(:user, user)
          |> assign(:form, form)
          |> render(:confirm)
        else
          conn
          |> put_flash(:error, "The link is invalid or it has expired.")
          |> redirect(to: ~p"/users/log-in")
        end
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
