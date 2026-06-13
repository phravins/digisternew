defmodule Digister.BinCleaner do
  use GenServer
  require Logger

  @interval_ms 24 * 60 * 60 * 1000  # 24 hours
  @first_run_ms 60 * 60 * 1000       # 1 hour after start

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init(_) do
    Process.send_after(self(), :run, @first_run_ms)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:run, state) do
    {count, _} = Digister.Registers.purge_expired_bin()
    if count > 0, do: Logger.info("[BinCleaner] Permanently deleted #{count} expired register(s) from bin.")
    Process.send_after(self(), :run, @interval_ms)
    {:noreply, state}
  end
end
