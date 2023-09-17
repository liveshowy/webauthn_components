defmodule <%= inspect @app_pascal_case %>.IdentityFixtures do
  @moduledoc false
  alias <%= inspect @app_pascal_case %>.Identity

  def random_integer, do: System.unique_integer([:positive, :monotonic])
  def unique_email, do: "user#{random_integer()}@example.com"

  def valid_user_attrs(attrs \\ []) do
    Enum.into(attrs, %{
      email: unique_email()
    })
  end

  def user_fixture(attrs \\ []) do
    {:ok, user} =
      attrs
      |> valid_user_attrs()
      |> Identity.create()

    user
  end
end
