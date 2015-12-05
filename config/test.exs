# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :motor_hat, 
  i2c: MotorHat.Test.I2cFake,
  boards: [
    [name: :mhat, devname: "i2c-1", address: 0x60, motor_config: {:dc, [:m2, :m3]}]
  ]

config :logger, :console,
  format: "$time $metadata[$level] - $message\n",
  metadata: [:module, :function]
