defmodule SevenSage.Repo.Migrations.AddRecordsTable do
  use Ecto.Migration

  def up do
    ScoreTypeEnum.create_type()

    create table(:records, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :score_type, null: false
      add :rank, :integer
      add :school_name, :string, size: 100
      add :first_year_class, :smallint
      add :L75, :integer
      add :L50, :integer
      add :L25, :integer
      add :G75, :float
      add :G50, :float
      add :G25, :float

      timestamps()
    end
  end

  def down do
    drop table(:records)

    ScoreTypeEnum.drop_type()
  end
end
