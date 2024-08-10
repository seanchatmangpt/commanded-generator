defmodule Commanded.Generator.Model do
  alias Commanded.Generator.Model.{
    Aggregate,
    Command,
    Event,
    EventHandler,
    ProcessManager,
    Projection,
    SupervisionTree,
    CommandValidation,
    CommandRouting,
    ExternalIntegration
  }

  alias __MODULE__

  @type t :: %Model{
          namespace: atom(),
          aggregates: list(Aggregate.t()),
          events: list(Event.t())
        }

  defstruct [
    :namespace,
    aggregates: [],
    commands: [],
    events: [],
    event_handlers: [],
    process_managers: [],
    projections: [],
    supervision_trees: [],
    command_validations: [],
    command_routings: [],
    external_integrations: []
  ]

  def new(namespace) do
    %Model{namespace: namespace}
  end

  def add_event_handler(%Model{} = model, %EventHandler{} = event_handler) do
    %Model{event_handlers: event_handlers} = model
    %EventHandler{name: name} = event_handler

    event_handlers =
      Enum.reject(event_handlers, fn
        %EventHandler{name: ^name} -> true
        %EventHandler{} -> false
      end)

    %Model{model | event_handlers: Enum.sort_by([event_handler | event_handlers], & &1.name)}
  end

  def add_process_manager(%Model{} = model, %ProcessManager{} = process_manager) do
    %Model{process_managers: process_managers} = model
    %ProcessManager{name: name} = process_manager

    process_managers =
      Enum.reject(process_managers, fn
        %ProcessManager{name: ^name} -> true
        %ProcessManager{} -> false
      end)

    %Model{
      model
      | process_managers: Enum.sort_by([process_manager | process_managers], & &1.name)
    }
  end

  def add_projection(%Model{} = model, %Projection{} = projection) do
    %Model{projections: projections} = model
    %Projection{name: name} = projection

    projections =
      Enum.reject(projections, fn
        %Projection{name: ^name} -> true
        %Projection{} -> false
      end)

    %Model{
      model
      | projections: Enum.sort_by([projection | projections], & &1.name)
    }
  end

  def add_supervision_tree(%Model{} = model, %SupervisionTree{} = supervision_tree) do
    %Model{supervision_trees: supervision_trees} = model
    %SupervisionTree{name: name} = supervision_tree

    supervision_trees =
      Enum.reject(supervision_trees, fn
        %SupervisionTree{name: ^name} -> true
        %SupervisionTree{} -> false
      end)

    %Model{
      model
      | supervision_trees: Enum.sort_by([supervision_tree | supervision_trees], & &1.name)
    }
  end

  def add_command_validation(%Model{} = model, %CommandValidation{} = command_validation) do
    %Model{command_validations: command_validations} = model
    %CommandValidation{name: name} = command_validation

    command_validations =
      Enum.reject(command_validations, fn
        %CommandValidation{name: ^name} -> true
        %CommandValidation{} -> false
      end)

    %Model{
      model
      | command_validations: Enum.sort_by([command_validation | command_validations], & &1.name)
    }
  end

  def add_command_routing(%Model{} = model, %CommandRouting{} = command_routing) do
    %Model{command_routings: command_routings} = model
    %CommandRouting{name: name} = command_routing

    command_routings =
      Enum.reject(command_routings, fn
        %CommandRouting{name: ^name} -> true
        %CommandRouting{} -> false
      end)

    %Model{
      model
      | command_routings: Enum.sort_by([command_routing | command_routings], & &1.name)
    }
  end

  def add_external_integration(%Model{} = model, %ExternalIntegration{} = external_integration) do
    %Model{external_integrations: external_integrations} = model
    %ExternalIntegration{name: name} = external_integration

    external_integrations =
      Enum.reject(external_integrations, fn
        %ExternalIntegration{name: ^name} -> true
        %ExternalIntegration{} -> false
      end)

    %Model{
      model
      | external_integrations: Enum.sort_by([external_integration | external_integrations], & &1.name)
    }
  end


  def find_aggregate(%Model{} = model, name) do
    %Model{aggregates: aggregates} = model

    Enum.find(aggregates, fn
      %Aggregate{name: ^name} -> true
      %Aggregate{} -> false
    end)
  end

  def find_command(%Model{} = model, name) do
    %Model{aggregates: aggregates, commands: commands} = model

    aggregates
    |> Stream.flat_map(fn %Aggregate{commands: commands} -> commands end)
    |> Stream.concat(commands)
    |> Enum.find(fn
      %Command{name: ^name} -> true
      %Command{} -> false
    end)
  end

  def find_event(%Model{} = model, name) do
    %Model{aggregates: aggregates, events: events} = model

    aggregates
    |> Stream.flat_map(fn %Aggregate{events: events} -> events end)
    |> Stream.concat(events)
    |> Enum.find(fn
      %Event{name: ^name} -> true
      %Event{} -> false
    end)
  end

  def find_event_handler(%Model{} = model, name) do
    %Model{event_handlers: event_handlers} = model

    Enum.find(event_handlers, fn
      %EventHandler{name: ^name} -> true
      %EventHandler{} -> false
    end)
  end

  def find_process_manager(%Model{} = model, name) do
    %Model{process_managers: process_managers} = model

    Enum.find(process_managers, fn
      %ProcessManager{name: ^name} -> true
      %ProcessManager{} -> false
    end)
  end

  def find_projection(%Model{} = model, name) do
    %Model{projections: projections} = model

    Enum.find(projections, fn
      %Projection{name: ^name} -> true
      %Projection{} -> false
    end)
  end

  def find_supervision_tree(%Model{} = model, name) do
    %Model{supervision_trees: supervision_trees} = model

    Enum.find(supervision_trees, fn
      %SupervisionTree{name: ^name} -> true
      %SupervisionTree{} -> false
    end)
  end

  def find_command_validation(%Model{} = model, name) do
    %Model{command_validations: command_validations} = model

    Enum.find(command_validations, fn
      %CommandValidation{name: ^name} -> true
      %CommandValidation{} -> false
    end)
  end

  def find_command_routing(%Model{} = model, name) do
    %Model{command_routings: command_routings} = model

    Enum.find(command_routings, fn
      %CommandRouting{name: ^name} -> true
      %CommandRouting{} -> false
    end)
  end

  def find_external_integration(%Model{} = model, name) do
    %Model{external_integrations: external_integrations} = model

    Enum.find(external_integrations, fn
      %ExternalIntegration{name: ^name} -> true
      %ExternalIntegration{} -> false
    end)
  end
end
