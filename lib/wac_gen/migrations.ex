defmodule Wac.Gen.Migrations do
  @moduledoc """
  Functions for generating a User schema and migration.
  """

  @template_files %{
    users: "users.ex",
    user_keys: "user_keys.ex",
    user_tokens: "user_tokens.ex"
  }

  @templates Map.keys(@template_files)

  def copy_templates(assigns) do
    for template <- Enum.sort(@templates), do: copy_template(template, assigns)
  end

  def copy_template(template, assigns) when template in @templates and is_list(assigns) do
    file_name = @template_files[template]
    timestamp = NaiveDateTime.local_now() |> Calendar.strftime("%Y%m%d%H%M%S")
    timestamped_file_name = "#{timestamp}_#{file_name}"
    template_dir = Path.expand("../../templates/migrations/", __DIR__)
    source = Path.join([template_dir, file_name])
    target = Path.join(["priv/repo/migrations", timestamped_file_name])
    Mix.Generator.copy_template(source, target, assigns)
  end
end
