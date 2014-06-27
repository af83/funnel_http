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
    :dets.open_file(:queries, [file: @dets_file, type: :set])
  end

  def terminate(_reason, queries) do
    :dets.close(queries)
    {:ok}
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

  def handle_call({:insert, uuid, metadata}, _from, queries) do
    {:reply, {:dets.insert(queries, {uuid, metadata}), uuid, metadata}, queries}
  end

  def handle_call({:find, uuid}, _from, queries) do
    lookup = case :dets.lookup(queries, uuid) do
      [{uuid, metadata}] -> {:ok, uuid, metadata}
      []                 -> {:not_found, uuid, nil}
    end
    {:reply, lookup, queries}
  end

  def handle_call({:delete, uuid}, _from, queries) do
    {:reply, {:dets.delete(queries, uuid), uuid}, queries}
  end
end
