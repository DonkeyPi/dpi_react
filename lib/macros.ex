defmodule Ash.React.Macros do
  defmacro component() do
    quote do
      import Ash.React.Helpers
      import Ash.React.Api
    end
  end

  defmacro app() do
    quote do
      import Ash.React.Helpers
      import Ash.React.Api
      alias Ash.React.App

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
        alias Ash.React.App
        alias Ash.React.Driver
        # Extract mandatory driver from app options.
        {driver, opts} = Keyword.pop!(opts, :driver)
        # Supervisor restart strategy.
        {delay, opts} = Keyword.pop(opts, :delay, 0)
        :timer.sleep(delay)
        {register, opts} = Keyword.pop(opts, :register, false)

        pid =
          spawn_link(fn ->
            # Pass on driver options.
            {:ok, opts} = Driver.start(driver, opts)
            # Init is the user defined function that must in
            # turn call Ash.React.App.run after adjusting opts.
            # @see ash_sample/exs/*.exs
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
