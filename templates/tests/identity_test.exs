defmodule <%= inspect @app_pascal_case %>.IdentityTest do
  @moduledoc false
  use <%= inspect @app_pascal_case %>.DataCase, async: true
  alias <%= inspect @app_pascal_case %>.IdentityFixtures
  alias <%= inspect @app_pascal_case %>.Identity
  alias <%= inspect @app_pascal_case %>.Identity.User
  alias <%= inspect @app_pascal_case %>.Identity.UserKey
  alias <%= inspect @app_pascal_case %>.Identity.UserToken


  describe "list/1" do
    setup do
      users =
      Stream.repeatedly(fn -> IdentityFixtures.user_fixture() end)
      |> Enum.take(10)

      %{users: users}
    end

    test "returns list of users without preloads", %{users: users} do
      user_list = Identity.list()
      user_ids = Enum.map(user_list, & &1.id)
      refute Enum.empty?(user_list)

      for user <- user_list do
        assert %User{} = user
        refute Ecto.assoc_loaded?(user.keys)
        refute Ecto.assoc_loaded?(user.tokens)
      end

      for user <- users do
        assert user.id in user_ids
      end
    end

    test "returns list of users with preloads", %{users: users} do
      user_list = Identity.list([:keys, :tokens])
      user_ids = Enum.map(user_list, & &1.id)
      refute Enum.empty?(user_list)

      for user <- user_list do
        assert %User{} = user
        assert Ecto.assoc_loaded?(user.keys)
        assert Ecto.assoc_loaded?(user.tokens)
        assert Enum.all?(user.keys, &is_struct(&1, UserKey))
        assert Enum.all?(user.tokens, &is_struct(&1, UserToken))
      end

      for user <- users do
        assert user.id in user_ids
      end
    end
  end

  describe "create/1" do
    test "returns error with invalid params" do
      assert {:error, changeset} = Identity.create(%{})
      assert %Ecto.Changeset{valid?: false, errors: errors} = changeset
      assert {"can't be blank", _} = errors[:email]
    end

    test "returns error with existing email" do
      attrs = IdentityFixtures.valid_user_attrs()
      {:ok, _user} = Identity.create(attrs)
      {:error, changeset} = Identity.create(attrs)
      assert %Ecto.Changeset{valid?: false, errors: errors} = changeset
      assert {"has already been taken", _} = errors[:email]
    end

    test "returns success with valid params" do
      attrs = IdentityFixtures.valid_user_attrs()
      assert {:ok, user} = Identity.create(attrs)
      assert %User{} = user
      assert user.email == attrs.email
    end
  end

  describe "get/2" do
    setup do
      %{user: IdentityFixtures.user_fixture()}
    end

    test "returns error with invalid id" do
      invalid_id = Ecto.ULID.generate()
      assert {:error, :not_found} = Identity.get(invalid_id)
    end

    test "returns success with valid id", %{user: user} do
      assert {:ok, found_user} = Identity.get(user.id)
      assert found_user.id == user.id
      assert found_user.email == user.email
      refute Ecto.assoc_loaded?(found_user.keys)
      refute Ecto.assoc_loaded?(found_user.tokens)
    end

    test "returns success with preloads", %{user: user} do
      assert {:ok, found_user} = Identity.get(user.id, [:keys, :tokens])
      assert found_user.id == user.id
      assert found_user.email == user.email
      assert Ecto.assoc_loaded?(found_user.keys)
      assert Ecto.assoc_loaded?(found_user.tokens)
    end
  end

  describe "update/2" do
    setup do
      %{user: IdentityFixtures.user_fixture()}
    end

    test "returns error with invalid params", %{user: user} do
      assert {:error, changeset} = Identity.update(user, %{email: "bad email"})
      assert %Ecto.Changeset{valid?: false, errors: errors} = changeset
      assert {"has invalid format", _} = errors[:email]
    end

    test "returns success with valid params", %{user: user} do
      attrs = IdentityFixtures.valid_user_attrs()
      assert {:ok, updated_user} = Identity.update(user, attrs)
      assert updated_user.id == user.id
      assert updated_user.email == attrs.email
    end
  end

  describe "delete/1" do
    setup do
      %{user: IdentityFixtures.user_fixture()}
    end

    test "returns error with invalid user" do
      invalid_id = Ecto.ULID.generate()
      assert_raise Ecto.StaleEntryError, fn -> Identity.delete(%User{id: invalid_id}) end
    end

    test "returns success with valid user", %{user: user} do
      assert {:ok, deleted_user} = Identity.delete(user)
      assert deleted_user.id == user.id
      assert deleted_user.email == user.email
    end
  end
end
