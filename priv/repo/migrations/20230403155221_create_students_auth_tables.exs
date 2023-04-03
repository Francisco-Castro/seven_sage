defmodule SevenSage.Repo.Migrations.CreateStudentsAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:students) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:students, [:email])

    create table(:students_tokens) do
      add :student_id, references(:students, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:students_tokens, [:student_id])
    create unique_index(:students_tokens, [:context, :token])
  end
end
