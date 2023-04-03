defmodule SevenSageWeb.StudentSessionController do
  use SevenSageWeb, :controller

  alias SevenSage.Accounts
  alias SevenSageWeb.StudentAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:student_return_to, ~p"/students/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"student" => student_params}, info) do
    %{"email" => email, "password" => password} = student_params

    if student = Accounts.get_student_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> StudentAuth.log_in_student(student, student_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/students/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> StudentAuth.log_out_student()
  end
end
