defmodule <%= @command_routing_module %> do
  @moduledoc """
  Command routing for <%= @command_routing_name %>.
  """

  use Commanded.Commands.Router

  # Define your command routing here
  # Example:
  # identify <%= @command_module %>, by: :id, prefix: "prefix-"
  # dispatch [<%= @command_name %>], to: <%= @command_module %>

  # Add more routing logic as needed
end

