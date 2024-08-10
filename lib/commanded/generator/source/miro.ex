defmodule Commanded.Generator.Source.Miro do
  alias Commanded.Generator.Model

  alias Commanded.Generator.Model.{
    Aggregate,
    Command,
    Event,
    EventHandler,
    Field,
    ProcessManager,
    Projection,
    SupervisionTree,
    CommandValidation,
    CommandRouting,
    ExternalIntegration
  }

  alias Commanded.Generator.Source
  alias Commanded.Generator.Source.Miro.Client

  @behaviour Source

  def build(opts) do
    namespace = Keyword.fetch!(opts, :namespace)

    # Determine the client based on json_file or board_id
    client =
      if json_file = Keyword.get(opts, :json_file) do
        Client.new(json_file: json_file)
      else
        # board_id = Keyword.fetch!(opts, :board_id)
        Client.new()
      end

    # Fetch widgets and build the model
    with {:ok, widgets} <- fetch_widgets(client, opts) do
      build_model(namespace, widgets)
    end
  end

  defp fetch_widgets(client, opts) do
    if json_file = Keyword.get(opts, :json_file) do
      Client.list_all_widgets(client)
    else
      board_id = Keyword.fetch!(opts, :board_id)
      Client.list_all_widgets(client, board_id)
    end
  end

  defp build_model(namespace, widgets) do
    Model.new(namespace)
    |> include_aggregates(widgets)
    |> include_events(widgets)
    |> include_event_handlers(widgets)
    |> include_process_managers(widgets)
    |> include_projections(widgets)
    # |> include_supervision_trees(widgets)
    # |> include_command_validations(widgets)
    # |> include_command_routings(widgets)
    # |> include_external_integrations(widgets)
    |> then(&{:ok, &1})
  end

  # Include aggregates and their associated commands and events.
  defp include_aggregates(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    widgets
    |> typeof("sticker", &is_a?(&1, :aggregate))
    |> Enum.reduce(model, fn sticker, model ->
      %{"id" => id, "text" => text} = sticker

      {name, fields} = parse_text(text)

      module = Module.concat([namespace, String.replace(name, " ", "")])

      aggregate =
        case Model.find_aggregate(model, name) do
          %Aggregate{} = aggregate ->
            aggregate

          nil ->
            %Aggregate{name: name, module: module, fields: fields}
        end

      aggregate =
        widgets
        |> connected_to(id, "sticker")
        |> Enum.reduce(aggregate, fn sticker, aggregate ->
          cond do
            is_a?(sticker, :command) ->
              %{"text" => text} = sticker

              {name, fields} = parse_text(text)

              command =
                case Model.find_command(model, name) do
                  %Command{} = command -> command
                  nil -> Command.new(Module.concat([module, Commands]), name, fields)
                end

              Aggregate.add_command(aggregate, command)

            is_a?(sticker, :event) ->
              event_aggregate =
                include_aggregate_event(model, aggregate, sticker, widgets, [sticker])

              # Here, map the command to the event
              # Enum.each(aggregate.commands, fn command ->
              #   aggregate = Aggregate.add_command_event_mapping(event_aggregate, command, sticker)
              # end)

              event_aggregate

            true ->
              aggregate
          end
        end)

      %Model{aggregates: aggregates} = model

      aggregates =
        Enum.reject(aggregates, fn
          %Aggregate{name: ^name} -> true
          %Aggregate{} -> false
        end)

      %Model{model | aggregates: Enum.sort_by([aggregate | aggregates], & &1.name)}
    end)
  end

  defp include_aggregate_event(
         %Model{} = model,
         %Aggregate{} = aggregate,
         sticker,
         widgets,
         accumulator
       ) do
    %Aggregate{module: module} = aggregate
    %{"id" => id, "text" => text} = sticker

    {name, fields} = parse_text(text)

    event =
      case Model.find_event(model, name) do
        %Event{} = event -> event
        nil -> Event.new(Module.concat([module, Events]), name, fields)
      end

    aggregate = Aggregate.add_event(aggregate, event)

    # Inclue any events connected to this event
    widgets
    |> connected_to(id, "sticker", &is_a?(&1, :event))
    |> Enum.reject(&Enum.member?(accumulator, &1))
    |> Enum.reduce(aggregate, fn sticker, aggregate ->
      include_aggregate_event(model, aggregate, sticker, widgets, [sticker | accumulator])
    end)
  end

  # Include events which aren't produced by an aggregate.
  defp include_events(%Model{} = model, widgets) do
    %Model{events: events, namespace: namespace} = model

    new_events =
      widgets
      |> typeof("sticker", &is_a?(&1, :event))
      |> Enum.map(fn sticker ->
        %{"text" => text} = sticker

        parse_text(text)
      end)
      |> Enum.reject(fn {name, _fields} ->
        case Model.find_event(model, name) do
          %Event{} -> true
          nil -> false
        end
      end)
      |> Enum.map(fn {name, fields} ->
        namespace = Module.concat([namespace, Events])

        Event.new(namespace, name, fields)
      end)

    %Model{model | events: Enum.sort_by(events ++ new_events, & &1.name)}
  end

  defp include_event_handlers(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    widgets
    |> typeof("sticker", &is_a?(&1, :event_handler))
    |> Enum.reduce(model, fn sticker, model ->
      %{"id" => id, "text" => text} = sticker

      {name, _fields} = parse_text(text)

      module = Module.concat([namespace, Handlers, String.replace(name, " ", "")])

      event_handler =
        case Model.find_event_handler(model, name) do
          %EventHandler{} = event_handler ->
            event_handler

          nil ->
            %EventHandler{name: name, module: module}
        end

      referenced_events = referenced_events(model, widgets, id)

      event_handler =
        Enum.reduce(referenced_events, event_handler, &EventHandler.add_event(&2, &1))

      Model.add_event_handler(model, event_handler)
    end)
  end

  defp include_process_managers(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    widgets
    |> typeof("sticker", &is_a?(&1, :process_manager))
    |> Enum.reduce(model, fn sticker, model ->
      %{"id" => id, "text" => text} = sticker

      {name, _fields} = parse_text(text)

      process_manager =
        case Model.find_process_manager(model, name) do
          %ProcessManager{} = process_manager ->
            process_manager

          nil ->
            module = Module.concat([namespace, Processes, String.replace(name, " ", "")])

            %ProcessManager{name: name, module: module}
        end

      referenced_events = referenced_events(model, widgets, id)

      process_manager =
        Enum.reduce(referenced_events, process_manager, &ProcessManager.add_event(&2, &1))

      Model.add_process_manager(model, process_manager)
    end)
  end

  defp include_projections(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    widgets
    |> typeof("sticker", &is_a?(&1, :projection))
    |> Enum.reduce(model, fn sticker, model ->
      %{"id" => id, "text" => text} = sticker

      {name, fields} = parse_text(text)

      projection =
        case Model.find_projection(model, name) do
          %Projection{} = projection ->
            projection

          nil ->
            module = Module.concat([namespace, Projections, String.replace(name, " ", "")])

            %Projection{name: name, module: module, fields: fields}
        end

      referenced_events = referenced_events(model, widgets, id)

      projection = Enum.reduce(referenced_events, projection, &Projection.add_event(&2, &1))

      Model.add_projection(model, projection)
    end)
  end

  defp include_supervision_trees(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    widgets
    |> typeof("sticker", &is_a?(&1, :supervision_tree))
    |> Enum.reduce(model, fn sticker, model ->
      %{"id" => id, "text" => text} = sticker

      {name} = parse_text(text)

      module = Module.concat([namespace, String.replace(name, " ", "")])

      supervision_tree =
        %SupervisionTree{name: name, module: module}

      Model.add_supervision_tree(model, supervision_tree)
    end)
  end

  defp include_command_validations(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    widgets
    |> typeof("sticker", &is_a?(&1, :command_validation))
    |> Enum.reduce(model, fn sticker, model ->
      %{"id" => id, "text" => text} = sticker

      {name, fields} = parse_text(text)

      module = Module.concat([namespace, String.replace(name, " ", "")])

      command_validation =
        %CommandValidation{name: name, module: module, fields: fields}

      Model.add_command_validation(model, command_validation)
    end)
  end

  defp include_command_routings(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    widgets
    |> typeof("sticker", &is_a?(&1, :command_routing))
    |> Enum.reduce(model, fn sticker, model ->
      %{"id" => id, "text" => text} = sticker

      {name, _fields} = parse_text(text)

      module = Module.concat([namespace, String.replace(name, " ", "")])

      command_routing =
        %CommandRouting{name: name, module: module, commands: []}

      Model.add_command_routing(model, command_routing)
    end)
  end

  defp include_external_integrations(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    widgets
    |> typeof("sticker", &is_a?(&1, :external_integration))
    |> Enum.reduce(model, fn sticker, model ->
      %{"id" => id, "text" => text} = sticker

      {name, fields} = parse_text(text)

      module = Module.concat([namespace, String.replace(name, " ", "")])

      external_integration =
        %ExternalIntegration{name: name, module: module, fields: fields}

      Model.add_external_integration(model, external_integration)
    end)
  end

  defp referenced_events(%Model{} = model, widgets, id) do
    widgets
    |> connected_to(id, "sticker", &is_a?(&1, :event))
    |> Enum.reduce([], fn sticker, acc ->
      %{"text" => text} = sticker

      {name, _fields} = parse_text(text)

      case Model.find_event(model, name) do
        %Event{} = event -> [event | acc]
        nil -> acc
      end
    end)
  end

  defp is_a?(widget, type)
  defp is_a?(%{"style" => %{"backgroundColor" => "#f5d128"}}, :aggregate), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#a6ccf5"}}, :command), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#ff9d48"}}, :event), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#ea94bb"}}, :event_handler), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#be88c7"}}, :process_manager), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#d5f692"}}, :projection), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#8bde72"}}, :supervision_tree), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#82b1ff"}}, :command_validation), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#ff8a80"}}, :command_routing), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#bdbdbd"}}, :external_integration), do: true
  defp is_a?(_widget, _type), do: false

  # Extract the name and optional fields from a sticker's text.
  defp parse_text(text) do
    parsed = Floki.parse_fragment!(text)

    {name_parts, fields} =
      Enum.reduce(parsed, {[], []}, fn
        {"p", _attrs, [text]}, {name_parts, fields} ->
          case Regex.split(~r/^[^A-Za-z]/, text) do
            [_prefix, name] ->
              name = String.trim(name)
              field = String.replace(name, " ", "") |> Macro.underscore() |> String.to_atom()

              {name_parts, fields ++ [%Field{name: name, field: field}]}

            [name] ->
              name = String.trim(name)

              {name_parts ++ [name], fields}
          end

        {_tag_name, _attrs, _child_nodes}, acc ->
          acc
      end)

    name = Enum.join(name_parts, "")

    {name, fields}
  end

  defp find_by_id(widgets, id) do
    Enum.find(widgets, fn
      %{"id" => ^id} -> true
      _widget -> false
    end)
  end

  defp typeof(widgets, type, filter \\ nil) do
    Enum.filter(widgets, fn
      %{"type" => ^type} = widget -> if is_nil(filter), do: true, else: filter.(widget)
      %{"type" => _type} -> false
    end)
  end

  defp connected_to(widgets, id, type, filter \\ nil) do
    widgets
    |> typeof("line")
    |> Enum.flat_map(fn
      %{"startWidget" => %{"id" => ^id}, "endWidget" => %{"id" => end_id}} -> [end_id]
      %{"startWidget" => %{"id" => start_id}, "endWidget" => %{"id" => ^id}} -> [start_id]
      _line -> []
    end)
    |> Enum.map(&find_by_id(widgets, &1))
    |> typeof(type, filter)
  end
end
