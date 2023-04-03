defmodule SevenSage.Repo do
  use Ecto.Repo,
    otp_app: :seven_sage,
    adapter: Ecto.Adapters.Postgres
end
