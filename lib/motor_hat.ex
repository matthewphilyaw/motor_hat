defmodule MotorHat do
  require Logger
  alias MotorHat.Pwm
  alias MotorHat.DcMotor

  def start_pwm do
    ret = {:ok, pwm_pid} = Pwm.start_link "i2c-1", 0x60
    Pwm.set_pwm_freq pwm_pid, 1600

    ret
  end

  def start_motors(motors, pwm_pid) do
    Enum.map motors, fn m ->
      {:ok, motor_pid} = DcMotor.start_link pwm_pid, m
      motor_pid
    end 
  end

  def run_motors(motors, dir) do
    Enum.each motors, &(DcMotor.run(&1, dir))
  end

  def set_speed(motors, speed \\ 0) do
    Enum.each motors, &(DcMotor.set_speed(&1, speed))
  end

  def set_speed_range(range, motors, delay \\ 0) do
    Enum.each range, fn x ->
      Enum.each motors, &(DcMotor.set_speed(&1, x))
      :timer.sleep delay
    end 
  end

  def demo_m1_m4 do
    # pwm is basically the motor_hat board at it's core
    # it is the module that does all the I2c stuff to set channels
    {:ok, pwm_pid} = start_pwm
    
    # each motor is a gen_server, so we keep the pids
    # and give each motor the pwm pid so it can talk ot the board
    motors = start_motors [:m1, :m4], pwm_pid

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
    [m1, m4] = motors

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
    run_motors motors, :release
  end
end
