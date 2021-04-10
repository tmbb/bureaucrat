defmodule Mandarin.Naming do
  @moduledoc false

  # Conveniences for inflecting and working with names in Mandarin.
  # Many of these functions are unsafe because they generate atoms at runtime.
  # They should only be used during project compilation and not with user-provided input.

  @doc """
  Extracts the resource name from an alias.

  ## Examples

      iex> Mandarin.Naming.resource_name(MyApp.User)
      "user"

      iex> Mandarin.Naming.resource_name(MyApp.UserView, "View")
      "user"

  """
  @spec resource_name(String.Chars.t(), String.t()) :: String.t()
  def resource_name(alias, suffix \\ "") do
    alias
    |> to_string()
    |> Module.split()
    |> List.last()
    |> unsuffix(suffix)
    |> underscore()
  end

  @doc """
  Removes the given suffix from the name if it exists.

  ## Examples

      iex> Mandarin.Naming.unsuffix("MyApp.User", "View")
      "MyApp.User"

      iex> Mandarin.Naming.unsuffix("MyApp.UserView", "View")
      "MyApp.User"

  """
  @spec unsuffix(String.t(), String.t()) :: String.t()
  def unsuffix(value, suffix) do
    string = to_string(value)
    suffix_size = byte_size(suffix)
    prefix_size = byte_size(string) - suffix_size

    case string do
      <<prefix::binary-size(prefix_size), ^suffix::binary>> -> prefix
      _ -> string
    end
  end

  def module_alias(module) do
    module
    |> Module.split()
    |> List.last()
  end

  def module_suffix(module) do
    module
    |> Module.split()
    |> List.last()
    |> List.wrap()
    |> Module.concat()
  end

  def module_suffix_underscore(module) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  def module_alias_to_underscore(module) do
    module_alias_to_underscore(module, :string)
  end

  def module_alias_to_underscore(module, :atom) do
    module
    |> module_alias_to_underscore(:string)
    |> String.to_atom()
  end

  def module_alias_to_underscore(module, :string) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  @doc """
  Converts String to underscore case.

  ## Examples

      iex> Mandarin.Naming.underscore("MyApp")
      "my_app"

  In general, `underscore` can be thought of as the reverse of
  `camelize`, however, in some cases formatting may be lost:

      Mandarin.Naming.underscore "SAPExample"  #=> "sap_example"
      Mandarin.Naming.camelize   "sap_example" #=> "SapExample"

  """
  @spec underscore(String.t()) :: String.t()
  def underscore(value), do: Macro.underscore(value)

  defp to_lower_char(char) when char in ?A..?Z, do: char + 32
  defp to_lower_char(char), do: char

  @doc """
  Converts String to camel case.

  Takes an optional `:lower` option to return lowerCamelCase.

  ## Examples

      iex> Mandarin.Naming.camelize("my_app")
      "MyApp"

      iex> Mandarin.Naming.camelize("my_app", :lower)
      "myApp"

  In general, `camelize` can be thought of as the reverse of
  `underscore`, however, in some cases formatting may be lost:

      Mandarin.Naming.underscore "SAPExample"  #=> "sap_example"
      Mandarin.Naming.camelize   "sap_example" #=> "SapExample"

  """
  @spec camelize(String.t()) :: String.t()
  def camelize(value), do: Macro.camelize(value)

  @spec camelize(String.t(), :lower) :: String.t()
  def camelize("", :lower), do: ""

  def camelize(<<?_, t::binary>>, :lower) do
    camelize(t, :lower)
  end

  def camelize(<<h, _t::binary>> = value, :lower) do
    <<_first, rest::binary>> = camelize(value)
    <<to_lower_char(h)>> <> rest
  end

  @doc """
  Converts a plural to a singular.

  Works with both strings and atoms.
  """
  def singularize(atom) when is_atom(atom),
    do: singularize(Atom.to_string(atom))

  def singularize(string) when is_binary(string) do
    Inflex.singularize(string)
  end

  @doc """
  Converts a singular to a plural.
  """
  def pluralize(atom) when is_atom(atom),
    do: pluralize(Atom.to_string(atom))

  def pluralize(string) when is_binary(string),
    do: Inflex.pluralize(string)

  @doc """
  ...
  """
  def table_name_to_module_name(atom) when is_atom(atom),
    do: table_name_to_module_name(Atom.to_string(atom))

  def table_name_to_module_name(string) when is_binary(string) do
    string
    |> singularize_last()
    |> camelize()
  end

  defp singularize_last(name_with_underscores) do
    name_with_underscores
    |> String.split("_")
    |> List.update_at(-1, fn name -> singularize(name) end)
    |> Enum.join("_")
  end

  @doc """
  Converts an attribute/form field into its humanize version.

      iex> Mandarin.Naming.humanize(:username)
      "Username"
      iex> Mandarin.Naming.humanize(:created_at)
      "Created at"
      iex> Mandarin.Naming.humanize("user_id")
      "User"
  """
  @spec humanize(atom | String.t()) :: String.t()
  def humanize(atom) when is_atom(atom),
    do: humanize(Atom.to_string(atom))

  def humanize("Elixir." <> rest), do: humanize(rest)

  def humanize(bin) when is_binary(bin) do
    bin =
      if String.ends_with?(bin, "_id") do
        binary_part(bin, 0, byte_size(bin) - 3)
      else
        bin
      end

    bin |> String.replace("_", " ") |> String.capitalize()
  end

  def humanize_alias(module) do
    module
    |> module_alias()
    |> humanize()
  end

  def humanize_and_pluralize_alias(module) do
    module
    |> module_alias()
    |> humanize()
    |> pluralize()
  end
end
