# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Elixir Ale is just under I2c
config :motor_hat,
  i2c: I2c,
  boards: [
    [name: :mhat, devname: "i2c-1", address: 0x60, motor_config: {:dc, [:m2, :m3]}]
  ]

