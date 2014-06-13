defmodule FunnelHttp do
  use Application

  # See http://elixir-lang.org/docs/stable/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
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

  def run(opts) do
    port = Keyword.get(opts, :port, 4000)
    IO.puts "Running Funnel with Cowboy on http://localhost:#{port}"
    Plug.Adapters.Cowboy.http FunnelHttp.Router, [], opts
  end
end
