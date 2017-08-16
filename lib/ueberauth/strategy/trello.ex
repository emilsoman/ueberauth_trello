defmodule Ueberauth.Strategy.Trello do
  @moduledoc """
  Trello Strategy for Überauth.
  """

  use Ueberauth.Strategy, uid_field: :id_str

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Strategy.Trello

  @doc """
  Handles initial request for Trello authentication.
  """
  def handle_request!(conn) do
    token = Trello.OAuth.request_token!([], [redirect_uri: callback_url(conn)])
    IO.puts "handle_request! TOKEN: #{inspect token}"

    conn
    |> put_session(:trello_token, token)
    |> redirect!(Trello.OAuth.authorize_url!(token))
  end

  @doc """
  Handles the callback from Trello.
  """
  def handle_callback!(%Plug.Conn{params: %{"oauth_verifier" => oauth_verifier}} = conn) do
    token = get_session(conn, :trello_token)
    IO.puts "handle_callback! TOKEN: #{inspect token}"
    case Trello.OAuth.access_token(token, oauth_verifier) do
      {:ok, access_token} -> fetch_user(conn, access_token)
      {:error, error} -> set_errors!(conn, [error(error.code, error.reason)])
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:trello_user, nil)
    |> put_session(:trello_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string

    conn.private.trello_user[uid_field]
  end

  @doc """
  Includes the credentials from the trello response.
  """
  def credentials(conn) do
    {token, secret} = conn.private.trello_token
    IO.puts "credentials: #{inspect token}, #{inspect secret}"

    %Credentials{token: token, secret: secret}
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.trello_user

    %Info{
      email: user["email"],
      image: "http://www.gravatar.com/avatar/#{user["gravatarHash"]}.jpg",
      name: user["fullName"],
      nickname: user["username"],
      description: user["description"],
      urls: %{
        Trello: "https://trello.com/#{user["username"]}",
        Website: user["url"]
      }
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the trello callback.
  """
  def extra(conn) do
    {token, _secret} = get_session(conn, :trello_token)

    %Extra{
      raw_info: %{
        token: token,
        user: conn.private.trello_user
      }
    }
  end

  defp fetch_user(conn, token) do
    params = []
    # params = [{"include_entities", false}, {"skip_status", true}, {"include_email", true}]
    case Trello.OAuth.get("/1/members/me", params, token) do
      {:ok, %{status_code: 401, body: _, headers: _}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      {:ok, %{status_code: status_code, body: body, headers: _}} when status_code in 200..399 ->
        IO.puts body
        body = Poison.decode!(body)

        conn
        |> put_private(:trello_token, token)
        |> put_private(:trello_user, body)
      {:ok, %{status_code: _, body: body, headers: _}} ->
        body = Poison.decode!(body)
        error = List.first(body["errors"])
        set_errors!(conn, [error("token", error["message"])])
    end
  end

  defp option(conn, key) do
    default = Keyword.get(default_options(), key)

    conn
    |> options
    |> Keyword.get(key, default)
  end
end
