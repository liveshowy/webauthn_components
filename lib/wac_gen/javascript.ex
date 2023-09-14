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

    updated_contents =
      javascript_path
      |> File.read!()
      |> String.replace(
        ~r/(import { LiveSocket } from "phoenix_live_view";)/,
        "\g{1}\n#{@import_hooks}"
      )
      |> String.replace(~r/(params: { _csrf_token: csrfToken })/, "\g{1},\n#{@socket_hooks}")

    File.write!(javascript_path, updated_contents)
  end
end
