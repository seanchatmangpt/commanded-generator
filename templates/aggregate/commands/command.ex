defmodule <%= @command_namespace %>.<%= @command_module %> do
  @moduledoc """
  <%= @command_name %> command.
  """

  alias __MODULE__

  @type t :: %<%= @command_module %>{
    <%= @aggregate %>_id: String.t(),
    <%= for field <- @fields do %>
    <%= field.field %>: term()<%= if @fields != [field], do: "," %>
    <% end %>
  }

  defstruct [
    :<%= @aggregate %>_id<%= if @fields != [], do: "," %>
    <%= for field <- @fields do %>
    :<%= field.field %><%= if @fields != [field], do: "," %><% end %>
  ]
end
