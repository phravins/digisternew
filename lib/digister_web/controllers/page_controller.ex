defmodule DigisterWeb.PageController do
  use DigisterWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/users/log-in")
  end
end
