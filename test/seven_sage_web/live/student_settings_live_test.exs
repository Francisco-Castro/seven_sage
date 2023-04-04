defmodule SevenSageWeb.StudentSettingsLiveTest do
  use SevenSageWeb.ConnCase

  alias SevenSage.Accounts
  import Phoenix.LiveViewTest
  import SevenSage.AccountsFixtures

  @min_score_allowed Constants.min_LSAT_score_allowed()
  @max_score_allowed Constants.max_LSAT_score_allowed()

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_student(student_fixture())
        |> live(~p"/students/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if student is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/students/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/students/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update score form" do
    setup %{conn: conn} do
      password = valid_student_password()
      student = student_fixture(%{password: password})
      %{conn: log_in_student(conn, student), student: student, password: password}
    end

    test "updates the student score", %{conn: conn, student: student} do
      score = 170

      assert Accounts.get_student_by_email(student.email).lsat_score == nil

      {:ok, lv, _html} = live(conn, ~p"/students/settings")

      lv
      |> form("#score_form", %{
        "student" => %{"lsat_score" => score}
      })
      |> render_submit()

      updated_student = Accounts.get_student_by_email(student.email).lsat_score

      assert updated_student == 170
    end

    test "renders errors with invalid data (phx-change) below the allowed range", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/students/settings")

      result =
        lv
        |> element("#score_form")
        |> render_change(%{
          "action" => "update_score",
          "student" => %{"lsat_score" => 119}
        })

      assert result =~ "Change Score"
      assert result =~ "must be greater than or equal to #{@min_score_allowed}"
    end

    test "renders errors with invalid data (phx-change) above the allowed range", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/students/settings")

      result =
        lv
        |> element("#score_form")
        |> render_change(%{
          "action" => "update_score",
          "student" => %{"lsat_score" => 181}
        })

      assert result =~ "Change Score"
      assert result =~ "must be less than or equal to #{@max_score_allowed}"
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_student_password()
      student = student_fixture(%{password: password})
      %{conn: log_in_student(conn, student), student: student, password: password}
    end

    test "updates the student email", %{conn: conn, password: password, student: student} do
      new_email = unique_student_email()

      {:ok, lv, _html} = live(conn, ~p"/students/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "student" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_student_by_email(student.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/students/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "student" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, student: student} do
      {:ok, lv, _html} = live(conn, ~p"/students/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "student" => %{"email" => student.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_student_password()
      student = student_fixture(%{password: password})
      %{conn: log_in_student(conn, student), student: student, password: password}
    end

    test "updates the student password", %{conn: conn, student: student, password: password} do
      new_password = valid_student_password()

      {:ok, lv, _html} = live(conn, ~p"/students/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "student" => %{
            "email" => student.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/students/settings"

      assert get_session(new_password_conn, :student_token) != get_session(conn, :student_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_student_by_email_and_password(student.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/students/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "student" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/students/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "student" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      student = student_fixture()
      email = unique_student_email()

      token =
        extract_student_token(fn url ->
          Accounts.deliver_student_update_email_instructions(
            %{student | email: email},
            student.email,
            url
          )
        end)

      %{conn: log_in_student(conn, student), token: token, email: email, student: student}
    end

    test "updates the student email once", %{
      conn: conn,
      student: student,
      token: token,
      email: email
    } do
      {:error, redirect} = live(conn, ~p"/students/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/students/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_student_by_email(student.email)
      assert Accounts.get_student_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/students/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/students/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, student: student} do
      {:error, redirect} = live(conn, ~p"/students/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/students/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_student_by_email(student.email)
    end

    test "redirects if student is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/students/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/students/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
