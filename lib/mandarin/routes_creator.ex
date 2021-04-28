defmodule Mandarin.Routes do
  alias Mandarin.GlobalParameters
  alias Mandarin.Naming
  @moduledoc false
  def route_function_name(scope_underscore, resource) do
    name = "#{scope_underscore}_#{resource}_path"

    String.to_atom(name)
  end

  def create_routes(parameters) do
    routes_path = parameters.routes_path
    select_path = "#{routes_path}/select"
    controller_suffix = parameters.controller_suffix

    quote do
      require Phoenix.Router
      # Add a special "select" route to work with the Select2 widget
      Phoenix.Router.get(
        unquote(select_path),
        unquote(controller_suffix),
        :select
      )
      # Add the "normal" routes for a Phoenix resource
      Phoenix.Router.resources(
        unquote(routes_path),
        unquote(controller_suffix)
      )
    end
  end

  @doc false
  def __mandarin_scope__(
        %GlobalParameters{} = global_parameters,
        path,
        route_calls,
        keywords)
      do

    body = Keyword.get(keywords, :do, [])
    scope = global_parameters.scope
    scope_underscore = global_parameters.scope_underscore
    layout_pipeline_name = global_parameters.layout_pipeline_name
    layout_view_module = global_parameters.layout_view_module
    layout_view_template = global_parameters.layout_view_template
    index_controller_alias = Naming.module_suffix(global_parameters.index_controller_module)

    quote do
      require Phoenix.Router
      require Phoenix.Controller
      # Add a new scope to the router
      Phoenix.Router.scope unquote(path), unquote(scope), as: unquote(scope_underscore) do
        # Add the user-defined code after adding the Mandarin routes
        unquote(body)

        # Define a pipeline that sets the layout:
        Phoenix.Router.pipeline unquote(layout_pipeline_name) do
          Phoenix.Router.plug(
            # If you do weird stuff in your Router, maybe `:put_layout`
            # won't be available.
            # TODO: fix this
            :put_layout,
            {unquote(layout_view_module), unquote(layout_view_template)}
          )
        end

        Phoenix.Router.pipe_through(unquote(layout_pipeline_name))

        get "/", unquote(index_controller_alias), :index
        # Add the Mandarin routes
        unquote_splicing(route_calls)
      end
    end
  end
end