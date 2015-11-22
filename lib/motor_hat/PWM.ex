defmodule MotorHat.PWM do
  use GenServer
  use Bitwise

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
    defstruct i2c_pid: nil
  end

  #Public API ----

  @doc """ 
  Spawns process to represent the motor_hat on the raspberry pi
  """
  def start_link(devname, address, opts \\ []) do
    GenServer.start_link(__MODULE__, [devname, address], opts)
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
  Inialize I2c bus and PCA9685 chip
  """
  def init([devname, address]) do
    {:ok, pid} = I2c.start_link(devname, address)

    # resetting mode1 reg without seting sleep and mode2
    set_all_pwm(pid, 0, 0)
    I2c.write pid, << @mode2, @out_drv >>
    I2c.write pid, << @mode1, @all_call >>
    :timmer.sleep(5) #wait for oscillator

    # wakeu up from sleep
    mode1 = I2c.write_read pid, << @mode1 >>, 1
    mode1 = mode1 &&& ~~~@sleep #~~~@sleep creates the bit mask to flip sleep bit
    I2c.write pid, @mode1, mode1
    :timmer.sleep(5) #wait for oscillator

    state = %State{i2c_pid: pid}
    {:ok, state}
  end

  def handle_call({:set_pwm_freq, freq}, _from, state) do
    prescale_val = ((250000000 / 4096) / freq) - 1.0

    prescale_val = Float.floor(prescale_val + 0.05) # round to whole number 

    old_mode1 = I2c.write_read state.i2c_pid, << @mode1 >>, 1
    new_mode1 = (old_mode1 &&& 0x7f) ||| 0x10 #set sleep bit, and clears reset bit if set

    # prescale has to be set after sleep is set
    I2c.write state.i2c_pid, << @mode1, new_mode1 >>
    I2c.write state.i2c_pid, << @prescale, prescale_val >>
    I2c.write state.i2c_pid, << @mode1, old_mode1 >>
    :time.sleep(5)

    I2c.write state.i2c_pid, << @mode1, old_mode1 &&& 0x80 >> # reset
  end

  def handle_call({:set_pwm, channel, on, off}, _from, state) do
    l_on_chan = @led0_on_l + 4 * channel
    h_on_chan = @led0_on_h + 4 * channel
    l_off_chan = @led0_off_l + 4 * channel
    h_off_chan = @led0_off_h + 4 * channel

    set_reg_word state.i2c_pid, l_on_chan, h_on_chan, on
    set_reg_word state.i2c_pid, l_off_chan, h_off_chan, off
  end

  def handle_call({:set_all_pwm, on, off}, _from, state) do
    set_reg_word state.i2c_pid, @all_led_on_l, @all_led_on_h, on
    set_reg_word state.i2c_pid, @all_led_off_l, @all_led_off_h, off
  end

  #private functions

  defp set_reg_word(i2c_pid, l_reg, h_reg, val) do
    I2c.write i2c_pid, << l_reg, val &&& 0xff >>
    I2c.write i2c_pid, << h_reg, val >>> 0xff >>
  end
end
