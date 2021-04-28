defmodule Mandarin.IndexCreator do
  @moduledoc false
  require EEx

  def create_index(global_params) do
    create_view(global_params)
    create_controller(global_params)
  end

  @external_resource "lib/mandarin/templates/splash.html.eex"

  @quoted_render_body EEx.compile_file(
    "lib/mandarin/templates/splash.html.eex",
    engine: Phoenix.HTML.Engine
  )

  def create_view(global_params) do
    app_web_namespace = global_params.app_web_namespace
    view_module = global_params.index_view_module

    contents =
      quote do
        use unquote(app_web_namespace), :view

        def render("splash.html", var!(assigns)) do
          _ = var!(assigns)
          unquote(@quoted_render_body)
        end
      end

    Module.create(view_module, contents, Macro.Env.location(__ENV__))
  end

  def create_controller(global_params) do
    controller_module = global_params.index_controller_module

    contents =
      quote do
        use Phoenix.Controller, namespace: unquote(controller_module)
        import Plug.Conn

        def index(conn, _params) do
          render(conn, "splash.html", [conn: conn])
        end
      end

    Module.create(controller_module, contents, Macro.Env.location(__ENV__))
  end
end