defmodule Ueberauth.Strategy.Trello.OAuth do
  @moduledoc """
  OAuth1 for Trello.

  Add `consumer_key` and `consumer_secret` to your configuration:

  config :ueberauth, Ueberauth.Strategy.Trello.OAuth,
    consumer_key: System.get_env("TRELLO_CONSUMER_KEY"),
    consumer_secret: System.get_env("TRELLO_CONSUMER_SECRET"),
    redirect_uri: System.get_env("TRELLO_REDIRECT_URI")
    name: "My App"
    name: "read,account"
  """

  alias Ueberauth.Strategy.Trello.OAuth.Internal

  @defaults [access_token: "/1/OAuthGetAccessToken",
             authorize_url: "/1/OAuthAuthorizeToken",
             request_token: "/1/OAuthGetRequestToken",
             site: "https://api.trello.com"]

  def access_token({token, token_secret}, verifier, opts \\ []) do
    opts
    |> client
    |> to_url(:access_token)
    |> Internal.get([{"oauth_verifier", verifier}], consumer(client()), token, token_secret)
    |> decode_response
  end

  def access_token!(access_token, verifier, opts \\ []) do
    case access_token(access_token, verifier, opts) do
      {:ok, token} -> token
      {:error, error} -> raise error
    end
  end

  def authorize_url!({token, _token_secret}, opts \\ []) do
    name = if Map.has_key?(client, :name), do: client.name, else: "Set \"name\" in config :ueberauth, Ueberauth.Strategy.Trello.OAuth"
    scope = if Map.has_key?(client, :scope), do: client.scope, else: "read,account"
    opts
    |> client
    |> to_url(:authorize_url, %{"oauth_token" => token, "name" => name, "scope" => scope})
  end

  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, __MODULE__)

    @defaults
    |> Keyword.merge(config)
    |> Keyword.merge(opts)
    |> Enum.into(%{})
  end

  def get(url, access_token), do: get(url, [], access_token)
  def get(url, params, {token, token_secret}) do
    client()
    |> to_url(url)
    |> Internal.get(params, consumer(client()), token, token_secret)
  end

  def request_token(params \\ [], opts \\ []) do
    client = client(opts)
    params = [{"oauth_callback", client.redirect_uri} | params]

    client
    |> to_url(:request_token)
    |> Internal.get(params, consumer(client))
    |> decode_response
  end

  def request_token!(params \\ [], opts \\ []) do
    case request_token(params, opts) do
      {:ok, token} -> token
      {:error, error} -> raise error
    end
  end

  defp consumer(client), do: {client.consumer_key, client.consumer_secret, :hmac_sha1}

  defp decode_response({:ok, %{status_code: 200, body: body, headers: _}}) do
    params = Internal.params_decode(body)
    token = Internal.token(params)
    token_secret = Internal.token_secret(params)

    {:ok, {token, token_secret}}
  end
  defp decode_response({:ok, %{status_code: status_code, body: body, headers: _}}) do
    {:error, "#{status_code}: #{body}"}
  end
  defp decode_response({:ok, %{status_code: status_code, body: _, headers: _}}) do
    {:error, "#{status_code}"}
  end
  defp decode_response({:error, %{reason: reason}}) do
    {:error, "#{reason}"}
  end
  defp decode_response(error) do
    {:error, error}
  end

  defp endpoint("/" <> _path = endpoint, client), do: client.site <> endpoint
  defp endpoint(endpoint, _client), do: endpoint

  defp to_url(client, endpoint, params \\ nil) do
    endpoint =
      client
      |> Map.get(endpoint, endpoint)
      |> endpoint(client)

    endpoint =
      if params do
        endpoint <> "?" <> URI.encode_query(params)
      else
        endpoint
      end

    endpoint
  end
end
