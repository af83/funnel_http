defimpl Funnel.Transport, for: Elixir.Plug.Conn do
  import Plug.Conn

  def write(conn, %{:id => id, :item => item}) do
    chunk conn, EventStreamMessage.to_message(id, item)
  end
end
