defmodule SevenSage.Records do
  import Ecto.Query, warn: false
  alias SevenSage.Repo
  alias SevenSage.Schemas.Record

  def list_records() do
    Repo.all(Record)
  end

  def list_records(filter, lsat_score) do
    from(Record)
    |> filter_by_percentile(filter, lsat_score)
    |> Repo.all()
  end

  @valid_perc_values ["L25", "L50", "L75"]

  def filter_by_percentile(query, percentile, lsat_score) when percentile in @valid_perc_values do
    percentile = String.to_existing_atom(percentile)

    where(query, [record], field(record, ^percentile) <= ^lsat_score)
  end

  def filter_by_percentile(query, _percentile, _lsat_score), do: query
end
