defmodule <%= @external_integration_module %> do
  @moduledoc """
  External integration for <%= @external_integration_name %>.
  """

  defstruct <%= for field <- @fields do %>
    :<%= field.field %><%= if @fields != [field], do: "," %><% end %>
end

