defmodule Dpi.React.Events do
  defmacro __using__(_) do
    quote do
      @refresh_event {:event, %{type: :sys, key: :print, flag: :none}}
    end
  end
end
