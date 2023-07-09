defmodule <%= inspect @app_pascal_case %>.UserKeys do
  @moduledoc """
  Functions for managing user keys.
  """
  import Ecto.Query
  alias Ecto.Changeset
  alias <%= inspect @app_pascal_case %>.Repo
  alias <%= inspect @app_pascal_case %>.UserKeys.UserKey

  @doc """
  Returns all `UserKey` records matching the optional query parameters.

  See `Ecto.Query.from/2` for supported options.
  """
  @spec query(opts :: Keyword.t()) :: [UserKey.t()]
  def query(opts \\ []) when is_list(opts) do
    from(user_key in UserKey, opts)
    |> Repo.all()
  end

  @doc """
  Inserts a new `UserKey` into the repo.
  """
  @spec create(attrs :: map()) :: {:ok, UserKey.t()} | {:error, Changeset.t()}
  def create(attrs) do
    %UserKey{}
    |> UserKey.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Retrieves a `UserKey` from the repo.
  """
  @spec get(id :: binary(), preloads :: list()) :: {:ok, UserKey.t()} | {:error, :not_found}
  def get(id, preloads \\ []) do
    result =
      UserKey
      |> Repo.get(id)
      |> Repo.preload(preloads)

    case result do
      %UserKey{} ->
        {:ok, result}

      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  Modifies an existing `UserKey` in the repo.
  """
  @spec update(user_key :: UserKey.t(), attrs :: map()) ::
          {:ok, UserKey.t()} | {:error, Changeset.t()}
  def update(%UserKey{} = user_key, attrs) do
    user_key
    |> UserKey.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Removes an existing `UserKey` from the repo.
  """
  @spec delete(user_key :: UserKey.t()) :: {:ok, UserKey.t()} | {:error, Changeset.t()}
  def delete(%UserKey{} = user_key) do
    Repo.delete(user_key)
  end
end
