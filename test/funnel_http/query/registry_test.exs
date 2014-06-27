defmodule FunnelHttp.Query.RegistryTest do
  use ExUnit.Case

  setup do
    on_exit fn ->
      FunnelHttp.Query.Registry.destroy_db
    end
  end

  test "add a new query to registry" do
    metadata = %{name: "New Query", category: "Awesome"}
    assert FunnelHttp.Query.Registry.insert("uuid", metadata) == {:ok, "uuid", metadata}
    assert FunnelHttp.Query.Registry.find("uuid") == {:ok, "uuid", metadata}
    assert FunnelHttp.Query.Registry.delete("uuid") == {:ok, "uuid"}
    assert FunnelHttp.Query.Registry.find("uuid") == {:not_found, "uuid", nil}
  end

  test "do not break" do
    assert FunnelHttp.Query.Registry.find("uuid_not_persisted") == {:not_found, "uuid_not_persisted", nil}
  end
end
