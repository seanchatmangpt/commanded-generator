defmodule Commanded.Generator.Source.Miro.Client do
  @doc """
  Initializes a new client for the Miro API.

  If a JSON file is provided in `opts`, it will be used as the data source
  instead of fetching data from the Miro API.
  """
  def new(opts \\ []) do
    json_file = Keyword.get(opts, :json_file)

    if json_file do
      {:json_file, json_file}
    else
      access_token = Keyword.get(opts, :access_token) || System.get_env("MIRO_ACCESS_TOKEN")
      middleware = [
        {Tesla.Middleware.BaseUrl, "https://api.miro.com/v1"},
        {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{access_token}"}]},
        {Tesla.Middleware.Compression, format: "gzip"},
        Tesla.Middleware.JSON
      ]

      {:client, Tesla.client(middleware)}
    end
  end


  @doc """
  List all widgets.

  If a JSON file was provided during client initialization, this function will
  read from the file instead of making an API request.
  """
  def list_all_widgets(client, board_id \\ nil, query \\ [])

  def list_all_widgets({:json_file, json_file}, _board_id, _query) do
    case File.read(json_file) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, %{"type" => "collection", "data" => data}} ->
            {:ok, data}

          {:ok, _other} ->
            {:error, "Invalid JSON structure in file"}

          {:error, error} ->
            {:error, "Failed to parse JSON: #{error}"}
        end

      {:error, reason} ->
        {:error, "Failed to read JSON file: #{reason}"}
    end
  end

  def list_all_widgets({:client, client}, board_id, query) do
    case Tesla.get(client, "/boards/" <> board_id <> "/widgets/", query: query) do
      {:ok, %Tesla.Env{status: 200, body: %{"type" => "collection", "data" => data}}} ->
        {:ok, data}

      {:ok, %Tesla.Env{body: %{"message" => message}}} ->
        {:error, message}

      {:ok, %Tesla.Env{} = env} ->
        {:error, env}

      reply ->
        reply
    end
  end
end
