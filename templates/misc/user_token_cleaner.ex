defmodule <%= @app_pascal_case %>.UserTokenCleaner do
  @moduledoc """
  Periodically deletes all expired user tokens in the repo.

  `UserTokenCleaner` relies on the application's `Repo`, so it must be started after the `Repo` in the application's supervisor. See the example below.

  ## Options

  The following options may be passed to `UserTokenCleaner` via `start_link/1`:

  - `:interval_minutes` - Determines how frequently expired tokens will be deleted. The value must be a positive integer of `1` or greater. Defaults to `10`.

  ## Token Deletion

  `UserTokenCleaner` calls to the application's `Identity.delete_all_expired_tokens/0`. `UserToken` expiration is defined in the `Identity` module, and `UserTokenCleaner`'s `:interval_minutes` sets the frequency for executing the `Repo` cleanup.

  ## Example

  Start `UserTokenCleaner` with its default options:

  ```
  def start(_type, _args) do
    children = [
      MyApp.Repo,
      MyApp.UserTokenCleaner,
      ...
    ]

    opts = [strategy: :one_for_one, name: Passkeys.Supervisor]
    Supervisor.start_link(children, opts)
  end
  ```

  Start `UserTokenCleaner` with a custom interval in minutes:

  ```
  def start(_type, _args) do
    children = [
      MyApp.Repo,
      {MyApp.UserTokenCleaner, interval_minutes: 60},
      ...
    ]

    opts = [strategy: :one_for_one, name: Passkeys.Supervisor]
    Supervisor.start_link(children, opts)
  end
  ```
  """
  use GenServer
  import Ecto.Query
  alias <%= @app_pascal_case %>.Identity

  defguard is_pos_integer(int) when is_integer(int) and int > 0

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Manually triggers a `UserToken` cleanup.

  All expired tokens will be deleted, and the cleanup timer will be reset. Tokens will be cleaned automatically at the next `:interval_minutes` set in the GenServer's state.
  """
  @spec delete_expired_tokens :: :ok
  def delete_expired_tokens do
    GenServer.cast(__MODULE__, :delete_expired_tokens)
  end

  @doc """
  Updates the interval for the cleanup process.

  The new interval will be applied to the next timer set by the cleanup process.
  """
  @spec set_interval_minutes(int :: pos_integer()) :: Keyword.t()
  def set_interval_minutes(int) when is_pos_integer(int) do
    GenServer.call(__MODULE__, {:update_interval_minutes, int})
  end

  @doc false
  def init(opts) do
    interval_minutes = opts[:interval_minutes] || 10
    GenServer.cast(__MODULE__, :delete_expired_tokens)
    {:ok, timer_ref: nil, interval_minutes: interval_minutes}
  end

  @doc false
  def handle_call({:update_interval_minutes, int}, _from, state) when is_pos_integer(int) do
    {:noreply, [interval_minutes: int | state]}
  end

  @doc false
  def handle_cast(:delete_expired_tokens = msg, _from, state) do
    timer_ref = state[:time_ref]
    if timer_ref, do: Process.cancel_timer(timer_ref)

    case Identity.delete_all_expired_tokens() do
      {count, _results} ->
        Logger.info(deleted_user_token_count: count)

      invalid_result ->
        Logger.error(invalid_user_token_delete_result: invalid_result)
    end

    interval_milliseconds = calculate_interval_milliseconds(state[:interval_minutes])
    timer_ref = Process.send_after(self(), msg, interval_milliseconds)
    {:ok, timer_ref: timer_ref}
  end

  @doc false
  def handle_info(:delete_expired_tokens = msg, state) do
    GenServer.cast(__MODULE__, msg)
    {:noreply, state}
  end

  @spec calculate_interval_milliseconds(int :: pos_integer()) :: pos_integer()
  defp calculate_interval_milliseconds(int) when is_pos_integer(int) do
    int * 60 * 1_000
  end
end
