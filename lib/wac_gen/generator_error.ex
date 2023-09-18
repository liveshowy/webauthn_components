defmodule Wac.Gen.GeneratorError do
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
