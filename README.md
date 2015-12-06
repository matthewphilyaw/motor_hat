# MotorHat
[![Build Status](https://travis-ci.org/matthewphilyaw/motor_hat.svg)](https://travis-ci.org/matthewphilyaw/motor_hat)

Implementing the [motor_hat](https://github.com/adafruit/Adafruit-Motor-HAT-Python-Library) library in elixir for a project. Initial support will be for DC motors only, but will try to expand to a complete functional clone (no pun intended) of this library for elixir plus have a few ideas to extend it.

It's important to note that I said a functional clone, in so far as I am aiming to provide a similar API as closely as I can, but the internals work a bit different - Elixir is not python.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add motor_hat to your list of dependencies in `mix.exs`:

        def deps do
          [{:motor_hat, "~> 0.6.0"}]
        end

## configuration

MotorHat needs to be configured before run. `config/dev.exs and config/test.exs` are good examples of how to configure the application for your project.

Typical configuration
``` Elixir
config :motor_hat,
  boards: [ # one or more boards to configure and start
    [ 
      # key to use to look up board for calls like get_dc_motor which uses 
      # this key to find the board
      name: :mhat,
      devname: "i2c-1", # busname, i2c-1 is common on the raspberry pi
      address: 0x60, # address on i2c,
      # motor config may change in the future right now in only supports
      # dc motors not entirely happy with this.
      motor_config: {
        :dc, # dc instead of stepper
        [:m2, :m3] # motor positions to create, can be :m1 - :m4
      }
    ]
  ]
```

There is one key that is optional which is i2c: and it's used like this

```Elixir
config :motor_hat,
  i2c: MotorHat.Test.I2cFake, # <- optional do not populate normally, it defaults to I2c
  boards: [ # one or more boards to configure and start
    [ 
      # key to use to look up board for calls like get_dc_motor which uses 
      # this key to find the board
      name: :mhat,
      devname: "i2c-1", # busname, i2c-1 is common on the raspberry pi
      address: 0x60, # address on i2c
      # motor config may change in the future right now in only supports
      # dc motors not entirely happy with this.
      motor_config: {
        :dc, # dc instead of stepper
        [:m2, :m3] # motor positions to create, can be :m1 - :m4
      }
    ]
  ]
```

i2c: allows you to swap out the I2c module which normally is the Elixir_Ale module. In this case we have redefined it to MotorHat.Test.I2cFake, which is used in the tests to mock up the I2c calls.
