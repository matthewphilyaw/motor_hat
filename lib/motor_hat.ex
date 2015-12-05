defmodule MotorHat do
  use GenServer
  require Logger
  alias MotorHat.Pwm
  alias MotorHat.DcMotor

  defmodule State do
    defstruct boards: %{}
  end

  defmodule Board do
    defstruct devname: nil, address: nil, pwm_pid: nil, dc_motors: %{}
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: MotorHat)
  end

  def attach_board(name, devname, address, motor_config, pwm_freq \\ 1600) do
    # not sure if I should validate here.
    {:ok, motor_config} = validate_config motor_config
    GenServer.call MotorHat, {:attach_board, {name, [devname, address, motor_config, pwm_freq]}}
  end

  def get_dc_motor(name, motor) do
    GenServer.call MotorHat, {:get_dc_motor, name, motor}
  end

  def release_all_motors do
    GenServer.call MotorHat, :release_all_motors
  end

  # Call Backs

  def init([]) do
    {:ok, %State{}}
  end

  def handle_call({:attach_board, {name, board=[devname, address, _motor_config, _pwm_freq]}}, _from, state=%State{boards: boards}) do
    case can_attach(name, devname, address, boards) do
      {:error, errors} ->
        {:reply, errors, state}
      :ok ->
        {:ok, board} = start_board board
        {:reply, :ok, %State{state | boards: Map.put(boards, name, board)}}
    end
  end

  def handle_call({:get_dc_motor, board_name, pos}, _from, state=%State{boards: boards}) do
    %Board{dc_motors: motors} = boards[board_name]
    case motors[pos] do
      nil -> {:reply, {:error, :no_motor_found, "no motor under that key"}, state}
      _ -> {:reply, {:ok, motors[pos]}, state}
    end
  end

  def handle_call(:release_all_motors, _from, state=%State{boards: boards}) do
    Enum.each boards, fn b ->
      Pwm.set_all_pwm b.pwm_pid, 0, 0
    end

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

  defp can_attach(name, devname, address, boards) do
    results = [no_dup_name(name, boards)]
    results = [no_same_devname_address(devname, address, boards) | results]

    errors = Enum.filter results, &(case &1 do :ok -> false; {:error, _, _} -> true end)

    case Enum.count(errors) > 0 do
      false -> :ok
      true -> {:error, errors}
    end
  end

  defp no_dup_name(name, boards) do
    case boards[name] do
      nil -> :ok
      _ -> {:error, :board_name_exist, "a board with that name is attached"}
    end
  end

  defp no_same_devname_address(devname, address, boards) do
    case Enum.any?(Map.to_list(boards), fn {_name, b} -> b.devname == devname && b.address == address end) do
      :true ->
        {:error, :dup_board, "another board is on bus #{devname} at same address #{address}"}
      _ ->
        :ok
    end
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

  defp start_board([devname, address, motor_config, pwm_freq]) do
    i2c_mod = Application.get_env(:motor_hat, :i2c)
    {:ok, i2c_pid} = i2c_mod.start_link devname, address
    {:ok, pwm_pid} = Pwm.start_link {i2c_mod, i2c_pid}
    Pwm.set_pwm_freq pwm_pid, pwm_freq

    motor_map = start_motors motor_config, pwm_pid
    {:ok, %Board{ devname: devname,
                  address: address,
                  pwm_pid: pwm_pid,
                  dc_motors: motor_map}}
  end

  defp start_motors({:dc, motors}, pwm_pid) do
    Enum.reduce motors, %{}, fn(m, map) ->
      {:ok, motor_pid} = DcMotor.start_link pwm_pid, m
      Map.put(map, m, motor_pid)
    end
  end
end
