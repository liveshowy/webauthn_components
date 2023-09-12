defmodule Wac.Gen.Router do
  @moduledoc false
  alias Sourceror.Zipper

  def update_router(assigns) do
    web_snake_case = Keyword.fetch!(assigns, :web_snake_case)
    router_path = Path.join(["lib", web_snake_case, "router.ex"])

    # Child AST trees to be inserted
    aliases = aliases(assigns)
    plug_fetch_current_user = plug_fetch_current_user()
    session_routes = session_routes(assigns)
    guest_routes = guest_routes(assigns)
    authenticated_routes = authenticated_routes(assigns)

    format_opts = [
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

    modified_router_contents =
      router_path
      |> File.read!()
      |> Sourceror.parse_string!()
      |> Zipper.zip()
      |> Zipper.find(&find_aliases/1)
      |> Zipper.insert_right(aliases)
      |> Zipper.find(&find_browser_pipeline/1)
      |> Zipper.insert_right(plug_fetch_current_user)
      |> Zipper.find(&find_first_scope/1)
      |> Zipper.insert_right(authenticated_routes)
      |> Zipper.insert_right(guest_routes)
      |> Zipper.insert_right(session_routes)
      |> Zipper.root()
      |> Sourceror.to_string(format_opts)

    File.write!(router_path, modified_router_contents)

    # Code.format_file!(router_path)
    IO.puts("Updated #{router_path}")
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

    quote do
      alias unquote(web_pascal_case).SessionHooks.AssignUser
      alias unquote(web_pascal_case).SessionHooks.RequireUser
      import unquote(web_pascal_case).Session, only: [fetch_current_user: 2]
    end
  end

  defp plug_fetch_current_user do
    quote do
      plug :fetch_current_user
    end
  end

  defp session_routes(assigns) do
    quote do
      # HTTP controller routes
      scope "/", unquote(assigns[:web_pascal_case]) do
        pipe_through :browser

        post "/session", Session, :create
        delete "/session", Session, :delete
      end
    end
  end

  defp guest_routes(assigns) do
    quote do
      # Unprotected LiveViews
      live_session :guest, on_mount: [AssignUser] do
        scope "/", unquote(assigns[:web_pascal_case]) do
          pipe_through :browser

          live "/sign-in", AuthenticationLive
        end
      end
    end
  end

  defp authenticated_routes(assigns) do
    quote do
      # Protected LiveViews
      live_session :authenticated, on_mount: [AssignUser, RequireUser] do
        scope "/", unquote(assigns[:web_pascal_case]) do
          pipe_through :browser

          # Example
          # live "/room/:room_id", RoomLive
        end
      end
    end
  end
end
