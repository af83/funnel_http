defmodule FunnelHttp.Router do
  import Plug.Conn
  use Plug.Router

  plug :match
  plug :dispatch

  get "/register" do
    token = Funnel.register conn
    {:ok, response} = JSEX.encode([token: token])

    send_resp(conn, 200, response)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
