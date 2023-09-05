defmodule <%= inspect @app_pascal_case %>.Users do
  @moduledoc """
  Functions for managing users.
  """

  alias Ecto.Changeset
  alias <%= inspect @app_pascal_case %>.Repo
  alias <%= inspect @app_pascal_case %>.Users.User

  @doc """
  Returns all `User` records with optional preloads.
  """
  @spec list(preloads :: list()) :: [User.t()]
  def list(preloads \\ []) when is_list(preloads) do
    User
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  @doc """
  Inserts a new `User` into the repo.
  """
  @spec create(attrs :: map()) :: {:ok, User.t()} | {:error, Changeset.t()}
  def create(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Retrieves a `User` from the repo.
  """
  @spec get(id :: binary(), preloads :: list()) :: {:ok, User.t()} | {:error, :not_found}
  def get(id, preloads \\ []) do
    result =
      User
      |> Repo.get(id)
      |> Repo.preload(preloads)

    case result do
      %User{} ->
        {:ok, result}

      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  Modifies an existing `User` in the repo.
  """
  @spec update(user :: User.t(), attrs :: map()) :: {:ok, User.t()} | {:error, Changeset.t()}
  def update(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Removes an existing `User` from the repo.
  """
  @spec delete(user :: User.t()) :: {:ok, User.t()} | {:error, Changeset.t()}
  def delete(%User{} = user) do
    Repo.delete(user)
  end
end
