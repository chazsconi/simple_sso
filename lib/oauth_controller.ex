defmodule SimpleSSO.OAuthController do
  use Phoenix.Controller
  require Logger

  @doc "Call back from OAuth Provider"
  def auth_callback(conn, %{"error" => error}) do
    # This should not happen
    Logger.error("auth_callback error: #{inspect(error)}")

    conn
    |> put_status(500)
    |> render(error_view(), "500.html")
  end

  def auth_callback(conn, %{"code" => code}) do
    client = init_client()

    authorized_client =
      client
      |> OAuth2.Client.get_token!([code: code, client_secret: client.client_secret], [
        {"accept", "application/json"}
      ])

    case OAuth2.Client.get(authorized_client, current_user_path()) do
      {:ok, %OAuth2.Response{body: %{"roles" => roles, "user" => user_json}, status_code: 200}} ->
        user_map = %{id: user_json["id"], email: user_json["email"], roles: roles}

        user =
          case user_model() do
            nil -> user_map
            model -> struct(model, user_map)
          end

        conn
        |> SimpleAuth.UserSession.put(user)
        |> redirect(to: post_login_path())

      resp ->
        Logger.error("#{current_user_path()} error resp: #{inspect(resp)}")

        conn
        |> put_status(500)
        |> render(error_view(), "500.html")
    end
  end

  @doc "Ajax endpoint for Single Sign Out"
  def logout(conn, _) do
    conn
    |> SimpleAuth.UserSession.delete()
    |> text("OK")
  end

  @doc "Server side api logout for all sessions"
  def logout_api(conn, %{"user_id" => user_id}) do
    Logger.info("Logout: #{user_id}")
    SimpleAuth.UserSession.delete(String.to_integer(user_id))
    send_resp(conn, 201, "")
  end

  @doc "Used in SimpleAuth as the login_url"
  def authorize_url() do
    OAuth2.Client.authorize_url!(init_client(), scope: "read")
  end

  defp init_client do
    OAuth2.Client.new(
      strategy: OAuth2.Strategy.AuthCode,
      client_id: Application.get_env(:simple_sso, :oauth)[:client_id],
      client_secret: Application.get_env(:simple_sso, :oauth)[:client_secret],
      redirect_uri: Application.get_env(:simple_sso, :oauth)[:redirect_uri],
      site: Application.get_env(:simple_sso, :oauth)[:site]
    )
    |> OAuth2.Client.put_serializer("application/json", Jason)
  end

  defp error_view, do: Application.get_env(:simple_sso, :error_view)
  defp current_user_path, do: Application.get_env(:simple_sso, :current_user_path)
  defp post_login_path, do: Application.get_env(:simple_auth, :post_login_path)
  defp user_model(), do: Application.get_env(:simple_auth, :user_model)
end
