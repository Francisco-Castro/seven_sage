defmodule SevenSage.Schemas.Record do
  use SevenSage.Schema

  schema "records" do
    field :type, ScoreTypeEnum
    field :rank, :integer
    field :school_name, :string
    field :first_year_class, :integer
    field :L75, :integer
    field :L50, :integer
    field :L25, :integer
    field :G75, :float
    field :G50, :float
    field :G25, :float

    timestamps()
  end

  @required_attributes ~w(
    type rank school_name first_year_class L75 L50 L25 G75 G50 G25
  )a

  @optional_attributes ~w(
  )a

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @required_attributes ++ @optional_attributes)
    |> validate_required(@required_attributes)
  end
end
