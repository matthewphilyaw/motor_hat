# MotorHat
[![Build Status](https://travis-ci.org/matthewphilyaw/motor_hat.svg)](https://travis-ci.org/matthewphilyaw/motor_hat)

Implementing the [motor_hat](https://github.com/adafruit/Adafruit-Motor-HAT-Python-Library) library in elixir for a project. Initial support will be for DC motors only, but will try to expand to a complete functional clone (no pun intended) of this library for elixir plus have a few ideas to extend it.

It's important to note that I said a functional clone, in so far as I am aiming to provide a similar API as closely as I can, but the internals work a bit different - Elixir is not python. 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add motor_hat to your list of dependencies in `mix.exs`:

        def deps do
          [{:motor_hat, "~> 0.0.1"}]
        end

  2. Ensure motor_hat is started before your application:

        def application do
          [applications: [:motor_hat]]
        end
