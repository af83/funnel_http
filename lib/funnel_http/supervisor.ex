defmodule FunnelHttp.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: FunnelHttpSupervisor)
  end

  def init([]) do
    children = [
      worker(FunnelHttp.Query.Registry, [])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
