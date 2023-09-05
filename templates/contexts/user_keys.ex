defmodule <%= inspect @app_pascal_case %>.UserKeys do
  @moduledoc """
  Functions for managing user keys.
  """

  alias Ecto.Changeset
  alias <%= inspect @app_pascal_case %>.Repo
  alias <%= inspect @app_pascal_case %>.UserKeys.UserKey

  @doc """
  Returns all `UserKey` records with optional preloads.
  """
  @spec list(preloads :: list()) :: [User.t()]
  def list(preloads \\ []) when is_list(preloads) do
    UserKey
    |> Repo.all()
    |> Repo.preload(preloads)
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
