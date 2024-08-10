defmodule Commanded.Generator.Model.CommandValidation do
  alias Commanded.Generator.Model.Field
  alias __MODULE__

  @type t :: %CommandValidation{
          name: String.t(),
          module: atom(),
          fields: list(Field.t())
        }

  defstruct [:name, :module, fields: []]

  def new(namespace, name, fields \\ []) do
    module = Module.concat([namespace, String.replace(name, " ", "")])

    %CommandValidation{name: name, module: module, fields: fields}
  end
end
