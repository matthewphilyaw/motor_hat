defmodule MotorHat.Board do
  use GenServer
  require Logger
  alias MotorHat.Pwm
  alias MotorHat.DcMotor

  defmodule Board do
    defstruct devname: nil, address: nil, pwm_pid: nil, dc_motors: %{}
  end

  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def get_dc_motor(board, motor) do
    GenServer.call board, {:get_dc_motor, motor}
  end

  def release_all_motors(board) do
    GenServer.call board, :release_all_motors
  end

  # Call Backs

  def init([nil, nil]) do
    {:stop, "missing i2c_module,and board definition see docs"}
  end

  def init([nil, _board]) do
    {:stop, "missing i2c_module, see docs"}
  end

  def init([_i2c_mod, nil]) do
    {:stop, "missing board definition, see docs"}
  end

  def init([i2c_mod, board]) do
    Logger.debug fn -> "using board config: #{inspect board}" end

    devname = board[:devname]
    address = board[:address]

    {:ok, i2c_pid} = i2c_mod.start_link devname, address
    {:ok, pwm_pid} = Pwm.start_link {i2c_mod, i2c_pid}

    pwm_freq = Keyword.get(board, :pwm_freq, 1600)
    Pwm.set_pwm_freq pwm_pid, pwm_freq

    {:ok, motor_config} = validate_config board[:motor_config]
    motor_map = start_motors motor_config, pwm_pid
    {:ok, %Board{ devname: devname,
                  address: address,
                  pwm_pid: pwm_pid,
                  dc_motors: motor_map}}
  end

  def handle_call({:get_dc_motor, pos}, _from, state) do
    motor = state.dc_motors[pos]
    case motor do
      nil -> {:reply, {:error, :no_motor_found, "no motor under that key"}, state}
      m -> {:reply, {:ok, m}, state}
    end
  end

  def handle_call(:release_all_motors, _from, state) do
    Pwm.set_all_pwm state.pwm_pid, 0, 0

    {:reply, :ok, state}
  end

  # Private

  defp validate_config(motor_config = {:dc, motors}) do
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
    Enum.reduce motors, %{}, fn m, map ->
      {:ok, motor_pid} = DcMotor.start_link pwm_pid, m
      Map.put(map, m, motor_pid)
    end
  end
end
