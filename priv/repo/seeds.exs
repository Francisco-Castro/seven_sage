# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SevenSage.Repo.insert!(%SevenSage.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias SevenSage.Repo
alias SevenSage.Accounts.Student
alias SevenSage.Schemas.Record

params = %{
  name: "John",
  email: "john@7sage.com",
  password: "123451234512345",
  lsat_score: 167
}

%Student{}
|> Student.registration_changeset(params)
|> Repo.insert!()

%Record{
  id: Ecto.UUID.generate(),
  type: :LSAT,
  rank: 1,
  school_name: "Yale University",
  first_year_class: 2018,
  L75: 176,
  L50: 173,
  L25: 170,
  G75: 3.98,
  G50: 3.92,
  G25: 3.84
}
|> Repo.insert!()

%Record{
  id: Ecto.UUID.generate(),
  type: :LSAT,
  rank: 2,
  school_name: "Stanford University",
  first_year_class: 2018,
  L75: 174,
  L50: 171,
  L25: 169,
  G75: 3.99,
  G50: 3.93,
  G25: 3.82
}
|> Repo.insert!()

%Record{
  id: Ecto.UUID.generate(),
  type: :LSAT,
  rank: 4,
  school_name: "Harvard University",
  first_year_class: 2018,
  L75: 175,
  L50: 173,
  L25: 170,
  G75: 3.97,
  G50: 3.9,
  G25: 3.8
}
|> Repo.insert!()

%Record{
  id: Ecto.UUID.generate(),
  type: :LSAT,
  rank: 3,
  school_name: "University of Chicago",
  first_year_class: 2018,
  L75: 173,
  L50: 171,
  L25: 167,
  G75: 3.96,
  G50: 3.89,
  G25: 3.73
}
|> Repo.insert!()

%Record{
  id: Ecto.UUID.generate(),
  type: :LSAT,
  rank: 4,
  school_name: "Columbia University",
  first_year_class: 2018,
  L75: 174,
  L50: 172,
  L25: 170,
  G75: 3.84,
  G50: 3.75,
  G25: 3.63
}
|> Repo.insert!()

%Record{
  id: Ecto.UUID.generate(),
  type: :LSAT,
  rank: 7,
  school_name: "New York University",
  first_year_class: 2018,
  L75: 172,
  L50: 170,
  L25: 167,
  G75: 3.9,
  G50: 3.79,
  G25: 3.61
}
|> Repo.insert!()

%Record{
  id: Ecto.UUID.generate(),
  type: :LSAT,
  rank: 6,
  school_name: "University of Pennsylvania",
  first_year_class: 2018,
  L75: 171,
  L50: 170,
  L25: 164,
  G75: 3.95,
  G50: 3.89,
  G25: 3.49
}
|> Repo.insert!()

%Record{
  id: Ecto.UUID.generate(),
  type: :LSAT,
  rank: 12,
  school_name: "Cornell University",
  first_year_class: 2018,
  L75: 168,
  L50: 167,
  L25: 164,
  G75: 3.89,
  G50: 3.82,
  G25: 3.73
}
|> Repo.insert!()
