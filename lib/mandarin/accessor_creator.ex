defmodule Mandarin.AccessorCreator do

  def create_accessor(parameters) do
    accessor_module = parameters.accessor_module
    schema = parameters.schema
    repo = parameters.repo
    sort_fields = parameters.sort_fields

    list_assoc_preloads = parameters.list_assoc_preloads
    assoc_preloads = parameters.assoc_preloads

    contents =
      quote do
        import Ecto.Query, warn: false

        def list_resource(params) do
          Forage.paginate(
            params,
            unquote(schema),
            unquote(repo),
            sort: unquote(sort_fields),
            preload: unquote(list_assoc_preloads)
          )
        end

        def get_resource!(id) do
          unquote(schema)
          |> unquote(repo).get!(id)
          |> unquote(repo).preload(unquote(assoc_preloads))
        end

        def create_resource(attrs \\ %{}) do
          attrs = Forage.load_assocs(unquote(repo), unquote(schema), attrs)

          %unquote(schema){}
          |> unquote(schema).changeset(attrs)
          |> unquote(repo).insert()
        end

        def update_resource(%unquote(schema){} = resource, attrs) do
          attrs = Forage.load_assocs(unquote(repo), unquote(schema), attrs)

          resource
          |> unquote(schema).changeset(attrs)
          |> unquote(repo).update()
        end

        def delete_resource(%unquote(schema){} = resource) do
          unquote(repo).delete(resource)
        end

        def change_resource(%unquote(schema){} = resource) do
          unquote(schema).changeset(resource, %{})
        end
      end

    Module.create(accessor_module, contents, Macro.Env.location(__ENV__))
  end
end