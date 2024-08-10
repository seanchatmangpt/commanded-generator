defmodule Commanded.Generator.Model.SupervisionTree do
  alias __MODULE__

  @type t :: %SupervisionTree{
          name: String.t(),
          module: atom()
        }

  defstruct [:name, :module]

  def new(namespace, name) do
    module = Module.concat([namespace, String.replace(name, " ", "")])

    %SupervisionTree{name: name, module: module}
  end
end
