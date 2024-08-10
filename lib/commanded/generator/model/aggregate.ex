defmodule Commanded.Generator.Model.Aggregate do
  alias Commanded.Generator.Model.{Command, Event, Field}
  alias __MODULE__

  @type t :: %Aggregate{
          name: String.t(),
          module: atom(),
          fields: list(Field.t()),
          commands: list(Command.t()),
          events: list(Event.t()),
          command_event_map: map()
        }

  defstruct [:name, :module, fields: [], commands: [], events: [], command_event_map: %{}]

  # def add_command_event_mapping(
  #       %Aggregate{} = aggregate,
  #       %Command{name: command_name},
  #       %Event{} = event
  #     ) do
  #   new_map = Map.update(aggregate.command_event_map, command_name, [event], &[event | &1])
  #   %Aggregate{aggregate | command_event_map: new_map}
  # end

  def add_command(%Aggregate{} = aggregate, %Command{} = command) do
    %Aggregate{commands: commands} = aggregate
    %Command{name: name} = command

    commands =
      Enum.reject(commands, fn
        %Command{name: ^name} -> true
        %Command{} -> false
      end)

    %Aggregate{aggregate | commands: Enum.sort_by([command | commands], & &1.name)}
  end

  def add_event(%Aggregate{} = aggregate, %Event{} = event) do
    %Aggregate{events: events} = aggregate
    %Event{name: name} = event

    events =
      Enum.reject(events, fn
        %Event{name: ^name} -> true
        %Event{} -> false
      end)

    %Aggregate{aggregate | events: Enum.sort_by([event | events], & &1.name)}
  end

  # def get_event_for_command(%Aggregate{command_event_map: map}, command_name) do
  #   Map.get(map, command_name)
  # end
end
