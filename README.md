# MotorHat
[![Build Status](https://travis-ci.org/matthewphilyaw/motor_hat.svg)](https://travis-ci.org/matthewphilyaw/motor_hat)

Implementing the [motor_hat](https://github.com/adafruit/Adafruit-Motor-HAT-Python-Library) library in elixir for a project. Initial support will be for DC motors only, but will try to expand to a complete functional clone (no pun intended) of this library for elixir plus have a few ideas to extend it.

It's important to note that I said a functional clone, in so far as I am aiming to provide a similar API as closely as I can, but the internals work a bit different - Elixir is not python.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add motor_hat to your list of dependencies in `mix.exs`:

        def deps do
          [{:motor_hat, "~> 0.5.0"}]
        end

## Demo

Complete demo file is [here](https://github.com/matthewphilyaw/motor_hat/blob/master/lib/motor_hat/demo.ex)

Demo assume a motor connected to m1, and m4 on the board. [Here](https://www.youtube.com/watch?v=yyMExkCFd-g) is a link to youtube of two roomba motors running this demo

### To run demo on the rapsberry pi

```shell
# Depending on your setup you may or may not need this, I run arch linux and don't run as root.
motor_hat ➤ sudo iex -S mix
Erlang/OTP 18 [erts-7.1] [source] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false]

Interactive Elixir (1.1.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> MotorHat.D
DcMotor    Demo
iex(1)> MotorHat.Demo.demo_m1_m4

22:44:36.981 [debug] m1, m4 going forward min to max

22:44:51.322 [debug] m1, m4 going forward going  max to min

22:45:05.417 [debug] m1, m4 going backward going min to max

22:45:19.755 [debug] m1, m4 going backward going from max to min

22:45:33.851 [debug] m1 forward, m4 backward going from min to max

22:45:48.190 [debug] m1 forward, m4 backward going from max to min

22:46:02.275 [debug] m1 forward min - max, m4 backward max to min seq

22:46:29.667 [debug] m1 forward min - max, m4 backward max to min concurrently

22:46:43.267 [debug] release m1, m4
:ok
iex(2)>
```

### The demo_m1_m4 function:

```Elixir
def demo_m1_m4 do
  # pwm is basically the motor_hat board at it's core
  # it is the module that does all the I2c stuff to set channels
  {:ok, mhat} = MotorHat.start_link "i2c-1", 0x60, {:dc, [:m1, :m4]}

  # each motor is a gen_server, so we keep the pids
  # and give each motor the pwm pid so it can talk ot the board
  {:ok, m1} = MotorHat.get_dc_motor mhat, :m1
  {:ok, m4} = MotorHat.get_dc_motor mhat, :m4
  motors = [m1, m4]

  # only sets the direction to run, doesn't do anything else
  run_motors motors, :forward

  # now lets slowly speed up, motors can run from 0 to 255
  # and we will sleep for 50ms between each step
  Logger.debug "m1, m4 going forward min to max"
  set_speed_range 0..255, motors, 50

  # put the brakes on
  set_speed motors, 0

  # a moment of pause for the next phase :) haha.
  # yes arguable not needed comment.
  :timer.sleep 250

  # now lets go fast and slow down!

  Logger.debug "m1, m4 going forward going  max to min"
  set_speed_range 255..0, motors, 50 
  set_speed motors, 0

  # reverse

  run_motors motors, :backward

  Logger.debug "m1, m4 going backward going min to max"
  set_speed_range 0..255, motors, 50 
  set_speed motors, 0

  :timer.sleep 250

  Logger.debug "m1, m4 going backward going from max to min"
  set_speed_range 255..0, motors, 50 
  set_speed motors, 0


  # one forward and one back!
  run_motors [m1], :forward
  run_motors [m4], :backward

  Logger.debug "m1 forward, m4 backward going from min to max"
  set_speed_range 0..255, motors, 50 
  set_speed motors, 0

  :timer.sleep 250

  Logger.debug "m1 forward, m4 backward going from max to min"
  set_speed_range 255..0, motors, 50 
  set_speed motors, 0

  # now one forward one back and one speed up to max
  # one slow down to brake

  Logger.debug "m1 forward min - max, m4 backward max to min seq"
  set_speed_range 0..255, [m1], 50
  set_speed_range 255..0, [m4], 50

  set_speed motors, 0

  :timer.sleep 250

  # Anyone care to guess why that didn't happen concurrently :)
  # Lets see if tasks can help us here... 
  # also note that the motors don't turn off till told
  # so the example above did some weird stuff keeping the max
  # motor running

  Logger.debug "m1 forward min - max, m4 backward max to min concurrently"
  m1t = Task.async fn -> set_speed_range 0..255, [m1], 50 end
  m4t = Task.async fn -> set_speed_range 255..0, [m4], 50 end

  Task.await m1t, 1 * 60 * 1000
  Task.await m4t, 1 * 60 * 1000

  set_speed motors, 0
  # that's better :)

  Logger.debug "release m1, m4"
  MotorHat.release_all_motors mhat
end
```
