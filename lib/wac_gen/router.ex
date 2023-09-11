defmodule Wac.Gen.Router do
  @moduledoc false

  def update_router(assigns) do
    web_snake_case = Keyword.fetch!(assigns, :web_snake_case)
    router_path = Path.join(["lib", web_snake_case, "router.ex"])
    # Slack request for help:
    # https://elixir-lang.slack.com/archives/C03EPRA3B/p1694398121220679
    IO.puts("Skipping #{router_path} for now")
  end
end
