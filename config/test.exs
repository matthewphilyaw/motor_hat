# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :motor_hat, i2c: MotorHat.Test.I2cFake

config :logger, :console,
  format: "$time $metadata[$level] - $message\n",
  level: :info,
  metadata: [:module, :function]
