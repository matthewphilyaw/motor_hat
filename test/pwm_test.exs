defmodule MotorHat.PwmTest do
  use ExUnit.Case

  test "init sends the write init sequnce via i2c" do
    i2c_mod = Application.get_env(:motor_hat, :i2c)
    {:ok, i2c_pid} = i2c_mod.start_link "i2c-1", 0x60 
    {:ok, pwm} = MotorHat.Pwm.start_link {i2c_mod, i2c_pid}

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
end
