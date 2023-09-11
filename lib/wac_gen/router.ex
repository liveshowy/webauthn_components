defmodule Wac.Gen.Router do
  @moduledoc false

  def update_router(assigns) do
    web_snake_case = Keyword.fetch!(assigns, :web_snake_case)
    router_path = Path.join(["lib", web_snake_case, "router.ex"])
  end
end
