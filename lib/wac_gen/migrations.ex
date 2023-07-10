defmodule Wac.Gen.Migrations do
  @moduledoc """
  Functions for generating a User schema and migration.
  """

  @template_files %{
    users: "users.exs",
    user_keys: "user_keys.exs",
    user_tokens: "user_tokens.exs"
  }

  @templates Map.keys(@template_files)

  def copy_templates(assigns) do
    for template <- @templates do
      copy_template(template, assigns)
      Process.sleep(1_000)
    end
  end

  def copy_template(template, assigns) when template in @templates and is_list(assigns) do
    file_name = @template_files[template]
    timestamp = NaiveDateTime.utc_now(:second) |> Calendar.strftime("%Y%m%d%H%M%S")
    timestamped_file_name = "#{timestamp}_#{file_name}"
    template_dir = Path.expand("../../templates/migrations/", __DIR__)
    source = Path.join([template_dir, file_name])
    target = Path.join(["priv/repo/migrations", timestamped_file_name])
    Mix.Generator.copy_template(source, target, assigns)
  end
end
