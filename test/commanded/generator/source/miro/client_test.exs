defmodule Commanded.Generator.Source.Miro.ClientTest do
  use ExUnit.Case

  alias Commanded.Generator.Source.Miro.Client

  describe "list_all_widgets/3" do
    test "returns widgets when valid JSON file is provided" do
      client = Client.new(json_file: "test/fixtures/miro/boards/widgets/list_all.json")

      assert {:ok, data} = Client.list_all_widgets(client)
      assert length(data) > 0
    end

    test "returns an error when the JSON file does not exist" do
      client = Client.new(json_file: "path/to/non_existent_file.json")

      assert {:error, "Failed to read JSON file: enoent"} = Client.list_all_widgets(client)
    end

    test "returns widgets from API when no JSON file is provided" do
      client = Client.new(access_token: "valid_token")

      # Here you would mock the Tesla.get response
      # Example:
      Tesla.Mock.mock(fn
        %{method: :get, url: "https://api.miro.com/v1/boards/board_id/widgets/"} ->
          %Tesla.Env{status: 200, body: %{"type" => "collection", "data" => [%{"id" => "widget1"}]}}
      end)

      assert {:ok, data} = Client.list_all_widgets(client, "board_id")
      assert length(data) > 0
    end

    test "returns an error when API returns an error message" do
      client = Client.new(access_token: "valid_token")

      # Mock an error response from the API
      Tesla.Mock.mock(fn
        %{method: :get, url: "https://api.miro.com/v1/boards/board_id/widgets/"} ->
          %Tesla.Env{status: 400, body: %{"message" => "Invalid board ID"}}
      end)

      assert {:error, "Invalid board ID"} = Client.list_all_widgets(client, "board_id")
    end
  end
end
