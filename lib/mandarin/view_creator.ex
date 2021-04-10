defmodule Mandarin.ViewCreator do
  @moduledoc false

  alias Mandarin.Parameters
  alias Mandarin.GlobalParameters
  alias Mandarin.TemplateCreator

  def create_view(%Parameters{} = parameters) do
    view_module = parameters.view_module
    app_web_namespace = parameters.app_web_namespace
    routes_module = parameters.routes_module
    forage_view_prefix = parameters.forage_view_prefix
    schemas = parameters.schemas

    {templates, render_clauses} = TemplateCreator.create_templates_and_render_clauses(parameters)

    aliases =
      # Make schemas into aliases in order to have less verbose templates.
      #
      # You might ask why I'm worrying about verbosity in a project
      # that's so deep into compile-time metaprogramming that long
      # function names and large numbers of parameters are quite
      # inconsequential.
      #
      # The reason is that we plan on making it possible for users
      # to customize the templas, which means that templates
      # should be easily human-editable.
      #
      # Deining the less-verbose functions inside the view make it easier.
      for schema <- schemas do
        quote do
          alias unquote(schema), warn: false
        end
      end

    contents =
      quote do
        # WARNING: We have no control over what the user has defined
        # in their `AppWeb.view()` function! This means the user
        # can break Mandarin by doing weird stuff.
        #
        # We trust that a less experienced user of Mandarin won't
        # be doing weird stuff in the `AppWeb.view()` function,
        # and think about an alternative for more experienced users.
        use unquote(app_web_namespace), :view

        unquote_splicing(aliases)

        # Use ForageWeb.ForageView so that a couple of useful functions
        # become available in a less verbose way.
        # Deining the less-verbose functions inside the view make it easier.
        # Remember we ant the templates to be user-editable.
        use ForageWeb.ForageView,
          routes_module: unquote(routes_module),
          prefix: unquote(forage_view_prefix)

        unquote_splicing(render_clauses)
      end

    Module.create(view_module, contents, Macro.Env.location(__ENV__))

    {templates, contents}
  end

  def create_layout_view(%GlobalParameters{} = global_parameters) do
    app_web_namespace = global_parameters.app_web_namespace
    layout_view_module = global_parameters.layout_view_module

    {templates, render_clauses} =
      TemplateCreator.create_layout_templates_and_render_clauses(global_parameters)

    contents =
      quote do
        # WARNING: We have no control over what the user has defined
        # in their `AppWeb.view()` function! This means the user
        # can break Mandarin by doing weird stuff.
        #
        # We trust that a less experienced user of Mandarin won't
        # be doing weird stuff in the `AppWeb.view()` function,
        # and think about an alternative for more experienced users.
        use unquote(app_web_namespace), :view

        unquote_splicing(render_clauses)
      end

    Module.create(layout_view_module, contents, Macro.Env.location(__ENV__))

    {templates, contents}
  end
end