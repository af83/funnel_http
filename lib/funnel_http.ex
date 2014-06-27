defmodule FunnelHttp do
  use Application

  # See http://elixir-lang.org/docs/stable/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    FunnelHttp.Supervisor.start_link
  end

  def run(opts) do
    port = Keyword.get(opts, :port, 4000)
    IO.puts "Running Funnel with Cowboy on http://localhost:#{port}"
    Plug.Adapters.Cowboy.http FunnelHttp.Router, [], opts
  end
end
