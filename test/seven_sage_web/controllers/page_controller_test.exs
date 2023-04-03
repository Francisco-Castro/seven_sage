defmodule SevenSageWeb.PageControllerTest do
  use SevenSageWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Welcome to 7Sage"
    assert html_response(conn, 200) =~ "The most advanced LSAT course available anywhere."

    assert html_response(conn, 200) =~
             "Study LSAT when you want, where you want, and how you want."

    assert html_response(conn, 200) =~ "Join 200,000 superfans and counting."
  end
end
