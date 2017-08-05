defmodule SteamId.Server do
  use GenServer

  @url "https://steamid.io/lookup"

  def lookup(contents) when is_list(contents) do
    contents
      |> Enum.map(&(Task.async(fn -> lookup(&1) end)))
      |> Enum.map(&(Task.await(&1)))
      |> Enum.filter(
        fn(result) ->
          case result do
            :not_found ->
              false
            map ->
              map["profile state"] != "unavailable"
          end
        end
      )
  end

  def lookup(content) do
    GenServer.call(__MODULE__, {:lookup, content})
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # callbacks

  def handle_call({:lookup, content}, _from, _state) when bit_size(content) == 0 do
    {:reply, :not_found, []}
  end
  def handle_call({:lookup, content}, _from, _state) do
    request_body = "input=" <> URI.encode_www_form(content)

    headers = [
      "Content-Type": "application/x-www-form-urlencoded"
    ]

    {:ok, %HTTPoison.Response{body: response_body}} = HTTPoison.post(
      @url, request_body, headers, follow_redirect: true
    )

    case Floki.find(response_body, "#content > .panel-body") do
      [] ->
        {:reply, :not_found, []}
      [{_, _, body}] ->
        {:reply, parse(body), []}
    end
  end

  defp parse(body) do
    body
      |> Enum.chunk_every(2)
      |> Enum.reduce(%{}, &fetch_data!/2)
  end

  defp fetch_data!(html_ast, map) do
    [
      {"dt", _, [name]},
      {"dd", _, children_nodes}
    ] = html_ast

    v =
      case children_nodes do
        [_, {"a", _, [value]}] ->
          value
        [{"a", _, [value]}] ->
          value
        [{"span", _, [value]}] ->
          value
        [value] ->
          value
      end

    Map.merge(map, %{name => String.trim(v)})
  end
end
