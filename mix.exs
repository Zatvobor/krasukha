defmodule Krasukha.Mixfile do
  use Mix.Project

  def project do
    [
      app: :krasukha,
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      package: package,
      deps: deps()
    ]
  end

  def application do
    [
      applications: [:logger, :spell],
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
      maintainers: ["Aleksey Zatvobor"], licenses: ["MIT"], links: %{"GitHub" => github, "Contributors" => contributors, "Issues" => issues}
    ]
  end

  defp github, do: "https://github.com/Zatvobor/krasukha"
  defp contributors, do: "https://github.com/Zatvobor/krasukha/graphs/contributors"
  defp issues, do: "https://github.com/Zatvobor/krasukha/issues"
end
