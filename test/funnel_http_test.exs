defmodule FunnelHttpTest do
  use ExUnit.Case
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

  test "does not allow to create an index without token" do
    conn = conn(:post, "/index", "{\"settings\":\"stuff\"}", headers: [{"content-type", "text/plain"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 400
    assert response["error"] == "Unauthenticated"
  end

  test "allow to create an index with token" do
    Funnel.Es.destroy("funnel")
    conn = conn(:post, "/index?token=index_creation", headers: [{"content-type", "text/plain"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 200
    assert response["acknowledged"] == true
    Funnel.Es.destroy("funnel")
  end

  test "forwards error" do
    Funnel.Es.destroy("funnel")
    settings = '{"settings" : {"number_of_shards" : 1},"mappings" : {"type1" : {"_source" : { "enabled" : false },"properties" : {"field1" : { "type" : "string", "index" : "not_analyzed" }}}}}'
    conn = conn(:post, "/index?token=index_creation", settings, headers: [{"content-type", "text/plain"}])
    FunnelHttp.Router.call(conn, @opts)

    conn = conn(:post, "/index?token=index_creation", settings, headers: [{"content-type", "text/plain"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 400
    assert response["error"] == "IndexAlreadyExistsException[[funnel_test] already exists]"
    Funnel.Es.destroy("funnel")
  end
end
