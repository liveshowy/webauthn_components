defmodule Wac.Gen.RouterError do
  defexception [:message]

  @impl true
  def exception(message) do
    formatted_message =
      """
      🫣 #{message}

      🙏 Please review the WebauthnComponents issue tracker and open a new issue if necessary.
      👉 https://github.com/liveshowy/webauthn_components/issues
      👇 For debugging, please include this error and the stacktrace below:
      """

    %__MODULE__{message: formatted_message}
  end
end

defmodule Wac.Gen.Router do
  @moduledoc false
  alias Sourceror.Zipper

  @format_opts [
    locals_without_parens: [
      plug: :*,
      get: :*,
      scope: :*,
      delete: :*,
      live: :*,
      post: :*,
      forward: :*,
      live_dashboard: :*,
      live_session: :*,
      pipe_through: :*
    ]
  ]

  def update_router(assigns) do
    web_snake_case = Keyword.fetch!(assigns, :web_snake_case)
    router_path = Path.join(["lib", web_snake_case, "router.ex"])

    modified_router_contents =
      router_path
      |> File.read!()
      |> Sourceror.parse_string!()
      |> Zipper.zip()
      |> Zipper.find(&find_aliases/1)
      |> insert_aliases(assigns)
      |> Zipper.find(&find_browser_pipeline/1)
      |> insert_plugs()
      |> Zipper.find(&find_first_scope/1)
      |> insert_routes(assigns)
      |> Zipper.root()
      |> Sourceror.to_string(@format_opts)

    File.write!(router_path, modified_router_contents)
    status = IO.ANSI.red() <> "* updating " <> IO.ANSI.reset() <> router_path
    IO.puts(status)
  end

  defp insert_aliases(%Zipper{} = zipper, assigns) do
    aliases = aliases(assigns)

    zipper
    |> Zipper.insert_right(aliases)
  end

  defp insert_aliases(nil, _assigns) do
    raise Wac.Gen.RouterError, "Unable to find aliases"
  end

  defp insert_plugs(%Zipper{} = zipper) do
    plug_fetch_current_user = plug_fetch_current_user()

    zipper
    |> Zipper.insert_right(plug_fetch_current_user)
  end

  defp insert_plugs(nil) do
    raise Wac.Gen.RouterError, "Unable to find the browser pipeline"
  end

  defp insert_routes(%Zipper{} = zipper, assigns) do
    session_routes = session_routes(assigns)
    guest_routes = guest_routes(assigns)
    authenticated_routes = authenticated_routes(assigns)

    zipper
    |> Zipper.insert_right(authenticated_routes)
    |> Zipper.insert_right(guest_routes)
    |> Zipper.insert_right(session_routes)
  end

  defp insert_routes(nil, _assigns) do
    raise Wac.Gen.RouterError, "Unable to find the first router scope"
  end

  defp find_aliases({:use, _meta, [{_, _, _}, {:__block__, _, [:router]} | _]}), do: true
  # defp find_aliases({:defmodule, _meta, [{_, _, _} | _]}), do: true
  defp find_aliases(_), do: false

  defp find_browser_pipeline({:plug, _, [{:__block__, _, [:put_secure_browser_headers]} | _]}),
    do: true

  defp find_browser_pipeline(_), do: false

  defp find_first_scope({:scope, _, [{:__block__, _, ["/"]} | _]}), do: true
  defp find_first_scope(_), do: false

  # AST Trees

  defp aliases(assigns) do
    web_pascal_case = assigns[:web_pascal_case]

    """
    alias #{inspect(web_pascal_case)}.SessionHooks.AssignUser
    alias #{inspect(web_pascal_case)}.SessionHooks.RequireUser
    import #{inspect(web_pascal_case)}.Session, only: [fetch_current_user: 2]
    """
    |> Sourceror.parse_string!()
  end

  defp plug_fetch_current_user do
    """
      plug :fetch_current_user
    """
    |> Sourceror.parse_string!()
  end

  defp session_routes(assigns) do
    web_pascal_case = assigns[:web_pascal_case]

    """
    # HTTP controller routes
    scope "/", #{inspect(web_pascal_case)} do
      pipe_through :browser

      post "/session", Session, :create
      delete "/session", Session, :delete
    end
    """
    |> Sourceror.parse_string!()
  end

  defp guest_routes(assigns) do
    web_pascal_case = assigns[:web_pascal_case]

    """
    # Unprotected LiveViews
    live_session :guest, on_mount: [AssignUser] do
      scope "/", #{inspect(web_pascal_case)} do
        pipe_through :browser

        live "/sign-in", AuthenticationLive
      end
    end
    """
    |> Sourceror.parse_string!()
  end

  defp authenticated_routes(assigns) do
    web_pascal_case = assigns[:web_pascal_case]

    """
    # Protected LiveViews
    live_session :authenticated, on_mount: [AssignUser, RequireUser] do
      scope "/", #{inspect(web_pascal_case)} do
        pipe_through :browser

        # Example
        # live "/room/:room_id", RoomLive
      end
    end
    """
    |> Sourceror.parse_string!()
  end
end
