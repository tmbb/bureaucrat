defmodule Mandarin.CodeGen do
  alias Mandarin.Naming

  def call_fa(function, args) do
    args_string =
      args
      |> Enum.map(&Macro.to_string/1)
      |> Enum.join(", ")

    "#{function}(#{args_string})"
  end

  def code(string) do
    Code.string_to_quoted!(string)
  end

  def call_mfa(module, function, args) do
    inspect(module) <> "." <> call_fa(function, args)
  end

  def at(arg) when is_atom(arg) or is_binary(arg) do
    "@#{arg}"
  end

  def route_to(scope, schema, args) do
    scope_underscore = Naming.module_alias_to_underscore(scope)
    schema_underscore = Naming.module_alias_to_underscore(schema)

    function = "#{scope_underscore}_#{schema_underscore}_path"

    call_mfa(Routes, function, args) |> check_syntax!()
  end

  def dgettext(parameters, value) when is_binary(value) do
    scope_underscore =
      parameters.scope
      |> Naming.module_alias_to_underscore()
      |> to_string()

    domain = "mandarin.#{scope_underscore}"

    "dgettext(#{inspect(domain)}, #{inspect(value)})"
  end

  def check_syntax!(string) do
    Code.string_to_quoted!(string)
    string
  end
end