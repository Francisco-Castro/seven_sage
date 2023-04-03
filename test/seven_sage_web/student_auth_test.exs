defmodule SevenSageWeb.StudentAuthTest do
  use SevenSageWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias SevenSage.Accounts
  alias SevenSageWeb.StudentAuth
  import SevenSage.AccountsFixtures

  @remember_me_cookie "_seven_sage_web_student_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, SevenSageWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{student: student_fixture(), conn: conn}
  end

  describe "log_in_student/3" do
    test "stores the student token in the session", %{conn: conn, student: student} do
      conn = StudentAuth.log_in_student(conn, student)
      assert token = get_session(conn, :student_token)
      assert get_session(conn, :live_socket_id) == "students_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Accounts.get_student_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, student: student} do
      conn = conn |> put_session(:to_be_removed, "value") |> StudentAuth.log_in_student(student)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, student: student} do
      conn =
        conn |> put_session(:student_return_to, "/hello") |> StudentAuth.log_in_student(student)

      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, student: student} do
      conn =
        conn |> fetch_cookies() |> StudentAuth.log_in_student(student, %{"remember_me" => "true"})

      assert get_session(conn, :student_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :student_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_student/1" do
    test "erases session and cookies", %{conn: conn, student: student} do
      student_token = Accounts.generate_student_session_token(student)

      conn =
        conn
        |> put_session(:student_token, student_token)
        |> put_req_cookie(@remember_me_cookie, student_token)
        |> fetch_cookies()
        |> StudentAuth.log_out_student()

      refute get_session(conn, :student_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Accounts.get_student_by_session_token(student_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "students_sessions:abcdef-token"
      SevenSageWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> StudentAuth.log_out_student()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if student is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> StudentAuth.log_out_student()
      refute get_session(conn, :student_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_student/2" do
    test "authenticates student from session", %{conn: conn, student: student} do
      student_token = Accounts.generate_student_session_token(student)

      conn =
        conn
        |> put_session(:student_token, student_token)
        |> StudentAuth.fetch_current_student([])

      assert conn.assigns.current_student.id == student.id
    end

    test "authenticates student from cookies", %{conn: conn, student: student} do
      logged_in_conn =
        conn |> fetch_cookies() |> StudentAuth.log_in_student(student, %{"remember_me" => "true"})

      student_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> StudentAuth.fetch_current_student([])

      assert conn.assigns.current_student.id == student.id
      assert get_session(conn, :student_token) == student_token

      assert get_session(conn, :live_socket_id) ==
               "students_sessions:#{Base.url_encode64(student_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, student: student} do
      _ = Accounts.generate_student_session_token(student)
      conn = StudentAuth.fetch_current_student(conn, [])
      refute get_session(conn, :student_token)
      refute conn.assigns.current_student
    end
  end

  describe "on_mount: mount_current_student" do
    test "assigns current_student based on a valid student_token ", %{
      conn: conn,
      student: student
    } do
      student_token = Accounts.generate_student_session_token(student)
      session = conn |> put_session(:student_token, student_token) |> get_session()

      {:cont, updated_socket} =
        StudentAuth.on_mount(:mount_current_student, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_student.id == student.id
    end

    test "assigns nil to current_student assign if there isn't a valid student_token ", %{
      conn: conn
    } do
      student_token = "invalid_token"
      session = conn |> put_session(:student_token, student_token) |> get_session()

      {:cont, updated_socket} =
        StudentAuth.on_mount(:mount_current_student, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_student == nil
    end

    test "assigns nil to current_student assign if there isn't a student_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        StudentAuth.on_mount(:mount_current_student, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_student == nil
    end
  end

  describe "on_mount: ensure_authenticated" do
    test "authenticates current_student based on a valid student_token ", %{
      conn: conn,
      student: student
    } do
      student_token = Accounts.generate_student_session_token(student)
      session = conn |> put_session(:student_token, student_token) |> get_session()

      {:cont, updated_socket} =
        StudentAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_student.id == student.id
    end

    test "redirects to login page if there isn't a valid student_token ", %{conn: conn} do
      student_token = "invalid_token"
      session = conn |> put_session(:student_token, student_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: SevenSageWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = StudentAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_student == nil
    end

    test "redirects to login page if there isn't a student_token ", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: SevenSageWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = StudentAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_student == nil
    end
  end

  describe "on_mount: :redirect_if_student_is_authenticated" do
    test "redirects if there is an authenticated  student ", %{conn: conn, student: student} do
      student_token = Accounts.generate_student_session_token(student)
      session = conn |> put_session(:student_token, student_token) |> get_session()

      assert {:halt, _updated_socket} =
               StudentAuth.on_mount(
                 :redirect_if_student_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "Don't redirect is there is no authenticated student", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               StudentAuth.on_mount(
                 :redirect_if_student_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_student_is_authenticated/2" do
    test "redirects if student is authenticated", %{conn: conn, student: student} do
      conn =
        conn
        |> assign(:current_student, student)
        |> StudentAuth.redirect_if_student_is_authenticated([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if student is not authenticated", %{conn: conn} do
      conn = StudentAuth.redirect_if_student_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_student/2" do
    test "redirects if student is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> StudentAuth.require_authenticated_student([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/students/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> StudentAuth.require_authenticated_student([])

      assert halted_conn.halted
      assert get_session(halted_conn, :student_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> StudentAuth.require_authenticated_student([])

      assert halted_conn.halted
      assert get_session(halted_conn, :student_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> StudentAuth.require_authenticated_student([])

      assert halted_conn.halted
      refute get_session(halted_conn, :student_return_to)
    end

    test "does not redirect if student is authenticated", %{conn: conn, student: student} do
      conn =
        conn |> assign(:current_student, student) |> StudentAuth.require_authenticated_student([])

      refute conn.halted
      refute conn.status
    end
  end
end
