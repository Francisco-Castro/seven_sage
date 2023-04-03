defmodule SevenSage.StudentTest do
  use SevenSage.DataCase
  alias SevenSage.Accounts.Student

  describe "lsat_changeset" do
    test "error: invalid value below the range" do
      changeset = Student.lsat_changeset(%Student{}, %{lsat_score: 119})
      refute changeset.valid?

      assert changeset.errors == [
               lsat_score:
                 {"must be greater than or equal to %{number}",
                  [validation: :number, kind: :greater_than_or_equal_to, number: 120]}
             ]
    end

    test "error: invalid value above the range" do
      changeset = Student.lsat_changeset(%Student{}, %{lsat_score: 181})
      refute changeset.valid?

      assert changeset.errors == [
               lsat_score: {
                 "must be less than or equal to %{number}",
                 [validation: :number, kind: :less_than_or_equal_to, number: 180]
               }
             ]
    end

    test "error: missing required lsat_score" do
      changeset = Student.lsat_changeset(%Student{}, %{})
      refute changeset.valid?
      assert changeset.errors == [lsat_score: {"can't be blank", [validation: :required]}]
    end
  end
end
