defmodule FunnelHttp.Router do
  import Plug.Conn
  use Plug.Router

  plug :match
  plug :dispatch

  get "/status" do
    {:ok, conn}
      |> set_content_type
      |> respond_with(:status)
  end

  post "/register" do
    {:ok, conn}
      |> set_content_type
      |> respond_with(:register)
  end

  post "/index" do
    {:ok, conn}
      |> authenticate
      |> set_content_type
      |> respond_with(:index_creation)
  end

  delete "/index/:index_id" do
    {:ok, assign(conn, :index_id, index_id)}
      |> authenticate
      |> set_content_type
      |> respond_with(:index_destroy)
  end

  post "/index/:index_id/queries" do
    {:ok, assign(conn, :index_id, index_id)}
      |> authenticate
      |> set_content_type
      |> validate(:query)
      |> respond_with(:query_creation)
  end

  get "/index/:index_id/queries" do
    {:ok, assign(conn, :index_id, index_id)}
      |> authenticate
      |> set_content_type
      |> respond_with(:query_find_for_index)
  end

  put "/index/:index_id/queries/:query_id" do
    {:ok, assign(conn, :index_id, index_id) |> assign(:query_id, query_id)}
      |> authenticate
      |> set_content_type
      |> validate(:query)
      |> respond_with(:query_update)
  end

  delete "/index/:index_id/queries/:query_id" do
    {:ok, assign(conn, :index_id, index_id) |> assign(:query_id, query_id)}
      |> authenticate
      |> set_content_type
      |> respond_with(:query_destroy)
  end

  post "/index/:index_id/feeding" do
    {:ok, assign(conn, :index_id, index_id)}
      |> set_content_type
      |> respond_with(:feeding)
  end

  get "/river" do
    {:ok, conn}
      |> authenticate
      |> set_content_type("text/event-streami")
      |> respond_with(:river)
  end

  get "/queries" do
    {:ok, conn}
      |> authenticate
      |> set_content_type
      |> respond_with(:query_find)
  end

  match _ do
    {:ok, conn}
      |> set_content_type
      |> respond_with(:not_found)
  end

  defp set_content_type({result, conn}, content_type \\ "application/json") do
    {result, put_resp_content_type(conn, content_type)}
  end

  defp respond_with({:ok, conn}, status, response) do
    {:ok, body} = JSEX.encode(response)
    log(conn, status)
    send_resp(conn, status, body)
  end

  defp respond_with({:unauthenticated, conn}, _status, _response) do
    response = %{:error => "Unauthenticated"}
    log(conn, 400)
    send_resp(conn, 400, response)
  end

  defp respond_with({:ok, conn}, :status) do
    %{body: body, headers: _headers, status_code: status_code} = Funnel.Es.get("/")
    {:ok, body} = JSEX.decode(body)
    respond_with({:ok, conn}, status_code, body)
  end

  defp respond_with({:ok, conn}, :register) do
    {:ok, token} = Funnel.register conn
    response = %{:token => token}
    respond_with({:ok, conn}, 201, response)
  end

  defp respond_with({:ok, conn}, :index_creation) do
    {:ok, body, conn} = read_body(conn)
    {:ok, status_code, body} = body |> Funnel.Index.create
    respond_with({:ok, conn}, status_code, body)
  end

  defp respond_with({:ok, conn}, :index_destroy) do
    {:ok, status_code, body} = Funnel.Index.destroy(conn.assigns[:index_id])
    respond_with({:ok, conn}, status_code, body)
  end

  defp respond_with({:ok, conn}, :query_creation) do
    {:ok, body} = JSEX.encode(conn.assigns[:payload]["query"])
    {:ok, status_code, body} = Funnel.Query.create(conn.assigns[:index_id], conn.assigns[:token], body)
    {:ok, _id, metadata} = FunnelHttp.Query.Registry.insert(body["query_id"], conn.assigns[:payload]["metadata"])
    body = %{:query_id => body["query_id"], :index_id => body["index_id"], :metadata => metadata}
    respond_with({:ok, conn}, status_code, body)
  end

  defp respond_with({:ok, conn}, :query_update) do
    {:ok, body} = JSEX.encode(conn.assigns[:payload]["query"])
    {:ok, status_code, body} = Funnel.Query.update(conn.assigns[:index_id], conn.assigns[:token], conn.assigns[:query_id], body)
    {:ok, _id, metadata} = FunnelHttp.Query.Registry.insert(body["query_id"], conn.assigns[:payload]["metadata"])
    body = %{:query_id => body["query_id"], :index_id => body["index_id"], :metadata => metadata}
    respond_with({:ok, conn}, status_code, body)
  end

  defp respond_with({:ok, conn}, :query_destroy) do
    {:ok, status_code, body} = Funnel.Query.destroy(conn.assigns[:index_id], conn.assigns[:token], conn.assigns[:query_id])
    FunnelHttp.Query.Registry.delete(conn.assigns[:query_id])
    respond_with({:ok, conn}, status_code, body)
  end

  defp respond_with({:ok, conn}, :feeding) do
    {:ok, body, conn} = read_body(conn)
    Funnel.percolate(conn.assigns[:index_id], body)
    respond_with({:ok, conn}, 204, "")
  end

  defp respond_with({:ok, conn}, :river) do
    conn = send_chunked(conn, 200)
    Funnel.register(conn, conn.assigns[:token], conn.params[:last_id])
    case Mix.env do
      :test -> conn
      _     -> :timer.sleep(:infinity)
    end
  end

  defp respond_with({:ok, conn}, :query_find) do
    {:ok, status_code, body} = Funnel.Query.find(conn.assigns[:token])
    body = serialize_queries(body)
    respond_with({:ok, conn}, status_code, body)
  end

  defp respond_with({:ok, conn}, :query_find_for_index) do
    {:ok, status_code, body} = Funnel.Query.find(conn.assigns[:token], %{index_id: conn.assigns[:index_id]})
    body = serialize_queries(body)
    respond_with({:ok, conn}, status_code, body)
  end

  defp respond_with({:ok, conn}, :not_found) do
    {:ok, response} = JSEX.encode([error: "Not found"])
    send_resp(conn, 404, response)
  end

  defp respond_with({:unauthenticated, conn}, _method) do
    {:ok, response} = JSEX.encode([error: "Unauthenticated"])
    send_resp(conn, 400, response)
  end

  defp respond_with({:invalid, conn, message}, _method) do
    {:ok, response} = JSEX.encode([error: message])
    log(conn, 422)
    send_resp(conn, 422, response)
  end

  defp authenticate({:ok, conn}) do
    conn = Plug.Conn.fetch_params(conn)
    case conn.params["token"] || get_header(conn.req_headers, "authorization") do
      nil   -> {:unauthenticated, conn}
      token -> {:ok, assign(conn, :token, token)}
    end
  end

  defp validate({:ok, conn}, :query) do
    {:ok, body, conn} = read_body(conn)
    {:ok, payload} = JSEX.decode(body)
    case payload["query"] && payload["metadata"] do
      nil -> {:invalid, conn, "`query` and `metadata` keys must be present."}
      _   -> {:ok, assign(conn, :payload, payload)}
    end
  end

  defp validate({:unauthenticated, conn}, _method) do
    {:unauthenticated, conn}
  end

  defp serialize_queries(queries) do
    Enum.map(queries, &serialize_query/1)
  end

  defp serialize_query(query) do
    {:ok, _id, metadata} = FunnelHttp.Query.Registry.find(query["query_id"])
    %{:index_id => query["index_id"], :query_id => query["query_id"], :metadata => metadata}
  end

  defp get_header(headers, key) do
    case List.keyfind(headers, key, 0) do
      {^key, value} -> value
      nil -> nil
    end
  end

  defp log(conn, status) do
    path = Enum.join(conn.path_info, "/")
    date = Timex.Date.now |> Timex.DateFormat.format!("{ISO}")
    IO.inspect("[#{date}] Respond to #{path} with #{status} code")
  end
end
