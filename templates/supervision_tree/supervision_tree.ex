defmodule <%= @supervision_tree_module %> do
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

