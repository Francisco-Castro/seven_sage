defmodule SevenSage.AccountsTest do
  use SevenSage.DataCase

  alias SevenSage.Accounts

  import SevenSage.AccountsFixtures
  alias SevenSage.Accounts.{Student, StudentToken}

  describe "get_student_by_email/1" do
    test "does not return the student if the email does not exist" do
      refute Accounts.get_student_by_email("unknown@example.com")
    end

    test "returns the student if the email exists" do
      %{id: id} = student = student_fixture()
      assert %Student{id: ^id} = Accounts.get_student_by_email(student.email)
    end
  end

  describe "get_student_by_email_and_password/2" do
    test "does not return the student if the email does not exist" do
      refute Accounts.get_student_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the student if the password is not valid" do
      student = student_fixture()
      refute Accounts.get_student_by_email_and_password(student.email, "invalid")
    end

    test "returns the student if the email and password are valid" do
      %{id: id} = student = student_fixture()

      assert %Student{id: ^id} =
               Accounts.get_student_by_email_and_password(student.email, valid_student_password())
    end
  end

  describe "get_student!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.Query.CastError, fn ->
        Accounts.get_student!("invalid_uuid")
      end
    end

    test "returns the student with the given id" do
      %{id: id} = student = student_fixture()
      assert %Student{id: ^id} = Accounts.get_student!(student.id)
    end
  end

  describe "register_student/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_student(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} =
        Accounts.register_student(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_student(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = student_fixture()
      {:error, changeset} = Accounts.register_student(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_student(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers students with a hashed password" do
      email = unique_student_email()
      {:ok, student} = Accounts.register_student(valid_student_attributes(email: email))
      assert student.email == email
      assert is_binary(student.hashed_password)
      assert is_nil(student.confirmed_at)
      assert is_nil(student.password)
    end
  end

  describe "change_student_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_student_registration(%Student{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_student_email()
      password = valid_student_password()

      changeset =
        Accounts.change_student_registration(
          %Student{},
          valid_student_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_student_email/2" do
    test "returns a student changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_student_email(%Student{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_student_email/3" do
    setup do
      %{student: student_fixture()}
    end

    test "requires email to change", %{student: student} do
      {:error, changeset} = Accounts.apply_student_email(student, valid_student_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{student: student} do
      {:error, changeset} =
        Accounts.apply_student_email(student, valid_student_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{student: student} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_student_email(student, valid_student_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{student: student} do
      %{email: email} = student_fixture()
      password = valid_student_password()

      {:error, changeset} = Accounts.apply_student_email(student, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{student: student} do
      {:error, changeset} =
        Accounts.apply_student_email(student, "invalid", %{email: unique_student_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{student: student} do
      email = unique_student_email()

      {:ok, student} =
        Accounts.apply_student_email(student, valid_student_password(), %{email: email})

      assert student.email == email
      assert Accounts.get_student!(student.id).email != email
    end
  end

  describe "deliver_student_update_email_instructions/3" do
    setup do
      %{student: student_fixture()}
    end

    test "sends token through notification", %{student: student} do
      token =
        extract_student_token(fn url ->
          Accounts.deliver_student_update_email_instructions(student, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert student_token = Repo.get_by(StudentToken, token: :crypto.hash(:sha256, token))
      assert student_token.student_id == student.id
      assert student_token.sent_to == student.email
      assert student_token.context == "change:current@example.com"
    end
  end

  describe "update_student_email/2" do
    setup do
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

      %{student: student, token: token, email: email}
    end

    test "updates the email with a valid token", %{student: student, token: token, email: email} do
      assert Accounts.update_student_email(student, token) == :ok
      changed_student = Repo.get!(Student, student.id)
      assert changed_student.email != student.email
      assert changed_student.email == email
      assert changed_student.confirmed_at
      assert changed_student.confirmed_at != student.confirmed_at
      refute Repo.get_by(StudentToken, student_id: student.id)
    end

    test "does not update email with invalid token", %{student: student} do
      assert Accounts.update_student_email(student, "oops") == :error
      assert Repo.get!(Student, student.id).email == student.email
      assert Repo.get_by(StudentToken, student_id: student.id)
    end

    test "does not update email if student email changed", %{student: student, token: token} do
      assert Accounts.update_student_email(%{student | email: "current@example.com"}, token) ==
               :error

      assert Repo.get!(Student, student.id).email == student.email
      assert Repo.get_by(StudentToken, student_id: student.id)
    end

    test "does not update email if token expired", %{student: student, token: token} do
      {1, nil} = Repo.update_all(StudentToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_student_email(student, token) == :error
      assert Repo.get!(Student, student.id).email == student.email
      assert Repo.get_by(StudentToken, student_id: student.id)
    end
  end

  describe "change_student_password/2" do
    test "returns a student changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_student_password(%Student{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_student_password(%Student{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_student_password/3" do
    setup do
      %{student: student_fixture()}
    end

    test "validates password", %{student: student} do
      {:error, changeset} =
        Accounts.update_student_password(student, valid_student_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{student: student} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_student_password(student, valid_student_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{student: student} do
      {:error, changeset} =
        Accounts.update_student_password(student, "invalid", %{password: valid_student_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{student: student} do
      {:ok, student} =
        Accounts.update_student_password(student, valid_student_password(), %{
          password: "new valid password"
        })

      assert is_nil(student.password)
      assert Accounts.get_student_by_email_and_password(student.email, "new valid password")
    end

    test "deletes all tokens for the given student", %{student: student} do
      _ = Accounts.generate_student_session_token(student)

      {:ok, _} =
        Accounts.update_student_password(student, valid_student_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(StudentToken, student_id: student.id)
    end
  end

  describe "generate_student_session_token/1" do
    setup do
      %{student: student_fixture()}
    end

    test "generates a token", %{student: student} do
      token = Accounts.generate_student_session_token(student)
      assert student_token = Repo.get_by(StudentToken, token: token)
      assert student_token.context == "session"

      # Creating the same token for another student should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%StudentToken{
          token: student_token.token,
          student_id: student_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_student_by_session_token/1" do
    setup do
      student = student_fixture()
      token = Accounts.generate_student_session_token(student)
      %{student: student, token: token}
    end

    test "returns student by token", %{student: student, token: token} do
      assert session_student = Accounts.get_student_by_session_token(token)
      assert session_student.id == student.id
    end

    test "does not return student for invalid token" do
      refute Accounts.get_student_by_session_token("oops")
    end

    test "does not return student for expired token", %{token: token} do
      {1, nil} = Repo.update_all(StudentToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_student_by_session_token(token)
    end
  end

  describe "delete_student_session_token/1" do
    test "deletes the token" do
      student = student_fixture()
      token = Accounts.generate_student_session_token(student)
      assert Accounts.delete_student_session_token(token) == :ok
      refute Accounts.get_student_by_session_token(token)
    end
  end

  describe "deliver_student_confirmation_instructions/2" do
    setup do
      %{student: student_fixture()}
    end

    test "sends token through notification", %{student: student} do
      token =
        extract_student_token(fn url ->
          Accounts.deliver_student_confirmation_instructions(student, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert student_token = Repo.get_by(StudentToken, token: :crypto.hash(:sha256, token))
      assert student_token.student_id == student.id
      assert student_token.sent_to == student.email
      assert student_token.context == "confirm"
    end
  end

  describe "confirm_student/1" do
    setup do
      student = student_fixture()

      token =
        extract_student_token(fn url ->
          Accounts.deliver_student_confirmation_instructions(student, url)
        end)

      %{student: student, token: token}
    end

    test "confirms the email with a valid token", %{student: student, token: token} do
      assert {:ok, confirmed_student} = Accounts.confirm_student(token)
      assert confirmed_student.confirmed_at
      assert confirmed_student.confirmed_at != student.confirmed_at
      assert Repo.get!(Student, student.id).confirmed_at
      refute Repo.get_by(StudentToken, student_id: student.id)
    end

    test "does not confirm with invalid token", %{student: student} do
      assert Accounts.confirm_student("oops") == :error
      refute Repo.get!(Student, student.id).confirmed_at
      assert Repo.get_by(StudentToken, student_id: student.id)
    end

    test "does not confirm email if token expired", %{student: student, token: token} do
      {1, nil} = Repo.update_all(StudentToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_student(token) == :error
      refute Repo.get!(Student, student.id).confirmed_at
      assert Repo.get_by(StudentToken, student_id: student.id)
    end
  end

  describe "deliver_student_reset_password_instructions/2" do
    setup do
      %{student: student_fixture()}
    end

    test "sends token through notification", %{student: student} do
      token =
        extract_student_token(fn url ->
          Accounts.deliver_student_reset_password_instructions(student, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert student_token = Repo.get_by(StudentToken, token: :crypto.hash(:sha256, token))
      assert student_token.student_id == student.id
      assert student_token.sent_to == student.email
      assert student_token.context == "reset_password"
    end
  end

  describe "get_student_by_reset_password_token/1" do
    setup do
      student = student_fixture()

      token =
        extract_student_token(fn url ->
          Accounts.deliver_student_reset_password_instructions(student, url)
        end)

      %{student: student, token: token}
    end

    test "returns the student with valid token", %{student: %{id: id}, token: token} do
      assert %Student{id: ^id} = Accounts.get_student_by_reset_password_token(token)
      assert Repo.get_by(StudentToken, student_id: id)
    end

    test "does not return the student with invalid token", %{student: student} do
      refute Accounts.get_student_by_reset_password_token("oops")
      assert Repo.get_by(StudentToken, student_id: student.id)
    end

    test "does not return the student if token expired", %{student: student, token: token} do
      {1, nil} = Repo.update_all(StudentToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_student_by_reset_password_token(token)
      assert Repo.get_by(StudentToken, student_id: student.id)
    end
  end

  describe "reset_student_password/2" do
    setup do
      %{student: student_fixture()}
    end

    test "validates password", %{student: student} do
      {:error, changeset} =
        Accounts.reset_student_password(student, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{student: student} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_student_password(student, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{student: student} do
      {:ok, updated_student} =
        Accounts.reset_student_password(student, %{password: "new valid password"})

      assert is_nil(updated_student.password)
      assert Accounts.get_student_by_email_and_password(student.email, "new valid password")
    end

    test "deletes all tokens for the given student", %{student: student} do
      _ = Accounts.generate_student_session_token(student)
      {:ok, _} = Accounts.reset_student_password(student, %{password: "new valid password"})
      refute Repo.get_by(StudentToken, student_id: student.id)
    end
  end

  describe "inspect/2 for the Student module" do
    test "does not include password" do
      refute inspect(%Student{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
