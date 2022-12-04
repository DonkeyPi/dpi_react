defmodule Sample.App do
  use Application
  require Ash.App

  def start(type, args) do
    Ash.App.log("start #{type}, #{inspect(args)}")

    children = [
      {Sample.Run, []}
    ]

    Supervisor.start_link(
      children,
      strategy: :one_for_one
    )
  end
end
