defmodule MotorHat do
  use Application

  def start(_type, _args) do
    MotorHat.Supervisor.start_link    
  end
end
