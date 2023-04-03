defmodule SevenSageWeb.StudentConfirmationInstructionsLiveTest do
  use SevenSageWeb.ConnCase

  import Phoenix.LiveViewTest
  import SevenSage.AccountsFixtures

  alias SevenSage.Accounts
  alias SevenSage.Repo

  setup do
    %{student: student_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/students/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, student: student} do
      {:ok, lv, _html} = live(conn, ~p"/students/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", student: %{email: student.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Accounts.StudentToken, student_id: student.id).context == "confirm"
    end

    test "does not send confirmation token if student is confirmed", %{conn: conn, student: student} do
      Repo.update!(Accounts.Student.confirm_changeset(student))

      {:ok, lv, _html} = live(conn, ~p"/students/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", student: %{email: student.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Accounts.StudentToken, student_id: student.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/students/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", student: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Accounts.StudentToken) == []
    end
  end
end
