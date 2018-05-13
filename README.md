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
  user_session_api: SimpleAuth.UserSession.HTTPSession,
  login_url: {SimpleSSO.OAuthController, :authorize_url},
  error_view: MyApp.ErrorView,

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
pipeline :remote_ajax do
  plug(:accepts, ["json"])
  plug(:fetch_session)
  plug(:put_secure_browser_headers)
end

scope "/" do
  pipe_through(:remote_ajax)
  delete("/logout", SimpleSSO.OAuthController, :logout) # or alternative logout path
end
```

Also provide a logout link to the SSO Provider's logout URL and ensure that the onclick action
of the logout button here triggers something similar to this:

```html
<a href="/logout" onclick="remoteLogout()">Logout</a>
```

```javascript
remoteLogout = function() {
	$.ajax({
		url: 'http://my-site/logout',
		type: 'DELETE',
		success: function(result) {
			true;
		}
	});
	return true;
};
```

If there are multiple OAuth consumers, multiple logouts can be done here.

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
