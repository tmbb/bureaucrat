defmodule Mandarin.EctoSchemaData do
  alias Ecto.Association.ManyToMany

  defstruct fields: [],
            field_names: [],
            redact_fields: [],
            assocs: [],
            assoc_names: [],
            field_types: %{}


  defp belongs_to_safe_list_assocs({_name, assoc}) do
    case assoc do
      %{cardinality: :many} ->
        false

      _ ->
        true
    end
  end

  def assoc?(type) do
    is_map(type)
  end

  def singular_assoc?(type) do
    case type do
      %{cardinality: :one} -> true
      _ -> false
    end
  end

  def plural_assoc?(type) do
    case type do
      %ManyToMany{} -> true
      %{cardinality: :many} -> true
      _ -> false
    end
  end

  def simple_field?(type) do
    (not singular_assoc?(type)) and (not plural_assoc?(type))
  end

  defp get_safe_list_assocs(%__MODULE__{} = schema_data) do
    assocs = schema_data.assocs

    assocs
    |> Enum.filter(&belongs_to_safe_list_assocs/1)
    |> Enum.map(fn {name, _assoc} -> name end)
  end

  def get_safe_list_fields(%__MODULE__{} = schema_data) do
    fields = schema_data.field_names
    fields ++ get_safe_list_assocs(schema_data)
  end

  def introspect(schema) do
    field_names = schema.__schema__(:fields)

    fields =
      for field_name <- field_names do
        type = schema.__schema__(:type, field_name)
        {field_name, type}
      end

    redact_fields = schema.__schema__(:redact_fields)

    association_names = schema.__schema__(:associations)

    associations =
      for association_name <- association_names do
        type = schema.__schema__(:association, association_name)
        {association_name, type}
      end

    field_types = Enum.into(fields ++ associations, %{})

    %__MODULE__{
      fields: fields,
      field_names: field_names,
      redact_fields: redact_fields,
      assocs: associations,
      assoc_names: association_names,
      field_types: field_types
    }
  end
end