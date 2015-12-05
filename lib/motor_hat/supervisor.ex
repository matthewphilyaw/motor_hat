defmodule MotorHat.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    i2c_module = Application.get_env :motor_hat, :i2c
    boards = Application.get_env :motor_hat, :boards

    children = Enum.map boards, fn b ->
      worker(MotorHat.Board, [[i2c_module, b], [name: b[:name]]])
    end

    supervise(children, strategy: :one_for_one)
  end
end
