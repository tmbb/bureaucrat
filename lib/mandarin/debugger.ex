defmodule Mandarin.Debugger do
  @moduledoc false
  alias Mandarin.DebugConfig
  alias Mandarin.Naming

  def debug(nil, _resource_data), do: :ok

  def debug(%DebugConfig{} = debug_data, resource_data) do
    if debug_data.dump_templates_into do
      dump_templates_into(resource_data, debug_data.dump_templates_into)
    end
  end

  def dump_templates_into(resource_data, dir) do
    templates = resource_data.templates
    resources_dir = Path.join(dir, "resources")
    File.mkdir_p!(resources_dir)
    for {schema, data} <- templates do
      subdir = Naming.module_alias_to_underscore(schema)
      for {name, content} <- data do
        rel_subdir = Path.join(resources_dir, subdir)
        File.mkdir_p!(rel_subdir)
        path = Path.join(rel_subdir, name) <> ".eex"
        File.write!(path, content)
      end
    end
  end
end