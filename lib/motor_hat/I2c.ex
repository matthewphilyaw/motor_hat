defmodule MotorHat.I2c do
  defmacro __using__([]) do
    module = Application.get_env(:motor_hat, :i2c)
    quote do
      alias unquote(module), as: I2c
    end
  end
end
