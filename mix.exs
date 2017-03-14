defmodule Krasukha.Mixfile do
  use Mix.Project

  @origin "https://github.com/Zatvobor/krasukha"

  def project do
    [
      app: :krasukha,
      description: "SDK for monitoring/trading/lending on Poloniex cryptocurrency exchange",
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      applications: [:logger, :crypto, :inets, :ssl, :spell],
      mod: {Krasukha, []}
    ]
  end

  defp deps do
    [
      {:spell, github: "zatvobor/spell", branch: "master"}
    ]
  end

  defp package do
    [
      maintainers: ["Aleksey Zatvobor"],
      licenses: ["MIT"],
      links: %{"GitHub" => @origin, "Contributors" => "#{@origin}/graphs/contributors", "Issues" => "#{@origin}/issues"}
    ]
  end
end
