defmodule MotorHatTest do
  use ExUnit.Case
  doctest MotorHat

  # this will change over time, this is to prove that 
  # I2cFake is being used for now
  @tag timeout: 5 * 60 * 1000
  test "Run demo" do
    MotorHat.Demo.demo_m1_m4
  end
end
