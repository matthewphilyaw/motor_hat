defmodule MotorHat.Test.I2cFake do
  require Logger

  defmodule State do
    defstruct devname: nil, address: nil, last_message: nil
  end

  def start_link(devname, address) do
    GenServer.start_link(__MODULE__, [devname, address])
  end

  def write(pid, message) do
    GenServer.call pid, {:write, message}
  end

  def write_read(pid, message, read_count) do
    GenServer.call pid, {:write_read, message, read_count}
  end

  def init([devname, address]) do
    Logger.debug fn -> "I2c started with #{devname} at address #{address}" end

    {:ok, %State{devname: devname, address: address}}
  end

  def handle_call({:write, message}, _from, state) do
    Logger.debug fn -> "I2c write: #{inspect message}" end

    {:reply, :ok, %State{state | last_message: message}}
  end

  def handle_call({:write_read, message, read_count}, _from, state) do
    Logger.debug fn -> "I2c write_read: #{inspect message} and client expects to read #{inspect read_count}" end

    {:reply, << 0x11 >>, %State{state | last_message: message}}
  end
end
