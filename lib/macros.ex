defmodule Dpi.React.Macros do
  defmacro component() do
    quote do
      import Dpi.React.Helpers
      import Dpi.React.Api
    end
  end

  defmacro app() do
    quote do
      import Dpi.React.Helpers
      import Dpi.React.Api
      alias Dpi.React.App

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          restart: :permanent,
          type: :worker,
          shutdown: 500
        }
      end

      def start_link(opts \\ []) do
        alias Dpi.React.App
        alias Dpi.React.Driver
        # Extract mandatory driver from app options.
        {driver, opts} = Keyword.pop!(opts, :driver)
        # Supervisor restart strategy.
        {delay, opts} = Keyword.pop(opts, :delay, 0)
        {register, opts} = Keyword.pop(opts, :register, false)

        pid =
          spawn_link(fn ->
            if delay > 0, do: :timer.sleep(delay)
            # Pass on driver options.
            {:ok, opts} = Driver.start(driver, opts)
            # Init is the user defined function that must in
            # turn call Dpi.React.App.run after adjusting opts.
            # @see dpi_sample/exs/*.exs
            {func, opts} = init(opts)
            App.run(func, opts)
          end)

        if register, do: Process.register(pid, __MODULE__)

        {:ok, pid}
      end

      # For demos only.
      def run_sync(opts) do
        Process.flag(:trap_exit, true)
        {:ok, pid} = start_link(opts)

        receive do
          {:EXIT, ^pid, reason} -> IO.inspect(reason)
          msg -> raise "Unexpected #{inspect(msg)}"
        end
      end
    end
  end
end
