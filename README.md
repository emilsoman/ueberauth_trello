# Überauth Trello

> Trello strategy for Überauth.

_Note_: Sessions are required for this strategy.
_Note_: Cloned from Überauth Twitter

## Installation

1. Setup your application at [Trello Developers](https://developers.trello.com).

1. Add `:ueberauth_trello` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_trello, "~> 0.1"},
       {:oauth, github: "tim/erlang-oauth"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_trello]]
    end
    ```

1. Add Trello to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        trello: {Ueberauth.Strategy.Trello, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Trello.OAuth,
      consumer_key: System.get_env("TRELLO_CONSUMER_KEY"),
      consumer_secret: System.get_env("TRELLO_CONSUMER_SECRET")
      name: "My App"
      scope: "read,account"

    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initiate the request through:

    /auth/trello

## License

Please see [LICENSE](https://github.com/wm/ueberauth_trello/blob/master/LICENSE) for licensing details.

