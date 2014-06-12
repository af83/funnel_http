defmodule FunnelHttpTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts FunnelHttp.Router.init([])

  test "returns a token in json" do
    conn = conn(:post, "/register")
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 201
    assert response["token"] != nil
  end
end

