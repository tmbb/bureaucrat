defmodule Mandarin.GlobalParameters do
  alias Mandarin.Naming
  alias Mandarin.EctoSchemaData

  defstruct app: nil,
            master_module: nil,
            search_fields: nil,
            schemas_underscore_map: nil,
            repo: nil,
            app_web_namespace: nil,
            scope: nil,
            scope_suffix: nil,
            schemas: nil,
            scope_underscore: nil,
            layout_view_module: nil,
            layout_view_template: nil,
            layout_pipeline_name: nil,
            index_view_module: nil,
            index_controller_module: nil,
            copyright: nil,
            theme: nil

  defp join_modules(left, right) do
    Module.concat([inspect(left) <> inspect(right)])
  end

  defp pretty_copyright(copyright) when is_atom(copyright) do
    case to_string(copyright) do
      "Elixir." <> rest -> rest
      other -> other
    end
  end

  defp pretty_copyright(other), do: other

  def possible_id_field?(field) do
    field
    |> Atom.to_string()
    |> String.split("_")
    |> List.last()
    |> Kernel.==("id")
  end

  def possible_search_field?({field, field_type}) do
    isnt_assoc? = not EctoSchemaData.assoc?(field_type)
    isnt_id? = not possible_id_field?(field)
    is_string? = field_type in [:string, :text]

    isnt_assoc? and isnt_id? and is_string?
  end

  def get_default_search_field(schema) do
    schema_data = EctoSchemaData.introspect(schema)
    # Fields is a list of 2-tuples of the form {field_name, field_type}
    fields = schema_data.fields
    # Don't forget to extract only the field name; we don't have any use for the
    {field_name, _type} = Enum.find(fields, &possible_search_field?/1)

    field_name
  end

  def get_search_field({schema, opts}) do
    case Keyword.fetch(opts, :search_field) do
      {:ok, field} ->
        field

      :error ->
        get_default_search_field(schema)
    end
  end

  def new(options) do
    app = Keyword.fetch!(options, :app)
    master_module = Keyword.fetch!(options, :master_module)
    repo = Keyword.fetch!(options, :repo)
    app_web_namespace = Keyword.fetch!(options, :app_web_namespace)
    scope = Keyword.fetch!(options, :scope)
    schemas = Keyword.fetch!(options, :schemas)
    arguments = Keyword.fetch!(options, :arguments)
    copyright = Naming.module_alias(app_web_namespace)
    theme = Keyword.fetch!(options, :theme)

    search_fields =
      arguments
      |> Enum.map(fn {schema, _opts} = pair -> {schema, get_search_field(pair)} end)
      |> Enum.into(%{})

    scope_suffix = Naming.module_suffix(scope)
    scope_underscore = Naming.module_suffix_underscore(scope)

    default_layout_view_module =
      Module.concat(
        app_web_namespace,
        join_modules(scope_suffix, LayoutView)
      )

    layout_view_module = default_layout_view_module

    index_view_module =
      Module.concat([
        app_web_namespace,
        scope_suffix,
        SplashPageIndexView
      ])

    index_controller_module =
      Module.concat([
        app_web_namespace,
        scope_suffix,
        SplashPageIndexController
      ])


    default_layout_view_template = "layout.html"
    layout_view_template = default_layout_view_template

    layout_pipeline_name =
      String.to_atom("__mandarin_magik_#{scope_underscore}_layout__")

    %__MODULE__{
      app: app,
      master_module: master_module,
      search_fields: search_fields,
      repo: repo,
      app_web_namespace: app_web_namespace,
      scope: scope,
      scope_suffix: scope_suffix,
      scope_underscore: scope_underscore,
      schemas: schemas,
      layout_view_module: layout_view_module,
      layout_view_template: layout_view_template,
      layout_pipeline_name: layout_pipeline_name,
      index_controller_module: index_controller_module,
      index_view_module: index_view_module,
      copyright: pretty_copyright(copyright),
      theme: theme
    }
  end
end