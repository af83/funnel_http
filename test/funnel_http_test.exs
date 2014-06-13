defmodule FunnelHttpTest do
  use ExUnit.Case
  use Plug.Test

  @opts FunnelHttp.Router.init([])

  test "404" do
    conn = conn(:post, "/ohai")
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 404
    assert response["error"] == "Not found"
  end

  test "status" do
    conn = conn(:get, "/status")
    conn = FunnelHttp.Router.call(conn, @opts)
    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 200
    assert response["status"] == 200
  end

  test "returns a token in json" do
    conn = conn(:post, "/register")
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 201
    assert response["token"] != nil
  end

  test "does not allow to create an index without token" do
    conn = conn(:post, "/index", "{\"settings\":\"stuff\"}", headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 400
    assert response["error"] == "Unauthenticated"
  end

  test "allow to create an index with token" do
    Funnel.Es.destroy("funnel")
    conn = conn(:post, "/index?token=index_creation", [], headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 200
    assert response["index_id"] != nil
    Funnel.Es.destroy("funnel")
  end

  test "allow to create an index with token, and settings forwarding" do
    Funnel.Es.destroy("funnel")
    settings = '{"settings" : {"number_of_shards" : 1},"mappings" : {"type1" : {"_source" : { "enabled" : false },"properties" : {"field1" : { "type" : "string", "index" : "not_analyzed" }}}}}' |> IO.iodata_to_binary
    conn = conn(:post, "/index?token=index_creation", settings, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 200
    assert response["index_id"] != nil
    Funnel.Es.destroy("funnel")
  end
end
