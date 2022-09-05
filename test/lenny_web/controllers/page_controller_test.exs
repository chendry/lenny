defmodule LennyWeb.PageControllerTest do
  use LennyWeb.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Lenny"
  end
end
