# SevenSage

Before running this project you'll need to have installed

- Erlang & Elixir (see [ASDF documentation](https://github.com/asdf-vm/asdf-elixir))
- Phoenix Liveview ~0.18.16 (see [phoenix-liveview-repo](https://github.com/phoenixframework/phoenix_live_view))
- Postgresql (see [postgres-official-page](https://www.postgresql.org/download/))

After that, clone this repository, then move to the `seven_sage` folder and finally run the following commands:

- `mix deps.get`
- `mix ecto.create` 
- `mix run priv/repo/seeds.exs`
- `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

If you want to reset this project you can use the following shortcut:

  1. `mix do ecto.drop, ecto.create, ecto.migrate, run priv/repo/seeds.exs`
  2. `iex -S mix phx.server`

The seeder inserts a student and some LSAT records.

The credentials for the student are:

email:john@7sage.com
password: "123451234512345"

After loging in, you'll be redirected to the `/scores` url to find something like:

<img width="1103" alt="image" src="https://user-images.githubusercontent.com/47334502/229910269-55ada462-080f-4664-94d3-a13530777b75.png">

The purpose of this short applications is to afford a student insight into his/her eligibility for acceptance at a given set of law schools.  The sample student (John) has an LSAT score of 171. He will ask the application three questions. 

Case L75: 
John wants to find the top university or universities that will almost certainly admit him. In this case, only the University of Pennsylvania is shown. 

Case L50:
Now that John has some reassurance that he will be admitted to at least one of the top law schools, he is curious to know which of the top schools does he have a 50/50 chance of acceptance (Ll50). In this case, the list expands to four universities.

Case L25: 
Finally, John asks the application to include even those universities into which he has a below average chance of admission (L25). The app adds to the (L50) list, two additional Law Schools: Harvard and Yale. While his chances of admission to these institutions are not good, he has a slight chance of acceptance. 





