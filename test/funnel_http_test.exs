defmodule FunnelHttpTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts FunnelHttp.Router.init([])

  test "returns a token in json" do
    conn = conn(:post, "/register")

    # Invoke the plug
    conn = FunnelHttp.Router.call(conn, @opts)

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 201
    {:ok, response} = JSEX.decode(conn.resp_body)
    assert response["token"] != nil
  end
end

