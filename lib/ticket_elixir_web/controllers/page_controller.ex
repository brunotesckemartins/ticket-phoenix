defmodule TicketElixirWeb.PageController do
  use TicketElixirWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
