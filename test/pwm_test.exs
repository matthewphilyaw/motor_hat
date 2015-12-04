defmodule MotorHat.PwmTest do
  use ExUnit.Case
  alias MotorHat.Pwm

  setup do
    i2c_mod = Application.get_env(:motor_hat, :i2c)
    {:ok, i2c_pid} = i2c_mod.start_link "i2c-1", 0x60 
    {:ok, i2c: {i2c_mod, i2c_pid}}
  end

  test "init sends the write init sequnce via i2c", context do
    i2c = {_, i2c_pid} = context[:i2c]
    {:ok, _pwm} = Pwm.start_link i2c

    %{:messages => msgs} = GenServer.call i2c_pid, :get_state

    # message list naturally is reversed due to appending to head
    assert msgs == [
      <<0, 1>>, # last message
      <<0>>,
      <<0, 1>>,
      <<1, 4>>,
      <<253, 0>>,
      <<252, 0>>,
      <<251, 0>>,
      <<250, 0>> # first message
    ]
  end

  test "set_pwm_freq message seq is correct for 1600", context do
    i2c = {_, i2c_pid} = context[:i2c]
    {:ok, pwm} = Pwm.start_link i2c

    # clear init messages
    GenServer.call i2c_pid, :clear_messages

    Pwm.set_pwm_freq pwm, 1600
    %{:messages => msgs} = GenServer.call i2c_pid, :get_state

    assert msgs == [
      <<0, 0>>, # last message
      <<0, 1>>,
      <<254, 37>>, # prescale
      <<0, 17>>,
      <<0>> # first
    ]
  end
end
