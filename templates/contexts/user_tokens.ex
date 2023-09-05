defmodule <%= inspect @app_pascal_case %>.UserTokens do
  @moduledoc """
  Functions for managing user tokens.
  """

  import Ecto.Query
  alias Ecto.Changeset
  alias <%= inspect @app_pascal_case %>.Repo
  alias <%= inspect @app_pascal_case %>.UserTokens.UserToken

  @rand_size 32
  @session_validity_in_days 7

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.

  The reason why we store session tokens in the database, even
  though Phoenix already provides a session cookie, is because
  Phoenix' default session cookies are not persisted, they are
  simply signed and potentially encrypted. This means they are
  valid indefinitely, unless you change the signing/encryption
  salt.

  Therefore, storing them allows individual user
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  You could then use this information to display all valid sessions
  and devices in the UI and allow users to explicitly expire any
  session they deem invalid.
  """
  def build_token(user, type \\ :session) do
    value = :crypto.strong_rand_bytes(@rand_size)
    %UserToken{value: value, type: type, user_id: user.id}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any.

  The token is valid if it matches the value in the database and it has
  not expired (after @session_validity_in_days).
  """
  def verify_token_query(token, validity_in_days \\ @session_validity_in_days) do
    from token in token_and_type_query(token, :session),
      join: user in assoc(token, :user),
      where: token.inserted_at > ago(^validity_in_days, "day"),
      select: user
  end

  @doc """
  Returns the token struct for the given token value and type.
  """
  def token_and_type_query(token, type) do
    from UserToken, where: [token: ^token, type: ^type]
  end

  @doc """
  Returns all `UserToken` records with optional preloads.
  """
  @spec list(preloads :: list()) :: [User.t()]
  def list(preloads \\ []) when is_list(preloads) do
    UserToken
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  @doc """
  Inserts a new `UserToken` into the repo.
  """
  @spec create(attrs :: map()) :: {:ok, UserToken.t()} | {:error, Changeset.t()}
  def create(attrs) do
    %UserToken{}
    |> UserToken.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Retrieves a `UserToken` from the repo.
  """
  @spec get(id :: binary(), preloads :: list()) :: {:ok, UserToken.t()} | {:error, :not_found}
  def get(id, preloads \\ []) do
    result =
      UserToken
      |> Repo.get(id)
      |> Repo.preload(preloads)

    case result do
      %UserToken{} ->
        {:ok, result}

      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  Modifies an existing `UserToken` in the repo.
  """
  @spec update(user_token :: UserToken.t(), attrs :: map()) ::
          {:ok, UserToken.t()} | {:error, Changeset.t()}
  def update(%UserToken{} = user_token, attrs) do
    user_token
    |> UserToken.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Removes an existing `UserToken` from the repo.
  """
  @spec delete(user_token :: UserToken.t()) :: {:ok, UserToken.t()} | {:error, Changeset.t()}
  def delete(%UserToken{} = user_token) do
    Repo.delete(user_token)
  end
end
