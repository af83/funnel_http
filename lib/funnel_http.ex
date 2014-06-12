defmodule FunnelHttp do
  use Application

  # See http://elixir-lang.org/docs/stable/Application.html
  # for more information on OTP Applications
  def start(_type, args) do
    IO.puts "Running Funnel with Cowboy on http://localhost:4000"
    Plug.Adapters.Cowboy.http FunnelHttp.Router, args

    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(FunnelHttp.Worker, [arg1, arg2, arg3])
    ]

    # See http://elixir-lang.org/docs/stable/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FunnelHttp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
