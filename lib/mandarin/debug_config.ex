defmodule Mandarin.DebugConfig do
  defstruct dump_templates_into: nil

  def new(options \\ []) do
    struct(__MODULE__, options)
  end
end