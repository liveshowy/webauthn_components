defmodule <%= inspect @app_pascal_case %>.UserFixtures do
  @moduledoc false
  alias <%= inspect @app_pascal_case %>.Users

  def valid_user_attrs(attrs \\ []) do
    Enum.into(attrs, %{
      email: "user#{System.unique_integer([:positive, :monotonic])}@example.com"
    })
  end

  def user_fixture(attrs \\ []) do
    {:ok, user} =
      attrs
      |> valid_user_attrs()
      |> Users.create()

    user
  end
end
