defmodule Wac.Gen.Javascript do
  @moduledoc false

  @import_hooks """
  import {
    SupportHook,
    AuthenticationHook,
    RegistrationHook,
  } from "webauthn_components";
  """

  @socket_hooks "hooks: { SupportHook, AuthenticationHook, RegistrationHook }"

  def inject_hooks do
    javascript_path = Path.join(["assets", "js", "app.js"])
    status = IO.ANSI.red() <> "* updating " <> IO.ANSI.reset() <> javascript_path
    IO.puts(status)

    updated_contents =
      javascript_path
      |> File.read!()
      |> String.replace(import_regex(), "\\1\n#{@import_hooks}")
      |> String.replace(socket_regex(), "\\1,\n#{@socket_hooks}")

    File.write!(javascript_path, updated_contents)
  end

  defp import_regex,
    do: Regex.compile!("(import {\s?LiveSocket\s?} from \"phoenix_live_view\";?)")

  defp socket_regex, do: Regex.compile!("(params: {\s?_csrf_token: csrfToken\s?})")
end
