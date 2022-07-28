defmodule WebAuthnLiveComponent.Form do
  use Phoenix.LiveComponent
  alias Ecto.Changeset

  # prop changeset, :struct

  def mount(socket) do
    {
      :ok,
      socket
      |> assign_new(:changeset, &build_changeset/1)
    }
  end

  defp build_changeset(assigns) do
    data = Map.get(assigns, :data, %{})
    types = %{username: :string}
    params = Map.get(assigns, :params, %{username: ""})

    {data, types}
    |> Changeset.cast(params, Map.keys(types))

    # |> Changeset.validate_required([:username])
  end

  def render(assigns) do
    ~H"""
    <form>
      <label>Username</label>
      <button type="button" value="sign_up">Sign Up</button>
      <button type="button" value="sign_in">Sign In</button>
    </form>
    """
  end
end
