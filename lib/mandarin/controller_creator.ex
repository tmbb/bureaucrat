defmodule Mandarin.ControllerCreator do
  alias Mandarin.Naming
  alias Mandarin.Routes
  alias Mandarin.Parameters

  def create_controller(%Parameters{} = parameters) do
    schema = parameters.schema
    controller_module = parameters.controller_module
    accessor_module = parameters.accessor_module
    routes_module = parameters.routes_module
    scope_underscore = parameters.scope_underscore
    master_module = parameters.master_module
    resource = parameters.resource

    resource_string = Atom.to_string(resource)
    humanized_resource = Naming.humanize(resource_string)
    route_function_name = Routes.route_function_name(scope_underscore, resource)

    contents =
      quote do
        use Phoenix.Controller, namespace: unquote(controller_module)
        import Plug.Conn

        # Adds the the resource type to the conn
        plug(Mandarin.Plugs.Resource, unquote(resource))

        def index(conn, params) do
          page = unquote(accessor_module).list_resource(params)
          render(conn, "index.html", [page: page])
        end

        def new(conn, _params) do
          changeset = unquote(accessor_module).change_resource(%unquote(schema){})
          render(conn, "new.html", changeset: changeset)
        end

        def create(conn, %{unquote(resource_string) => resources_params}) do
          case unquote(accessor_module).create_resource(resources_params) do
            {:ok, resource} ->
              redirection_url =
                apply(
                  unquote(routes_module),
                  unquote(route_function_name),
                  [conn, :show, resource]
                )

              conn
              |> put_flash(:info, unquote("#{humanized_resource} created successfully."))
              |> redirect(to: redirection_url)

            {:error, %Ecto.Changeset{} = changeset} ->
              render(conn, "new.html", changeset: changeset)
          end
        end

        def show(conn, %{"id" => id}) do
          resource = unquote(accessor_module).get_resource!(id)
          render(conn, "show.html", [{unquote(resource), resource}])
        end

        def edit(conn, %{"id" => id}) do
          resource = unquote(accessor_module).get_resource!(id)
          changeset = unquote(accessor_module).change_resource(resource)
          render(conn, "edit.html", [
            {unquote(resource), resource},
            {:changeset, changeset}
          ])
        end

        def update(conn, %{"id" => id, unquote(resource_string) => resource_params}) do
          resource = unquote(accessor_module).get_resource!(id)
          case unquote(accessor_module).update_resource(resource, resource_params) do
            {:ok, employee} ->
              redirection_url =
                apply(
                  unquote(routes_module),
                  unquote(route_function_name),
                  [conn, :update, resource]
                )

              conn
              |> put_flash(:info, unquote("#{humanized_resource} updated successfully."))
              |> redirect(to: redirection_url)

            {:error, %Ecto.Changeset{} = changeset} ->
              render(conn, "edit.html", [
                {unquote(resource), resource},
                {:changeset, changeset}
              ])
          end
        end

        def delete(conn, %{"id" => id} = params) do
          resource = unquote(accessor_module).get_resource!(id)
          {:ok, _employee} = unquote(accessor_module).delete_resource(resource)
          # After deleting, remain on the same page
          redirect_params = ForageWeb.ForageController.pagination_from_params(params)

          redirection_url =
            apply(
              unquote(routes_module),
              unquote(route_function_name),
              [conn, :index, redirect_params]
            )

          conn
          |> put_flash(:info, unquote("#{humanized_resource} deleted successfully."))
          |> redirect(to: redirection_url)
        end

        def select(conn, params) do
          resources = unquote(accessor_module).list_resource(params)
          data =
            ForageWeb.ForageController.forage_select_data(
              unquote(master_module),
              resources
            )
          json(conn, data)
        end
      end

    Module.create(controller_module, contents, Macro.Env.location(__ENV__))
  end
end