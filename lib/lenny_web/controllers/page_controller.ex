defmodule LennyWeb.PageController do
  use LennyWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
