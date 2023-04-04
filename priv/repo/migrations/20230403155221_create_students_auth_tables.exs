defmodule SevenSage.Repo.Migrations.CreateStudentsAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:students, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, size: 20
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:students, [:email])

    create table(:students_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :student_id, references(:students, type: :uuid, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:students_tokens, [:student_id])
    create unique_index(:students_tokens, [:context, :token])
  end
end
