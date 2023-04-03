defmodule SevenSageWeb.StudentConfirmationLiveTest do
  use SevenSageWeb.ConnCase

  import Phoenix.LiveViewTest
  import SevenSage.AccountsFixtures

  alias SevenSage.Accounts
  alias SevenSage.Repo

  setup do
    %{student: student_fixture()}
  end

  describe "Confirm student" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/students/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, student: student} do
      token =
        extract_student_token(fn url ->
          Accounts.deliver_student_confirmation_instructions(student, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/students/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Student confirmed successfully"

      assert Accounts.get_student!(student.id).confirmed_at
      refute get_session(conn, :student_token)
      assert Repo.all(Accounts.StudentToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/students/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Student confirmation link is invalid or it has expired"

      # when logged in
      {:ok, lv, _html} =
        build_conn()
        |> log_in_student(student)
        |> live(~p"/students/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, student: student} do
      {:ok, lv, _html} = live(conn, ~p"/students/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Student confirmation link is invalid or it has expired"

      refute Accounts.get_student!(student.id).confirmed_at
    end
  end
end
