defmodule Dpi.React do
  import Dpi.React.Macros

  defmacro __using__(opts) do
    case Keyword.get(opts, :app, false) do
      true -> quote do: app()
      _ -> quote do: component()
    end
  end
end
