defmodule FunnelHttp.Query.Registry do
  use GenServer

  @dets_file Path.expand("db/queries_#{Mix.env}.dets")

  ## Cient API

  @doc """
  Starts the registry.
  """
  def start_link do
    GenServer.start_link(__MODULE__, [], name: QueryRegistry)
  end

  def init([]) do
    {:ok, nil}
  end

  def insert(uuid, metadata) do
    GenServer.call(QueryRegistry, {:insert, uuid, metadata})
  end

  def find(uuid) do
    GenServer.call(QueryRegistry, {:find, uuid})
  end

  def delete(uuid) do
    GenServer.call(QueryRegistry, {:delete, uuid})
  end

  def handle_call({:insert, uuid, metadata}, _from, _) do
    queries = open_db
    :ok = :dets.insert(queries, {uuid, metadata})
    close_db(queries)
    {:reply, {:ok, uuid, metadata}, nil}
  end

  def handle_call({:find, uuid}, _from, _) do
    queries = open_db
    lookup = case :dets.lookup(queries, uuid) do
      [{uuid, metadata}] -> {:ok, uuid, metadata}
      []                 -> {:not_found, uuid, nil}
    end
    {:reply, lookup, nil}
  end

  def handle_call({:delete, uuid}, _from, queries) do
    queries = open_db
    query = :dets.delete(queries, uuid)
    close_db(queries)
    {:reply, {query, uuid}, nil}
  end

  defp close_db(queries) do
    :dets.close(queries)
  end

  defp open_db do
    {:ok, queries} = :dets.open_file(:queries, [file: @dets_file, type: :set])
    queries
  end
end
