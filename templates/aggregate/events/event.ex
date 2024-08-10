defmodule <%= @event_namespace %>.<%= @event_module %> do
  @moduledoc """
  <%= @event_name %> event.
  """

  alias __MODULE__

  @type t :: %<%= @event_module %>{
    <%= @aggregate %>_id: String.t(),
    <%= for field <- @fields do %>
    <%= field.field %>: term()<%= if @fields != [field], do: "," %>
    <% end %>
    version: pos_integer()
  }

  @derive Jason.Encoder
  defstruct [
    :<%= @aggregate %>_id,
    <%= for field <- @fields do %>
    :<%= field.field %><%= if @fields != [field], do: "," %>
    <% end %>
    version: 1,
  ]

  defimpl Commanded.Serialization.JsonDecoder do
    def decode(%<%= @event_module %>{} = event), do: event
  end

  defimpl Commanded.Event.Upcaster do
    def upcast(%<%= @event_module %>{version: 1} = event, _metadata), do: event
  end
end
