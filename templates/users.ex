defmodule <%= @app_pascal_case %>.Users do
  @moduledoc """
  Functions for managing users.
  """

  import Ecto.Query
  alias Ecto.Changeset
  alias <%= @app_pascal_case %>.Repo
  alias <%= @app_pascal_case %>.Users.User

  @doc """
  Returns all `User` records matching the optional query parameters.

  See `Ecto.Query.from/2` for supported options.
  """
  @spec query(opts :: Keyword.t()) :: [User.t()]
  def query(opts \\ []) when is_list(opts) do
    from(user in User, opts)
    |> Repo.all()
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
