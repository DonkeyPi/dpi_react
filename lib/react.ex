defmodule Ash.React do
  defmacro __using__(opts) do
    case Keyword.get(opts, :app, false) do
      true ->
        quote do
          use Ash.Node
          import Ash.React.Api
          import Ash.React.App, only: [run: 2]
          import Ash.React.Helpers

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

            pid =
              spawn_link(fn ->
                # Pass on driver options.
                :ok = Driver.start(driver, opts)
                # Init is the user defined function that calls run.
                # Returned options are driver specific.
                # TUI drivers have the following mandatory options:
                # - Title
                # - Cols and Rows in characters
                # GUI drivers have the following mandatory options:
                # - Title
                # - Width and Height in pixels
                Driver.opts(driver)
                |> Keyword.put(:driver, driver)
                |> init()

                # Init is the user defined function that must in
                # turn call Ash.React.App.run after adjusting opts.
                # @see samples at app/exs/*.exs
              end)

            {:ok, pid}
          end

          # Use monitor to avoid setting/restoring trap_exit.
          # Use monitor for stop to work from unlinked process.
          def stop(pid, toms \\ 5000) do
            ref = Process.monitor(pid)

            # Attempt a clean stop.
            send(pid, :react_stop)

            # Reliable code should not depend
            # on proper on exit effects cleanup.
            receive do
              {:DOWN, ^ref, :process, ^pid, reason} -> reason
            after
              toms ->
                Process.unlink(pid)
                Process.demonitor(pid, ref)
                Process.exit(pid, :kill)
                :kill
            end
          end

          # Use monitor to avoid setting/restoring trap_exit.
          def run_and_wait(driver, opts) do
            {:ok, pid} =
              Keyword.put(opts, :driver, driver)
              |> start_link()

            ref = Process.monitor(pid)

            receive do
              {:DOWN, ^ref, :process, ^pid, reason} -> reason
              msg -> raise "unexpected #{inspect(msg)}"
            end
          end
        end

      _ ->
        quote do
          use Ash.Node
          import Ash.React.Api
          import Ash.React.Helpers
        end
    end
  end
end
