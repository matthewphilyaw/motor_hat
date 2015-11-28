defmodule MotorHat do
  use GenServer
  require Logger
  alias MotorHat.Pwm
  alias MotorHat.DcMotor

  defmodule State do
    defstruct devname: nil, address: nil, pwm_pid: nil, dc_motors: %{}
  end

  def start_link(devname, address, motor_config, pwm_freq \\ 1600) do
    {:ok, motor_config} = validate_config motor_config
    GenServer.start_link(__MODULE__, [devname, address, motor_config, pwm_freq])
  end

  def get_dc_motor(pid, motor) do
    GenServer.call pid, {:get_dc_motor, motor}
  end

  def release_all_motors(pid) do
    GenServer.call pid, :release_all_motors
  end

  # Call Backs

  def init([devname, address, motor_config, pwm_freq]) do
    {:ok, pwm_pid} = Pwm.start_link devname, address
    Pwm.set_pwm_freq pwm_pid, pwm_freq

    motor_map = start_motors motor_config, pwm_pid
    {:ok, %State{ devname: devname, 
                  address: address,
                  pwm_pid: pwm_pid,
                  dc_motors: motor_map}}
  end

  def handle_call({:get_dc_motor, pos}, _from, state=%State{dc_motors: motors}) do
    case motors[pos] do
      nil -> {:reply, {:error, :no_motor_found, "no motor under that key"}, state}
      _ -> {:reply, {:ok, motors[pos]}, state}
    end
  end

  def handle_call(:release_all_motors, _from, state=%State{pwm_pid: pwm_pid}) do
    Pwm.set_all_pwm pwm_pid, 0, 0

    {:reply, :ok, state}
  end

  # Private

  def validate_config(motor_config = {:dc, motors}) do
    results = [is_valid_count(Enum.count(motors))]
    results = [no_dup_motors(motors) | results]
    results = results ++ Enum.map motors, fn m -> valid_motor_position m end

    errors = Enum.filter results, &(case &1 do :ok -> false; {:error, _, _} -> true end)

    case Enum.count(errors) > 0 do
      false -> {:ok, motor_config}
      true -> {:error, errors}
    end
  end

  defp is_valid_count(count) when is_integer(count) and count < 1 or count > 4 do
    {:error, :invalid_count, "please provide between :m1 and :m4 dc motor positions"}
  end

  defp is_valid_count(_count) do
    :ok
  end

  defp no_dup_motors(motors) do
    case motors == Enum.uniq motors do
      true -> :ok
      false -> {:error, :dup_motors, "please provide a unique list of motor positions"}
    end
  end

  defp valid_motor_position(motor) do
    case motor do
      :m1 -> :ok
      :m2 -> :ok
      :m3 -> :ok
      :m4 -> :ok
      _ -> {:error, :invalid_position, "invalid motor position #{inspect motor}"}
    end 
  end

  defp start_motors({:dc, motors}, pwm_pid) do
    Enum.reduce motors, %{}, fn(m, map) ->
      {:ok, motor_pid} = DcMotor.start_link pwm_pid, m
      Map.put(map, m, motor_pid)
    end
  end
end
