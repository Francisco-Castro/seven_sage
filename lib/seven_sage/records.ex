defmodule SevenSage.Records do
  alias SevenSage.Repo
  alias SevenSage.Schemas.Record

  def all() do
    Repo.all(Record)
  end
end
