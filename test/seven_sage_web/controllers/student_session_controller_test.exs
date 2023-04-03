defmodule SevenSageWeb.StudentSessionControllerTest do
  use SevenSageWeb.ConnCase, async: true

  import SevenSage.AccountsFixtures

  setup do
    %{student: student_fixture()}
  end

  describe "POST /students/log_in" do
    test "logs the student in", %{conn: conn, student: student} do
      conn =
        post(conn, ~p"/students/log_in", %{
          "student" => %{"email" => student.email, "password" => valid_student_password()}
        })

      assert get_session(conn, :student_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ student.email
      assert response =~ ~p"/students/settings"
      assert response =~ ~p"/students/log_out"
    end

    test "logs the student in with remember me", %{conn: conn, student: student} do
      conn =
        post(conn, ~p"/students/log_in", %{
          "student" => %{
            "email" => student.email,
            "password" => valid_student_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_seven_sage_web_student_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the student in with return to", %{conn: conn, student: student} do
      conn =
        conn
        |> init_test_session(student_return_to: "/foo/bar")
        |> post(~p"/students/log_in", %{
          "student" => %{
            "email" => student.email,
            "password" => valid_student_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, student: student} do
      conn =
        conn
        |> post(~p"/students/log_in", %{
          "_action" => "registered",
          "student" => %{
            "email" => student.email,
            "password" => valid_student_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, student: student} do
      conn =
        conn
        |> post(~p"/students/log_in", %{
          "_action" => "password_updated",
          "student" => %{
            "email" => student.email,
            "password" => valid_student_password()
          }
        })

      assert redirected_to(conn) == ~p"/students/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/students/log_in", %{
          "student" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/students/log_in"
    end
  end

  describe "DELETE /students/log_out" do
    test "logs the student out", %{conn: conn, student: student} do
      conn = conn |> log_in_student(student) |> delete(~p"/students/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :student_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the student is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/students/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :student_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
