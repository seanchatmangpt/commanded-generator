#!/usr/bin/env fish

# Define base path for the templates
set base_path /Users/sac/dev/commanded-generator/templates

# Create directories
mkdir -p $base_path/supervision_tree
mkdir -p $base_path/command_validation
mkdir -p $base_path/command_routing
mkdir -p $base_path/external_integration

# Create supervision_tree template
echo 'defmodule <%= @supervision_tree_module %> do
  @moduledoc """
  Supervision tree for <%= @supervision_tree_name %>.
  """

  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      # Define workers and child supervisors here
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
' > $base_path/supervision_tree/supervision_tree.ex

# Create command_validation template
echo 'defmodule <%= @command_validation_module %> do
  @moduledoc """
  Command validation for <%= @command_validation_name %>.
  """

  def validate(command) do
    # Add your validation logic here
    :ok
  end
end
' > $base_path/command_validation/command_validation.ex

# Create command_routing template
echo 'defmodule <%= @command_routing_module %> do
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
' > $base_path/command_routing/command_routing.ex

# Create external_integration template
echo 'defmodule <%= @external_integration_module %> do
  @moduledoc """
  External integration for <%= @external_integration_name %>.
  """

  defstruct <%= for field <- @fields do %>
    :<%= field.field %><%= if @fields != [field], do: "," %><% end %>
end
' > $base_path/external_integration/external_integration.ex

# Display a message indicating that the script has run successfully
echo "Templates for Supervision Tree, Command Validation, Command Routing, and External Integration have been created successfully."
