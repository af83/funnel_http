defmodule FunnelHttp.Mixfile do
  use Mix.Project

  def project do
    [app: :funnel_http,
     version: "0.0.1",
     elixir: "~> 0.14",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:cowboy, :plug, :funnel],
     mod: {FunnelHttp, []}]
  end

  defp deps do
    [
      {:cowboy, github: "extend/cowboy"},
      {:plug, "~> 0.5"},
      {:timex,  github: "bitwalker/timex"},
      {:funnel, github: "AF83/funnel"}
    ]
  end
end
