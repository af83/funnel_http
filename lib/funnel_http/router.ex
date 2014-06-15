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

  post "/index/:index_id/query" do
    {:ok, assign(conn, :index_id, index_id)}
      |> authenticate
      |> set_content_type
      |> respond_with(:query_creation)
  end

  put "/index/:index_id/query/:query_id" do
    {:ok, assign(conn, :index_id, index_id) |> assign(:query_id, query_id)}
      |> authenticate
      |> set_content_type
      |> respond_with(:query_update)
  end

  delete "/index/:index_id/query/:query_id" do
    {:ok, assign(conn, :index_id, index_id) |> assign(:query_id, query_id)}
      |> authenticate
      |> set_content_type
      |> respond_with(:query_destroy)
  end

  match _ do
    {:ok, conn}
      |> set_content_type
      |> respond_with(:not_found)
  end

  defp set_content_type({result, conn}) do
    {result, put_resp_content_type(conn, "application/json")}
  end

  defp respond_with({:ok, conn}, status, response) do
    send_resp(conn, status, response)
  end

  defp respond_with({:unauthenticated, conn}, _status, _response) do
    {:ok, response} = JSEX.encode([error: "Unauthenticated"])
    send_resp(conn, 400, response)
  end

  defp respond_with({:ok, conn}, :status) do
    %{body: body, headers: _headers, status_code: status_code} = Funnel.Es.get("/")
    respond_with({:ok, conn}, status_code, body)
  end

  defp respond_with({:ok, conn}, :register) do
    token = Funnel.register conn
    {:ok, response} = JSEX.encode([token: token])
    respond_with({:ok, conn}, 201, response)
  end

  defp respond_with({:ok, conn}, :index_creation) do
    {status_code, body} = req_body(conn) |> Funnel.Index.create
    respond_with({:ok, conn}, status_code, body)
  end

  defp respond_with({:ok, conn}, :index_destroy) do
    {status_code, body} = Funnel.Index.destroy(conn.assigns[:index_id])
    respond_with({:ok, conn}, status_code, body)
  end

  defp respond_with({:ok, conn}, :query_creation) do
    {status_code, body} = Funnel.Query.create(conn.assigns[:index_id], conn.assigns[:token], req_body(conn))
    respond_with({:ok, conn}, status_code, body)
  end

  defp respond_with({:ok, conn}, :query_update) do
    {status_code, body} = Funnel.Query.update(conn.assigns[:index_id], conn.assigns[:token], conn.assigns[:query_id], req_body(conn))
    respond_with({:ok, conn}, status_code, body)
  end

  defp respond_with({:ok, conn}, :query_destroy) do
    {status_code, body} = Funnel.Query.destroy(conn.assigns[:index_id], conn.assigns[:token], conn.assigns[:query_id])
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

  defp authenticate({:ok, conn}) do
    conn = Plug.Conn.fetch_params(conn)
    case conn.params["token"] do
      nil   -> {:unauthenticated, conn}
      token -> {:ok, assign(conn, :token, token)}
    end
  end

  defp req_body(conn) do
    {_, %{req_body: req_body}} = conn.adapter
    req_body
  end
end
