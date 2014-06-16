defmodule FunnelHttpTest do
  use ExUnit.Case
  use Plug.Test

  @opts FunnelHttp.Router.init([])

  teardown _context do
    Funnel.Es.destroy("funnel")
    :ok
  end

  test "404" do
    conn = conn(:post, "/ohai")
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 404
    assert conn.assigns[:token] == nil
    assert response["error"] == "Not found"
  end

  test "status" do
    conn = conn(:get, "/status")
    conn = FunnelHttp.Router.call(conn, @opts)
    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.assigns[:token] == nil
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
    assert response["token"] == nil
    assert response["error"] == "Unauthenticated"
  end

  test "allow to create an index with token" do
    Funnel.Es.destroy("funnel")
    conn = conn(:post, "/index?token=index_creation", [], headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)
    index_id = response["index_id"]

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.assigns[:token] != nil
    assert index_id != nil
    Funnel.Es.destroy(index_id)
  end

  test "allow to create an index with token and empty body" do
    Funnel.Es.destroy("funnel")
    conn = conn(:post, "/index?token=index_creation", "", headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)
    index_id = response["index_id"]

    assert conn.state == :sent
    assert conn.status == 200
    assert index_id != nil
    assert conn.assigns[:token] != nil
    Funnel.Es.destroy(index_id)
  end

  test "allow to create an index with token, and settings forwarding" do
    settings = '{"settings" : {"number_of_shards" : 1},"mappings" : {"type1" : {"_source" : { "enabled" : false },"properties" : {"field1" : { "type" : "string", "index" : "not_analyzed" }}}}}' |> IO.iodata_to_binary
    conn = conn(:post, "/index?token=index_creation", settings, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)
    index_id = response["index_id"]

    assert conn.state == :sent
    assert conn.status == 200
    assert index_id != nil
    assert conn.assigns[:token] != nil
    Funnel.Es.destroy(index_id)
  end

  test "allow to destroy an index with token" do
    settings = '{"settings" : {"number_of_shards" : 1},"mappings" : {"type1" : {"_source" : { "enabled" : false },"properties" : {"field1" : { "type" : "string", "index" : "not_analyzed" }}}}}' |> IO.iodata_to_binary
    conn = conn(:post, "/index?token=index_creation", settings, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)
    index_id = response["index_id"]

    conn = conn(:delete, "/index/#{index_id}?token=index_creation")
    conn = FunnelHttp.Router.call(conn, @opts)

    assert conn.assigns[:index_id] == index_id
    assert conn.assigns[:token] != nil
    assert conn.state == :sent
    assert conn.status == 200
    Funnel.Es.destroy(index_id)
  end

  test "does not allow to destroy an index without token" do
    settings = '{"settings" : {"number_of_shards" : 1},"mappings" : {"type1" : {"_source" : { "enabled" : false },"properties" : {"field1" : { "type" : "string", "index" : "not_analyzed" }}}}}' |> IO.iodata_to_binary
    conn = conn(:post, "/index?token=index_creation", settings, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)
    index_id = response["index_id"]

    conn = conn(:delete, "/index/#{index_id}")
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 400
    assert conn.assigns[:token] == nil
    assert response["error"] == "Unauthenticated"
    Funnel.Es.destroy(index_id)
  end

  test "does not allow to create a query without token" do
    query = '{"query" : {"match" : {"message" : "elasticsearch"}}}' |> IO.iodata_to_binary
    conn = conn(:post, "/index/index_id/queries", query, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 400
    assert response["token"] == nil
    assert response["error"] == "Unauthenticated"
  end

  test "allow to create a query with token, and settings forwarding" do
    settings = '{"settings" : {"number_of_shards" : 1},"mappings" : {"type1" : {"_source" : { "enabled" : false },"properties" : {"field1" : { "type" : "string", "index" : "not_analyzed" }}}}}' |> IO.iodata_to_binary
    conn = conn(:post, "/index?token=index_creation", settings, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)
    index_id = response["index_id"]

    query = '{"query" : {"match" : {"message" : "elasticsearch"}}}' |> IO.iodata_to_binary
    conn = conn(:post, "/index/#{index_id}/queries?token=query_creation", query, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 201
    assert response["index_id"] == index_id
    assert response["query_id"] != nil
    assert response["token"] == nil

    Funnel.Es.destroy(index_id)
  end

  test "does not allow to update a query without token" do
    query = '{"query" : {"match" : {"message" : "elasticsearch"}}}' |> IO.iodata_to_binary
    conn = conn(:put, "/index/index_id/queries/:query_id", query, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 400
    assert response["token"] == nil
    assert response["error"] == "Unauthenticated"
  end

  test "allow to update a query with token" do
    settings = '{"settings" : {"number_of_shards" : 1},"mappings" : {"type1" : {"_source" : { "enabled" : false },"properties" : {"field1" : { "type" : "string", "index" : "not_analyzed" }}}}}' |> IO.iodata_to_binary
    conn = conn(:post, "/index?token=index_creation", settings, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)
    index_id = response["index_id"]

    query = '{"query" : {"match" : {"message" : "elasticsearch"}}}' |> IO.iodata_to_binary
    conn = conn(:post, "/index/#{index_id}/queries?token=query_creation", query, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)
    {:ok, response} = JSEX.decode(conn.resp_body)
    query_id = response["query_id"]

    query = '{"query" : {"match" : {"message" : "update"}}}' |> IO.iodata_to_binary
    conn = conn(:put, "/index/#{index_id}/queries/#{query_id}?token=query_creation", query, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)
    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 200
    assert response["index_id"] == index_id
    assert response["query_id"] == query_id
    assert response["token"] == nil

    Funnel.Es.destroy(index_id)
  end

  test "does not allow to destroy a query without token" do
    query = '{"query" : {"match" : {"message" : "elasticsearch"}}}' |> IO.iodata_to_binary
    conn = conn(:delete, "/index/index_id/queries/:query_id", query, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 400
    assert response["token"] == nil
    assert response["error"] == "Unauthenticated"
  end

  test "allow to destroy a query with token" do
    settings = '{"settings" : {"number_of_shards" : 1},"mappings" : {"type1" : {"_source" : { "enabled" : false },"properties" : {"field1" : { "type" : "string", "index" : "not_analyzed" }}}}}' |> IO.iodata_to_binary
    conn = conn(:post, "/index?token=index_creation", settings, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)
    index_id = response["index_id"]

    query = '{"query" : {"match" : {"message" : "elasticsearch"}}}' |> IO.iodata_to_binary
    conn = conn(:post, "/index/#{index_id}/queries?token=query_creation", query, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)
    {:ok, response} = JSEX.decode(conn.resp_body)
    query_id = response["query_id"]

    conn = conn(:delete, "/index/#{index_id}/queries/#{query_id}?token=query_creation", headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)
    {:ok, response} = JSEX.decode(conn.resp_body)

    assert conn.state == :sent
    assert conn.status == 200
    assert response["token"] == nil

    Funnel.Es.destroy(index_id)
  end

  test "submit a document to the percolator" do
    settings = '{"settings" : {"number_of_shards" : 1},"mappings" : {"type1" : {"_source" : { "enabled" : false },"properties" : {"field1" : { "type" : "string", "index" : "not_analyzed" }}}}}' |> IO.iodata_to_binary
    message = "{\"doc\":{\"message\":\"this new elasticsearch percolator feature is nice, borat style\"}}"

    conn = conn(:post, "/index?token=index_creation", settings, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)
    index_id = response["index_id"]

    conn = conn(:post, "/index/#{index_id}/feeding", message, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 204

    Funnel.Es.destroy(index_id)
  end

  test "submit a list of documents to the percolator" do
    settings = '{"settings" : {"number_of_shards" : 1},"mappings" : {"type1" : {"_source" : { "enabled" : false },"properties" : {"field1" : { "type" : "string", "index" : "not_analyzed" }}}}}' |> IO.iodata_to_binary
    messages = "[{\"doc\" : {\"message\":\"So long, and thanks for all the fish\"}},{\"doc\":{\"message\":\"Say thanks to the fish\"}}]"

    conn = conn(:post, "/index?token=index_creation", settings, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    {:ok, response} = JSEX.decode(conn.resp_body)
    index_id = response["index_id"]

    conn = conn(:post, "/index/#{index_id}/feeding", messages, headers: [{"content-type", "application/json"}])
    conn = FunnelHttp.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 204

    Funnel.Es.destroy(index_id)
  end
end
