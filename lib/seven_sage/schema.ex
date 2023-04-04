defmodule SevenSage.Schema do
  @moduledoc """
  Common schema attributes - all schema/table IDs are UUIDs
  """

  defmacro __using__(_) do
    quote do
      alias SevenSage.Constants
      use Ecto.Schema
      import Ecto.Changeset
      import Ecto.Query

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
