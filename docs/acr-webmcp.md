# ACR Web MCP Server

`acr-webmcp` is a [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server that exposes the HiFiBerry AudioControl (ACR) API as MCP tools. It lets AI assistants like Claude control playback, browse your music library, and manage genre configuration on a HiFiBerry device.

## Installation

The server ships as a Debian package and is included in `hbos-full`:

```bash
sudo apt install hifiberry-acr-webmcp
```

The service runs as a systemd user service and listens on `http://127.0.0.1:13180`. Nginx proxies it at `/api/acr-webmcp/` on port 80.

## Connecting Claude

### Claude Code (CLI)

Add a `.mcp.json` file to your project (or `~/.claude/mcp.json` for global use):

```json
{
  "mcpServers": {
    "hifiberry": {
      "type": "url",
      "url": "http://<device-ip>/api/acr-webmcp/mcp"
    }
  }
}
```

Replace `<device-ip>` with your HiFiBerry device's IP address. The nginx proxy on port 80 is preferred over the direct port 13180 connection, which is localhost-only by default.

### Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "hifiberry": {
      "type": "url",
      "url": "http://<device-ip>/api/acr-webmcp/mcp"
    }
  }
}
```

### Direct HTTP access (port 13180)

Port 13180 binds to localhost only. To expose it on the network, either use the nginx proxy (recommended) or add an SSH tunnel:

```bash
ssh -L 13180:127.0.0.1:13180 user@<device-ip>
```

Then connect to `http://127.0.0.1:13180/mcp`.

### Health check

```bash
curl http://<device-ip>/api/acr-webmcp/health
```

## Available Tools

### Playback

| Tool | Description |
|------|-------------|
| `players_list` | List all players and their capabilities |
| `player_active` | Get the currently active player |
| `now_playing` | Get track info for what's playing now |
| `playback_command` | Send play / pause / stop / next / previous to a player |

### Queue

| Tool | Description |
|------|-------------|
| `player_queue` | Get the current queue for a player |
| `queue_add_track` | Add a track URI to a player's queue |
| `queue_remove_index` | Remove a queue item by position |
| `queue_play_index` | Jump to a queue item by position |
| `queue_clear` | Clear a player's queue |

### Library browsing

| Tool | Description |
|------|-------------|
| `library_players` | List players that have library support |
| `library_info` | Library status for one player |
| `library_albums` | All albums for a player |
| `library_artists` | All artists for a player |
| `library_album_by_id` | Album details and track list by album ID |
| `library_albums_by_artist` | Albums by artist name (supports fuzzy matching) |
| `library_artist_by_name` | Artist details by name (supports fuzzy matching) |
| `library_genres` | All genres in the library |
| `library_albums_by_genre` | Albums filtered by genre |
| `library_artists_by_genre` | Artists filtered by genre |
| `library_categories` | Canonical categories (genres after cleanup/mapping) |
| `library_albums_by_category` | Albums filtered by canonical category |
| `library_artists_by_category` | Artists filtered by canonical category |
| `library_refresh` | Reload library data from the backend |
| `library_update` | Trigger an asynchronous library scan |

### Genre configuration

| Tool | Description |
|------|-------------|
| `genre_config_get` | Effective genre config (system + user merged) |
| `genre_config_user_get` | User-only genre config |
| `genre_mapping_set` | Map a raw genre tag to a canonical name |
| `genre_mapping_delete` | Remove a genre mapping |
| `genre_ignore_add` | Add a genre to the ignore list |
| `genre_ignore_remove` | Remove a genre from the ignore list |

## Example prompts with Claude

Once connected, you can interact with your HiFiBerry in natural language:

**Basic playback**
> "What's playing on my HiFiBerry right now?"
> "Pause the music."
> "Skip to the next track."

**Library browsing**
> "List all albums by Nick Cave in my library."
> "Play the album 'Kind of Blue' by Miles Davis."
> "Show me all Jazz albums in the library."

**Building a queue**
> "Clear the queue and add the three most recent albums by Radiohead."
> "Add the album 'OK Computer' to the queue and start playing."

**Genre cleanup**
> "Show me all the raw genre tags in my library — I want to clean them up."
> "Map the genre 'hip hop' to 'Hip-Hop' and ignore the tag 'seen live'."
> "What genre mappings are currently active?"

## Architecture

```
Claude / AI assistant
      ↓ MCP (HTTP JSON-RPC)
acr-webmcp  (port 13180, proxied via nginx on port 80)
      ↓ REST
AudioControl / ACR  (port 1080)
      ↓
Players: MPD, Librespot, Shairport, Squeezelite, …
```

The MCP server is stateless — each tool call makes one or more REST requests to ACR and returns the result. No authentication is required on the local network.
