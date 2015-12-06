defmodule MotorHat.Pwm do
  use GenServer
  use Bitwise
  require Logger

  # constants used to manipulate the motor_hat taken from the pyhton code
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
    defstruct i2c: nil
  end

  #Public API ----

  @doc """ 
  Spawns process to represent the motor_hat on the raspberry pi
  """
  def start_link(i2c, opts \\ []) do
    GenServer.start_link(__MODULE__, [i2c], opts)
  end

  def software_reset(pid) do
    GenServer.call pid, :software_reset
  end

  def set_pwm_freq(pid, freq) do
    GenServer.call pid, {:set_pwm_freq, freq}
  end

  def set_pwm(pid, channel, on, off) do
    GenServer.call pid, {:set_pwm, channel, on, off}
  end

  def set_all_pwm(pid, on, off) do
    GenServer.call pid, {:set_all_pwm, on, off}
  end

  #Gen Server Callbacks

  @doc """
  Inialize i2c_mod bus and PCA9685 chip
  """
  def init([i2c={i2c_mod, i2c_pid}]) do
    # resetting mode1 reg without seting sleep and mode2

    set_reg_word i2c, @all_led_on_l, @all_led_on_h, 0
    set_reg_word i2c, @all_led_off_l, @all_led_off_h, 0
    i2c_mod.write i2c_pid, << @mode2, @out_drv >>
    i2c_mod.write i2c_pid, << @mode1, @all_call >>
    :timer.sleep(5) #wait for oscillator

    # wake up from sleep
    # returns binary, match out the byte
    << mode1 >> = i2c_mod.write_read i2c_pid, << @mode1 >>, 1
    mode1 = mode1 &&& ~~~@sleep #~~~@sleep creates the bit mask to flip sleep bit
    i2c_mod.write i2c_pid, << @mode1, mode1 >>
    :timer.sleep(5) #wait for oscillator

    state = %State{i2c: i2c}
    {:ok, state}
  end

  def handle_call({:set_pwm_freq, freq}, _from, state=%State{i2c: {i2c_mod, i2c_pid}}) do
    Logger.debug fn -> "setting pwm freq to: #{inspect freq}" end
    prescale_val = ((250000000 / 4096) / freq) - 1.0

    # round to whole number and take integer part
    prescale_val = trunc Float.floor(prescale_val + 0.05)

    << old_mode1 >> = i2c_mod.write_read i2c_pid, << @mode1 >>, 1
    new_mode1 = (old_mode1 &&& 0x7f) ||| 0x10 #set sleep bit, and clears reset bit if set

    # prescale has to be set after sleep is set
    i2c_mod.write i2c_pid, << @mode1, new_mode1 >>
    i2c_mod.write i2c_pid, << @prescale, prescale_val >>
    i2c_mod.write i2c_pid, << @mode1, old_mode1 >>
    :timer.sleep(5)

    i2c_mod.write i2c_pid, << @mode1, old_mode1 &&& 0x80 >> # reset

    {:reply, :ok, state}
  end

  def handle_call({:set_pwm, channel, on, off}, _from, state) do
    l_on_chan = @led0_on_l + 4 * channel
    h_on_chan = @led0_on_h + 4 * channel
    l_off_chan = @led0_off_l + 4 * channel
    h_off_chan = @led0_off_h + 4 * channel

    set_reg_word state.i2c, l_on_chan, h_on_chan, on
    set_reg_word state.i2c, l_off_chan, h_off_chan, off

    {:reply, :ok, state}
  end

  def handle_call({:set_all_pwm, on, off}, _from, state) do
    set_reg_word state.i2c, @all_led_on_l, @all_led_on_h, on
    set_reg_word state.i2c, @all_led_off_l, @all_led_off_h, off

    {:reply, :ok, state}
  end

  #private functions

  defp set_reg_word({i2c_mod, i2c_pid}, l_reg, h_reg, val) do
    i2c_mod.write i2c_pid, << l_reg, val &&& 0xff >>
    i2c_mod.write i2c_pid, << h_reg, val >>> 8 >>
  end

  def terminate(reason, state) do
    Logger.debug fn -> "#{inspect reason} - #{inspect state}" end
  end
end
