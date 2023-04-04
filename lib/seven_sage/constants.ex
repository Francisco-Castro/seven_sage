defmodule SevenSage.ConstantMacro do
  @moduledoc """
  Constants across the projet.
  """
  defmacro const(const_name, const_value) do
    quote do
      def unquote(const_name)(), do: unquote(const_value)
    end
  end
end

defmodule SevenSage.Constants do
  alias SevenSage.ConstantMacro
  require ConstantMacro

  ConstantMacro.const(:min_LSAT_score_allowed, 120)
  ConstantMacro.const(:max_LSAT_score_allowed, 180)
end
