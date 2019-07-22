defmodule <%= install.web_module %>.<%= install.context_camel_case %>.IndexController do
  use <%= install.web_module %>, :controller

  # No active resource in the index page
  plug(Mandarin.Plugs.Resource, nil)

  def index(conn, params) do
    render(conn, "index.html", context: "<%= install.context_camel_case %>")
  end
end
