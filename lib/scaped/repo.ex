defmodule Scaped.Repo do
  use Ecto.Repo,
    otp_app: :scaped,
    adapter: Ecto.Adapters.Postgres
end
