defmodule SevenSage.Repo.Migrations.AddLsatScoreToStudent do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :lsat_score, :integer
    end
  end
end
