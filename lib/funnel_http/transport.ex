defimpl Funnel.Transport, for: Elixir.Plug.Conn do
  import Plug.Conn

  def write(conn, %{:id => id, :item => item}) do
    queries = Enum.map(item[:query_ids], &to_query/1)
    item = %{queries: queries, body: item[:body]}
    {:ok, item} = JSEX.encode(item)

    chunk conn, EventSourceEncoder.encode(id, item)
  end

  defp to_query(id) do
    {:ok, _id, metadata} = FunnelHttp.Query.Registry.find(id)
    %{id: id, metadata: metadata}
  end
end
