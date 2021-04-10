defmodule Mandarin.FormCreator do
  alias Mandarin.EctoSchemaData
  alias Mandarin.CodeGen

  def create_form_input_data(parameters) do
    fields = parameters.create_fields
    field_types = parameters.field_types

    Enum.map(fields, fn field ->
      field_type = Map.fetch!(field_types, field)
      pick_input(parameters, field, field_type)
    end)
  end

  def create_filters(parameters) do
    fields = parameters.fields
    field_types = parameters.field_types

    Enum.map(fields, fn field ->
      field_type = Map.fetch!(field_types, field)
      pick_filter(parameters, field, field_type)
    end)
  end

  # ----------------------
  # Filters
  # ----------------------

  @doc false
  def pick_filter(parameters, field, field_type) do
    # TODO: add the ability to customize filters
    default_filter_for_field(parameters, field, field_type)
  end

  defp default_filter_for_field(parameters, field, field_type) do
    case simple_type?(field_type) do
      true -> pick_default_filter_for_simple_field(parameters, field, field_type)
      false -> pick_default_filter_for_assoc(parameters, field, field_type)
    end
  end

  defp pick_default_filter_for_simple_field(_parameters, field, field_type) do
    type =
      case field_type do
        {:references, _} -> nil
        :integer -> :numeric
        :float -> :numeric
        :decimal -> :numeric
        :boolean -> nil
        :text -> :text
        :string -> :text
        :date -> :date
        :time -> :time
        :datetime -> :datetime
        :utc_datetime -> :datetime
        :naive_datetime -> :datetime
        _ -> nil
      end

    filter =
      case type do
        nil ->
          ""

        other when other in [:numeric, :date, :text, :time, :datetime] ->
          # Indent the text here becuase it's easier than indenting it in the template
          """
            <%= forage_horizontal_form_group #{inspect(field)} do %>
              <%= forage_#{other}_filter(f, #{inspect(field)}) %>
            <% end %>\
          """
      end

    filter
  end

  defp pick_default_filter_for_assoc(parameters, field, field_type) do
    case EctoSchemaData.singular_assoc?(field_type) do
      true ->
        search_field = search_field_for(parameters, field_type)
        resource_displayer = parameters.resource_displayer
        path = select_path(parameters, field_type)

        """
          <%= forage_horizontal_form_group :#{field} do %>
            <%= forage_select_filter f, #{inspect(resource_displayer)}, :#{field},
                  path: #{path},
                  remote_field: :#{search_field} %>
          <% end %>\
        """

      false ->
        nil
    end
  end

  # ----------------------
  # Form Inputs
  # ----------------------

  @doc false
  def pick_input(parameters, field, field_type) do
    # TODO: add the ability to customize filters
    pick_default_input(parameters, field, field_type)
  end

  def pick_default_input(parameters, field, field_type) do
    case simple_type?(field_type) do
      true ->
        pick_default_input_for_simple_type(parameters, field, field_type)

      false ->
        pick_default_input_for_assoc(parameters, field, field_type)
    end
  end

  def pick_default_input_for_simple_type(_parameters, field, field_type) do
    case field_type do
      {:references, _} ->
        {nil, nil, nil}

      :integer ->
        {label(field), ~s(<%= number_input f, #{inspect(field)}, class: "form-control" %>),
          error(field)}

      :float ->
        {label(field),
          ~s(<%= number_input f, #{inspect(field)}, step: "any", class: "form-control" %>),
          error(field)}

      :decimal ->
        {label(field),
          ~s(<%= number_input f, #{inspect(field)}, step: "any", class: "form-control" %>),
          error(field)}

      :boolean ->
        {label(field), ~s(<%= checkbox f, #{inspect(field)}, class: "form-control" %>), error(field)}


      :string ->
        {label(field), ~s(<%= text_input f, #{inspect(field)}, class: "form-control" %>), error(field)}


      :text ->
        {label(field), ~s(<%= textarea f, #{inspect(field)}, class: "form-control" %>), error(field)}

      :date ->
        {label(field), ~s(<%= forage_date_input f, #{inspect(field)}, class: "form-control" %>),
          error(field)}

      :time ->
        {label(field), ~s(<%= time_select f, #{inspect(field)}, class: "form-control" %>),
          error(field)}

      :utc_datetime ->
        {label(field), ~s(<%= datetime_select f, #{inspect(field)}, class: "form-control" %>),
          error(field)}

      :naive_datetime ->
        {label(field), ~s(<%= datetime_select f, #{inspect(field)}, class: "form-control" %>),
          error(field)}

      {:array, :integer} ->
        {label(field), ~s(<%= multiple_select f, #{inspect(field)}, ["1": 1, "2": 2] %>),
          error(field)}

      {:array, _} ->
        {label(field),
          ~s(<%= multiple_select f, #{inspect(field)}, ["Option 1": "option1", "Option 2": "option2"] %>),
          error(field)}

      _ ->
        {label(field), ~s(<%= text_input f, #{inspect(field)}, class: "form-control" %>),
          error(field)}
    end
  end


  defp select_path(parameters, field_type) do
    scope = parameters.scope
    related_schema = field_type.related

    CodeGen.route_to(scope, related_schema, [quote(do: @conn), :select])
  end


  defp search_field_for(parameters, field_type) do
    related_schema = field_type.related
    search_fields = parameters.search_fields
    Map.fetch!(search_fields, related_schema)
  end


  defp pick_default_input_for_assoc(parameters, field, field_type) do
    search_field = search_field_for(parameters, field_type)
    resource_displayer = parameters.resource_displayer
    path = select_path(parameters, field_type)

    input =
      case EctoSchemaData.singular_assoc?(field_type) do
        true ->
          """
            <%= forage_select f, #{inspect(resource_displayer)}, :#{field},
                    path: #{path},
                    remote_field: :#{search_field} %>\
          """

        false ->
          """
            <%= forage_multiple_select f, #{inspect(resource_displayer)}, :#{field},
                    path: #{path},
                    remote_field: :#{search_field} %>\
          """
    end

    {label(field), input, error(field)}
  end

  defp simple_type?(field_type), do: not is_map(field_type)

  defp label(field) do
    ~s(<%= label f, #{inspect(field)}, class: "control-label col-sm-2" %>)
  end

  defp error(field) do
    ~s(<%= error_tag f, #{inspect(field)} %>)
  end
end