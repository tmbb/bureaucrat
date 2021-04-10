defmodule Mandarin.Parameters do
  alias Mandarin.EctoSchemaData
  alias Mandarin.Naming
  alias Mandarin.GlobalParameters

  @non_editable_fields [
    :id,
    :inserted_at,
    :updated_at
  ]

  defstruct master_module: nil,
            master_module_alias: nil,
            resource_displayer: nil,
            resource_displayer_alias: nil,
            app_web_namespace: nil,
            repo: nil,

            accessor_module: nil,
            controller_module: nil,
            view_module: nil,
            renderer_module: nil,
            routes_module: nil,
            routes_path: nil,

            accessor_suffix: nil,
            controller_suffix: nil,
            view_suffix: nil,
            renderer_suffix: nil,

            schema: nil,
            schema_suffix: nil,
            schema_underscore: nil,
            schema_humanized: nil,
            schema_humanized_plural: nil,
            schema_data_map: nil,
            resource: nil,
            resource_plural_string: nil,
            schemas: nil,

            scope: nil,
            scope_suffix: nil,
            scope_underscore: nil,

            fields: nil,
            list_fields: nil,
            create_fields: nil,
            edit_fields: nil,
            show_fields: nil,

            sort_fields: nil,
            list_assoc_preloads: nil,
            assoc_preloads: nil,
            forage_view_prefix: nil,

            field_types: nil,
            filters: nil,
            search_fields: nil


  defp join_modules(left, right) do
    Module.concat([inspect(left) <> inspect(right)])
  end

  def get_assoc_preloads(%EctoSchemaData{} = schema_data) do
    assocs = schema_data.assocs
    Enum.map(assocs, fn {name, _assoc} -> name end)
  end

  def get_sort_fields(options, %EctoSchemaData{} = schema_data) do
    with {:ok, value} <- Keyword.fetch(options, :sort_fields) do
        {true, value}
      else
        :error ->
          fields = schema_data.field_names
          fields_without_id = Enum.reject(fields, fn name -> name == :id end)

          sort_fields_apart_from_id =
            case fields_without_id do
              [] -> []
              [field | _] -> [field]
            end

          {false, sort_fields_apart_from_id ++ [:id]}
      end
  end

  defp remove_id(fields) do
    Enum.reject(fields, fn name ->
      name_is_id? = (name == :id)

      name_ends_with_id? =
        name
        |> Atom.to_string()
        |> String.split("_")
        |> List.last()
        |> Kernel.==("id")

      name_is_id? or name_ends_with_id?
    end)
  end

  def get_fields(options, %EctoSchemaData{} = schema_data) do
    with {:ok, value} <- Keyword.fetch(options, :fields) do
        {true, value}
      else
        :error ->
          fields = remove_id(schema_data.field_names ++ schema_data.assoc_names)
          {false, fields}
      end
  end


   def get_fields_with_default(options, key, default) do
    with {:ok, value} <- Keyword.fetch(options, key) do
        {true, value}
      else
        :error ->
          {false, default}
      end
  end

  def get_editable_fields_with_default(options, key, default) do
    with {:ok, value} <- Keyword.fetch(options, key) do
        {true, value}
      else
        :error ->
          editable_default =
            Enum.reject(default, fn field -> field in @non_editable_fields end)

          {false, editable_default}
      end
  end

  def new(options) do
    global_parameters = Keyword.fetch!(options, :global_parameters)
    %GlobalParameters{} = global_parameters
    repo = global_parameters.repo
    scope = global_parameters.scope
    scope_suffix = global_parameters.scope_suffix
    app_web_namespace = global_parameters.app_web_namespace
    schemas = global_parameters.schemas
    master_module = global_parameters.master_module
    search_fields = global_parameters.search_fields

    master_module_alias = Naming.module_suffix(master_module)
    resource_displayer = master_module
    resource_displayer_alias = Naming.module_suffix(resource_displayer)

    schema = Keyword.fetch!(options, :schema)
    # schema_data_map = Keyword.fetch!(options, :schema_data_map)
    schema_suffix = Naming.module_suffix(schema)
    schema_humanized = Naming.humanize(schema_suffix)
    schema_humanized_plural = Naming.pluralize(schema_humanized)

    scope_underscore = scope_suffix |> Naming.underscore() |> String.to_atom()
    schema_underscore = schema_suffix |> Naming.underscore() |> String.to_atom()
    resource = schema_underscore
    resource_plural_string = Naming.pluralize(resource)
    forage_view_prefix = String.to_atom("#{scope_underscore}_#{schema_underscore}")

    controller_suffix = join_modules(schema_suffix, Controller)
    view_suffix = join_modules(schema_suffix, View)
    accessor_suffix = join_modules(schema_suffix, Accessor)
    renderer_suffix = join_modules(schema_suffix, Renderer)

    controller_module = Module.concat(scope, controller_suffix)
    view_module = Module.concat(scope, view_suffix)
    accessor_module = Module.concat(scope,accessor_suffix)
    renderer_module = Module.concat(scope, renderer_suffix)

    schema_data = EctoSchemaData.introspect(schema)

    safe_list_fields =
      schema_data
      |> EctoSchemaData.get_safe_list_fields()
      |> remove_id()

    {_fields_supplied?, fields} =
      get_fields(options, schema_data)

    {_list_fields_supplied?, list_fields} =
      get_fields_with_default(options, :list_fields, safe_list_fields)

    {_edit_fields_supplied?, edit_fields} =
      get_editable_fields_with_default(options, :edit_fields, fields)

    {_create_fields_supplied?, create_fields} =
      get_editable_fields_with_default(options, :create_fields, fields)

    {_show_fields_supplied?, show_fields} =
      get_fields_with_default(options, :show_fields, fields)

    list_assoc_preloads =
      Enum.filter(list_fields, fn field -> field in schema_data.assoc_names end)

    assoc_preloads = schema_data.assoc_names

    field_types = schema_data.field_types

    {_sort_fields_supplied?, sort_fields} =
      get_sort_fields(options, schema_data)

    filters = []

    routes_module =
      Module.concat([
        app_web_namespace,
        Router,
        Helpers
      ])

    routes_path = "/#{schema_underscore}"

    %__MODULE__{
      master_module: master_module,
      master_module_alias: master_module_alias,
      resource_displayer: resource_displayer,
      resource_displayer_alias: resource_displayer_alias,

      repo: repo,
      app_web_namespace: app_web_namespace,
      scope: scope,
      scope_suffix: scope_suffix,
      scope_underscore: scope_underscore,

      schema: schema,
      schema_suffix: schema_suffix,
      schema_underscore: schema_underscore,
      schema_humanized: schema_humanized,
      schema_humanized_plural: schema_humanized_plural,
      resource: schema_underscore,
      resource_plural_string: resource_plural_string,
      schemas: schemas,
      # schema_data_map: schema_data_map,
      # MVC(AR) modules
      controller_module: controller_module,
      view_module: view_module,
      accessor_module: accessor_module,
      renderer_module: renderer_module,
      routes_module: routes_module,

      controller_suffix: controller_suffix,
      view_suffix: view_suffix,
      accessor_suffix: accessor_suffix,
      renderer_suffix: renderer_suffix,

      routes_path: routes_path,
      # Data-related stuff
      # * Data representation
      fields: fields,
      list_fields: list_fields,
      create_fields: create_fields,
      edit_fields: edit_fields,
      show_fields: show_fields,

      field_types: field_types,

      sort_fields: sort_fields,
      assoc_preloads: assoc_preloads,
      list_assoc_preloads: list_assoc_preloads,

      forage_view_prefix: forage_view_prefix,
      filters: filters,
      search_fields: search_fields
    }
  end
end