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
  alias <%= inspect @app_pascal_case %>.Identity
  require Logger

  defguard is_pos_integer(int) when is_integer(int) and int > 0

  @spec start_link(args :: Keyword.t()) :: GenServer.on_start()
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Manually triggers a `UserToken` cleanup.

  All expired tokens will be deleted, and the cleanup timer will be reset. Tokens will be cleaned automatically at the next `:interval_minutes` set in the GenServer's state.
  """
  @spec delete_expired_tokens :: :ok
  def delete_expired_tokens do
    Process.send(__MODULE__, :delete_expired_tokens, [])
  end

  @doc """
  Updates the interval for the cleanup process.

  The new interval will be applied to the next timer set by the cleanup process.
  """
  @spec set_interval_minutes(int :: pos_integer()) :: :ok
  def set_interval_minutes(int) when is_pos_integer(int) do
    Process.send(__MODULE__, {:update_interval_minutes, int}, [])
  end

  @doc false
  def init(args) do
    int = args[:interval_minutes] || 10
    {:ok, timer_ref} = set_timer(int)
    {:ok, [interval_minutes: int, timer_ref: timer_ref]}
  end

  defp set_timer(int) when is_pos_integer(int) do
    int
    |> :timer.minutes()
    |> :timer.apply_interval(Process, :send, [__MODULE__, :delete_expired_tokens, []])
  end

  @doc false
  def handle_info({:update_interval_minutes, int}, state) when is_pos_integer(int) do
    if ref = state[:timer_ref], do: :timer.cancel(ref)
    {:ok, timer_ref} = set_timer(int)

    new_state =
      state
      |> Keyword.put(:interval_minutes, int)
      |> Keyword.put(:timer_ref, timer_ref)

    {:noreply, new_state}
  end

  @doc false
  def handle_info(:delete_expired_tokens, state) do
    {count, _results} = Identity.delete_all_expired_tokens()
    Logger.info(expired_tokens_deleted: count)
    {:noreply, state}
  end
end
