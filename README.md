# SimpleSSO

Adds single sign on functionality to a Phoenix app.

This library acts as a single sign on client by providing a controller that works
in conjunction with Simple Auth to authenticate the user against an OAuth2 provider
and store the user's details in the session.

In addition to providing the standard OAuth2 endpoints, the provider must
provide a URL that gives the current user's details when provided with a token.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `simple_sso` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:simple_sso, "~> 0.1.0"}
  ]
end
```
## Use

### Add configuration for SimpleAuth and SimpleSSO

```elixir
config :simple_auth,
  user_session_api: SimpleAuth.UserSession.Memory,
  session_expiry_seconds: 3600,
  login_url: {SimpleSSO.OAuthController, :authorize_url},
  error_view: MyApp.ErrorView,
  user_model: MyApp.User #Optional - if not specified a map is stored as the user

config :simple_sso,
  error_view: MyApp.ErrorView,
  current_user_path: "/api/users/me" # Gets the current user when given Bearer token in the authorization header

config :simple_sso, :oauth,
  client_id: "my-client",
  client_secret: "my-secret",
  redirect_uri: "http://my-site/auth/callback",
  site: "http://oauth-provider-site"
```

### Add routes

Add the following to `router.ex` to match the `redirect_uri` above:

```elixir
scope "/" do
  pipe_through(:browser)
  get("/auth/callback", SimpleSSO.OAuthController, :auth_callback)
end
```

### Provide a login link (optional)
```
<%= link "Student Login", to: SimpleSSO.OAuthController.authorize_url() %>
```


### Single sign out (Optional)
Add the following optional route if you want single sign out also:
```elixir
pipeline :api do
  plug(:accepts, ["json"])
end

scope "/" do
  pipe_through(:api)
  delete("/api/logout", SimpleSSO.OAuthController, :logout_api)
end
```

In the provider you must call this URL to force all sessions for the user to logout
e.g.
```
  DELETE http://my-site/api/logout?user_id=1234
```
If there are multiple OAuth consumers, multiple logouts can be done here by posting to each URL.

In your app just set the logout link to the provider's logout UI link.

Therefore the process will be as follows:
1. User clicks on logout link
2. Logout action is executed on provider site
3. Provider backend sends API calls to each OAuth consumers passing the user id
4. The OAuth consumer controller (within SimpleSSO controller) deletes the in memory session for the user.

## Provider requirements
The OAuth2 provider must have the following endpoints:

* `/oauth/authorize` - OAuth2 Authorize endpoint that redirects the the `redirect_uri` with a `code`
* `/oauth/token` - OAuth2 Token endpoint that exchanges a `code` for a `token`
* `/api/users/me` - Provides json in the following structure given a `token` in the `Authorize` header

```json
{
   "user":{
      "id":1234,
      "email":"user1@acme.com"
   },
   "roles":[
      "ROLE_ADMIN"
   ]
}
```

These URLs are configurable in the config.
