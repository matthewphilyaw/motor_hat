defmodule MotorHat.Test.I2cFake do
  require Logger

  @mode1 0x00
  @mode2 0x01
  @subadr1 0x02
  @subadr2 0x03
  @subadr3 0x04
  @prescale 0xfe
  @led0_on_l 0x06
  @led0_on_h 0x07
  @led0_off_l 0x08
  @led0_off_h 0x09
  @all_led_on_l 0xfa
  @all_led_on_h 0xfb
  @all_led_off_l 0xfc
  @all_led_off_h 0xfd
  @restart 0x80
  @sleep 0x10
  @all_call 0x01
  @invrt 0x10
  @out_drv 0x04

  defmodule State do
    defstruct devname: nil, address: nil, messages: nil
  end

  def start_link(devname, address) do
    GenServer.start_link(__MODULE__, [devname, address], name: I2cFake)
  end

  def write(pid, message) do
    GenServer.call pid, {:write, message}
  end

  def write_read(pid, message, read_count) do
    GenServer.call pid, {:write_read, message, read_count}
  end

  def get_state(pid) do
    GenServer.call pid, :get_state
  end

  def stop_server(pid) do
    GenServer.call pid, :stop_server
  end

  def init([devname, address]) do
    Logger.debug fn -> "started with #{devname} at address #{address}" end

    {:ok, %State{devname: devname, address: address, messages: []}}
  end

  def handle_call({:write, message}, _from, state=%State{messages: messages}) do
    Logger.debug fn -> "#{inspect message}" end

    {:reply, :ok, %State{state | messages: [message|messages]}}
  end

  def handle_call({:write_read, message=<< @mode1 >>, read_count}, _from, state=%State{messages: messages}) do
    Logger.debug fn -> "#{inspect message} and client expects to read #{inspect read_count} byte(s)" end

    {:reply, << 0x01 >>, %State{state | messages: [message|messages]}}
  end

  def handle_call({:write_read, message, read_count}, _from, state=%State{messages: messages}) do
    Logger.debug fn -> "#{inspect message} and client expects to read #{inspect read_count} byte(s)" end

    {:reply, <<>>, %State{state | messages: [message|messages]}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, Map.from_struct(state), state}
  end

  def handle_call(:stop_server, _from, state) do
    {:stop, "client shutdown server", :ok, state}
  end

  def terminate(reason, state) do
    Logger.debug fn -> "#{inspect reason} - #{inspect state}" end
  end
end
