defmodule MotorHat.PwmTest do
  use ExUnit.Case

  test "init sends the write init sequnce via i2c" do
    {:ok, pwm} = MotorHat.Pwm.start_link "i2c-1", 0x60

    %{:messages => msgs} = GenServer.call I2cFake, :get_state

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
