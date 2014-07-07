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
      {:funnel, "~> 0.0.1"},
      {:httpotion,   github: "myfreeweb/httpotion" },
      {:uuid,        github: "travis/erlang-uuid" },
      {:event_source_encoder, github: "chatgris/event_source_encoder"}
    ]
  end
end
