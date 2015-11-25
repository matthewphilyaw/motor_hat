defmodule MotorHat.DcMotor do
  use GenServer
  alias MotorHat.Pwm

  defmodule State do
    defstruct pwm_pid: nil, name: nil, pin_one: nil, pin_two: nil, pin_pwm: nil
  end

  #public Api

  def start_link(pwm_pid, name=:m1) do
    state = %State{pwm_pid: pwm_pid, name: name, pin_one: 10, pin_two: 9, pin_pwm: 8}

    GenServer.start_link(__MODULE__, state, [])
  end

  def start_link(pwm_pid, name=:m2) do
    state = %State{pwm_pid: pwm_pid, name: name, pin_one: 11, pin_two: 12, pin_pwm: 13}

    GenServer.start_link(__MODULE__, state, [])
  end

  def start_link(pwm_pid, name=:m3) do
    state = %State{pwm_pid: pwm_pid, name: name, pin_one: 4, pin_two: 3, pin_pwm: 2}

    GenServer.start_link(__MODULE__, state, [])
  end

  def start_link(pwm_pid, name=:m4) do
    state = %State{pwm_pid: pwm_pid, name: name, pin_one: 5, pin_two: 6, pin_pwm: 7}

    GenServer.start_link(__MODULE__, state, [])
  end

  def run(pid, dir=:forward) do
    GenServer.call pid, {:set_direction, dir}
  end

  def run(pid, dir=:backward) do
    GenServer.call pid, {:set_direction, dir}
  end

  def run(pid, dir=:release) do
    GenServer.call pid, {:set_direction, dir}
  end

  def set_speed(pid, val) when is_integer(val) and val < 256 and val >= 0 do
    GenServer.call pid, {:set_speed, val}
  end

  #private Api
  def init(state) do
    {:ok, state}
  end

  def handle_call({:set_direction, :forward}, _from, state=%State{pwm_pid: pid, pin_one: one, pin_two: two}) do
    Pwm.set_pwm pid, one, 4096, 0
    Pwm.set_pwm pid, two, 0, 4096

    {:reply, :ok, state}
  end

  def handle_call({:set_direction, :backward}, _from, state=%State{pwm_pid: pid, pin_one: one, pin_two: two}) do
    Pwm.set_pwm pid, one, 0, 4096
    Pwm.set_pwm pid, two, 4096, 0

    {:reply, :ok, state}
  end

  def handle_call({:set_direction, :release}, _from, state=%State{pwm_pid: pid, pin_one: one, pin_two: two}) do
    Pwm.set_pwm pid, one, 0, 0
    Pwm.set_pwm pid, two, 0, 0

    {:reply, :ok, state}
  end

  def handle_call({:set_speed, val}, _from, state=%State{pwm_pid: pid, pin_pwm: pwm}) when is_integer(val) and val < 256 and val >= 0 do
    Pwm.set_pwm pid, pwm, 0, val * 16

    {:reply, :ok, state}
  end
end
