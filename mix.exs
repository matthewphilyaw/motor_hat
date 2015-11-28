defmodule MotorHat.Mixfile do
  use Mix.Project

  def project do
    [app: :motor_hat,
     name: "motor hat",
     source_url: "https://github.com/matthewphilyaw/motor_hat",
     description: "elixir implementation of the motor_hat lib by adafruit for
     the board by the same name",
     version: "0.5.0",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:elixir_ale, "~> 0.4.0"}
    ]
  end
end
