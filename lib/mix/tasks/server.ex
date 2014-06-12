defmodule Mix.Tasks.Server do
  use Mix.Task

  @shortdoc "Run Funnel in a web server"
  @recursive true

  @moduledoc """
  Runs Funnel in a web server.

  ## Command line options

    * `-p`, `--port` - the port to listen to

  """
  def run(args) do
    Mix.Task.run "app.start", args

    unless Code.ensure_loaded?(IEx) && IEx.started? do
      :timer.sleep(:infinity)
    end
  end
end
