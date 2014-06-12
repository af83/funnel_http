defmodule FunnelHttp.Router do
  import Plug.Conn
  use Plug.Router

  plug :match
  plug :dispatch

  post "/register" do
    {:ok, conn}
      |> set_content_type
      |> set_response(:register)
  end

  post "/index" do
    {:ok, conn}
      |> authenticate
      |> set_content_type
      |> set_response(:index_creation)
  end

  match _ do
    {:ok, conn}
      |> set_content_type
      |> set_response(:not_found)
  end

  defp set_content_type({:ok, conn}) do
    {:ok, put_resp_content_type(conn, "application/json")}
  end

  defp set_content_type({:unauthenticated, conn}) do
    {:unauthenticated, put_resp_content_type(conn, "application/json")}
  end

  defp set_response({:ok, conn}, status, response) do
    send_resp(conn, status, response)
  end

  defp set_response({:unauthenticated, conn}, _status, _response) do
    {:ok, response} = JSEX.encode([error: "Unauthenticated"])
    send_resp(conn, 400, response)
  end

  defp set_response({:ok, conn}, :register) do
    token = Funnel.register conn
    {:ok, response} = JSEX.encode([token: token])
    set_response({:ok, conn}, 201, response)
  end

  defp set_response({:ok, conn}, :index_creation) do
    response = case req_body(conn) do
      ""   -> Funnel.Index.create
      body -> Funnel.Index.create(body)
    end

    %{body: body, headers: _headers, status_code: status_code} = response
    set_response({:ok, conn}, status_code, body)
  end

  defp set_response({:ok, conn}, :not_found) do
    {:ok, response} = JSEX.encode([error: "Not found"])
    send_resp(conn, 404, response)
  end

  defp set_response({:unauthenticated, conn}, _method) do
    {:ok, response} = JSEX.encode([error: "Unauthenticated"])
    send_resp(conn, 400, response)
  end

  defp authenticate({:ok, conn}) do
    conn = Plug.Conn.fetch_params(conn)
    case conn.params["token"] do
      nil   -> {:unauthenticated, conn}
      token -> {:ok, conn}
    end
  end

  defp req_body(conn) do
    {_, %{req_body: req_body}} = conn.adapter
    req_body
  end
end
