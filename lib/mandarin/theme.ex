defmodule Mandarin.Theme do
  @moduledoc false
  alias Mandarin.{
    Naming,
    GlobalParameters
  }

  @css_basename "bootstrap.min.css"

  def relative_theme_css_path(%GlobalParameters{} = params) do
    admin_module = params.master_module
    basename = Naming.module_alias_to_underscore(admin_module) <> ".css"

    Path.join([
      "/",
      "css",
      basename
    ])
  end

  def setup_theme(%GlobalParameters{} = params) do
    app = params.app
    theme = params.theme
    {:bootswatch, theme_path} = theme

    themes_dir =
      Path.join([
        :code.priv_dir(:mandarin),
        "themes",
        "bootswatch"
      ])

    # Path relative to Mandarin's priv directory
    src = Path.join([themes_dir, theme_path, @css_basename])
    # Path relative to the
    rel_dst_path = relative_theme_css_path(params)

    dst = Path.join([
      :code.priv_dir(app),
      "static",
      rel_dst_path
    ])

    File.cp!(src, dst)
  end
end