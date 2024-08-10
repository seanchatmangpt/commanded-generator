defmodule Commanded.Generator.Model.CommandRouting do
  alias Commanded.Generator.Model.Command
  alias __MODULE__

  @type t :: %CommandRouting{
          name: String.t(),
          module: atom(),
          commands: list(Command.t())
        }

  defstruct [:name, :module, commands: []]

  def new(namespace, name) do
    module = Module.concat([namespace, String.replace(name, " ", "")])

    %CommandRouting{name: name, module: module}
  end

  def add_command(%CommandRouting{} = command_routing, %Command{} = command) do
    %CommandRouting{commands: commands} = command_routing
    %Command{name: name} = command

    commands =
      Enum.reject(commands, fn
        %Command{name: ^name} -> true
        %Command{} -> false
      end)

    %CommandRouting{command_routing | commands: Enum.sort_by([command | commands], & &1.name)}
  end
end

