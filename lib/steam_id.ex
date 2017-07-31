defmodule SteamId do
  use Application

  defstruct [
    :steam_id, :steam_id3, :steam_id64, :custom_url,
    :profile_state, :profile_created, :name,
    :real_name, :location, :status, :profile
  ]

  def start(_type, _args) do
    SteamId.Supervisor.start_link
  end

  @doc """
  lookup info from steam account info.

  ## Examples

      iex> SteamId.lookup("76561198364102159").__struct__ == SteamId
      true
      iex> SteamId.lookup("4038364311234") == :not_found
      true

  """
  def lookup(content) do
    case SteamId.Server.lookup(content) do
      :not_found ->
        :not_found
      map ->
        %__MODULE__{
          steam_id: map["steamID"],
          steam_id3: map["steamID3"],
          steam_id64: map["steamID64"],
          custom_url: map["customURL"],
          profile_state: map["profile state"],
          profile_created: map["profile created"],
          name: map["name"],
          real_name: map["real name"],
          location: map["location"],
          status: map["status"],
          profile: map["profile"]
        }
    end
  end
end

