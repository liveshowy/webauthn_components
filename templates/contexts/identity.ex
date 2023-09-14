defmodule <%= inspect @app_pascal_case %>.Identity do
  @moduledoc """
  Functions for managing users.
  """

  alias Ecto.Changeset
  alias <%= inspect @app_pascal_case %>.Repo
  alias <%= inspect @app_pascal_case %>.Identity.User
  alias <%= inspect @app_pascal_case %>.Identity.UserToken
  import Ecto.Query

  #
  @token_expiration {24, :hour}

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
  Retrieves a `User` by querying a valid token.
  """
  @spec get_by_token(raw_value :: binary(), type :: atom()) ::
          {:ok, User.t()} | {:error, :not_found}
  def get_by_token(raw_value, type \\ :session) when is_binary(raw_value) do
    {expiration, unit} = @token_expiration

    expiration_timestamp =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-expiration, unit)

    query =
      from(user in User,
        join: token in assoc(user, :tokens),
        where:
          token.value == ^raw_value and
            token.type == ^type and
            token.inserted_at < ^expiration_timestamp,
        order_by: [desc: token.inserted_at],
        limit: 1
      )

    case Repo.one(query) do
      %User{} = user ->
        {:ok, user}

      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  Retrieves a `User` by querying an associated `:key_id`.
  """
  @spec get_by_key_id(key_id :: binary()) :: {:ok, User.t()} | {:error, :not_found}
  def get_by_key_id(key_id) when is_binary(key_id) do
    query =
      from(user in User,
        join: key in assoc(user, :keys),
        where: key.key_id == ^key_id
      )

    case Repo.one(query) do
      %User{} = user ->
        {:ok, user}

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

  # USER TOKENS

  @doc """
  Inserts a new `UserToken` into the repo.
  """
  @spec create_token(attrs :: map()) :: {:ok, UserToken.t()} | {:error, Changeset.t()}
  def create_token(attrs) do
    %UserToken{}
    |> UserToken.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes all session tokens belonging to a user.
  """
  def delete_all_user_sessions(user_id) do
    from(token in UserToken, where: token.user_id == ^user_id and token.type == :session)
    |> Repo.delete_all()
  end
end
