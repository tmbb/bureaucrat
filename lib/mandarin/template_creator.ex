defmodule Mandarin.TemplateCreator do
  @moduledoc false

  require EEx
  require Logger

  alias Mandarin.FormCreator
  alias Mandarin.Naming
  alias Mandarin.CodeGen

  # We generate two kinds of templates in different places:
  # - templates associated with a given schema (or resource)
  # - "global" templates not associated with a schema.
  # It's useful to keep these distinctions.
  schema_template_names = ~w(edit filters form show index new table)
  top_level_template_names = ~w(layout sidebar)

  generate_template_data = fn name ->
    # The `template_name` will be used when defining the render/2 calls
    template_name = "#{name}.html"
    # We need a name for the function that will generate the application templates
    function_name = String.to_atom("#{name}_template_binary")

    {template_name, function_name}
  end

  # We want to precompile the mandarin templates that will generate
  # the application templates.
  # Compiling these templates gets us a three things:
  #   1. Some efficiency (probably not much, didn't bother measuring)
  #   2. Some basic correctness checks
  #   3. We get some functions we can reuse later to generate templates
  #      in case the user wants to customize the default templates.
  #      TODO: this functionality is not yet implemented.
  generate_template_function = fn {template_name, function_name} ->
    path = "lib/mandarin/templates/#{template_name}.eex"
    quoted = EEx.compile_file(path, engine: EEx.Engine)
    # Mark the template file as an external resource
    @external_resource path

    def unquote(function_name)(var!(p), var!(opts)) do
      _ = var!(p)
      _ = var!(opts)

      unquote(quoted)
    end
  end

  # Organize data in a way that will be useful later for the functions that generate the
  # application templates
  schema_template_data = Enum.map(schema_template_names, generate_template_data)
  top_level_template_data = Enum.map(top_level_template_names, generate_template_data)
  # Write this data into module attributes so that we can access it from inside function bodies
  @schema_templates schema_template_data
  @top_level_templates top_level_template_data

  # Generate functions that will write the templates which we will compile later
  Enum.map(schema_template_data ++ top_level_template_data, generate_template_function)

  def create_templates_and_render_clauses(parameters) do
    # Populate the `opts` argument with data which is not interesting
    # to Mandarin in other places (that's why we generate it here).
    # The forms and filters are only useful in a couple templates,
    # but things are much simpler if we pass them as arguments into all templates.
    form_input_data = FormCreator.create_form_input_data(parameters)
    filters = FormCreator.create_filters(parameters)
    opts = [form_input_data: form_input_data, filters: filters]

    for {name, function_name} <- @schema_templates do
      # Build a template generating function from the function name:
      generator = fn p, opts -> apply(__MODULE__, function_name, [p, opts]) end
      create_template_and_render_clause(parameters, opts, name, generator)
    end
    |> Enum.unzip()
  end

  def create_layout_templates_and_render_clauses(global_parameters) do
    # Global tempaltes don't need extra options, but we keep the second argument
    # to the `*_template_binary` functions in case it becomes useful in the future.
    opts = []

    for {name, function_name} <- @top_level_templates do
      # Build a template generating function from the function name:
      generator = fn p, opts -> apply(__MODULE__, function_name, [p, opts]) end
      create_template_and_render_clause(global_parameters, opts, name, generator)
    end
    |> Enum.unzip()
  end

  def create_template_and_render_clause(parameters, opts, name, binary_generator) do
    # Create the tempalte content as a binary...
    content = binary_generator.(parameters, opts)
    # ... and parse it into Elixir code!
    quoted =
      try do
        EEx.compile_string(
          content,
          engine: Phoenix.HTML.Engine,
          line: 1,
          trim: true
        )


      rescue
        e ->
          content_with_line_numbers = with_line_numbers(content)

          message = """
          ** Error compiling the template "#{name}" with the following contents:
          _____________________________________________________________________________________

          #{content_with_line_numbers}
          _____________________________________________________________________________________
          """

          Logger.error(message)

          raise e
      end

    # This is not very efficient, but we plan on adding support for template customization
    # in the future.  When that is possible, we want to be able to produce a template for
    # customization in the form of a binary (which gets stored somewhere in the user's
    # Phoenix application structure).
    #
    # The best way to make sure we give the user a template which is the same
    # as the default ones is to actually compile the default templates from the
    # string we want to present to the user.
    #
    # Regarding efficiency, this is a compile-time feature and it doesn't take
    # that long in practice, so I think it's acceptable

    render_clause =
      quote do
        # Generate a clause for the `render` function that will be injected
        # into the View
        def render(unquote(name), var!(assigns)) do
          _ = var!(assigns)
          unquote(quoted)
        end
      end

    {{name, content}, render_clause}
  end

  def with_line_numbers(text) do
    lines = String.split(text, "\n")
    max_line_nr = length(lines)
    max_nr_of_digits = max_line_nr |> to_string() |> String.length()

    build_line =
      fn {line, line_nr} ->
        [
          String.pad_leading(to_string(line_nr), max_nr_of_digits, " "),
          ".",
          "   ",
          line,
          "\n"
        ]
      end

    lines
    |> Enum.with_index(1)
    |> Enum.map(build_line)
    |> to_string()
  end
end