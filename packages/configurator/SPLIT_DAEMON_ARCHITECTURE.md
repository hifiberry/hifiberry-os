# HiFiBerry Config Server Split Daemon Architecture

## Overview

The HiFiBerry configuration system has been split into two separate daemons to resolve PipeWire permission issues:

1. **Root Daemon** (`config-server`) - Handles system configuration that requires root privileges
2. **User Daemon** (`config-server-user`) - Handles PipeWire operations in user session

## Architecture

```
┌─────────────────────┐    HTTP API     ┌──────────────────────────┐
│   Root Daemon       │ ──────────────> │   User Daemon            │
│   (config-server)   │    (port 1082)  │   (pipewire-daemon)      │
│   Port: 8080        │                 │   Port: 1082             │
│   User: root        │                 │   User: configured user  │
└─────────────────────┘                 └──────────────────────────┘
         │                                          │
         │                                          │
         v                                          v
┌─────────────────────┐                 ┌──────────────────────────┐
│   System Config     │                 │   PipeWire Session       │
│   - Hardware        │                 │   - Volume Control       │
│   - Network         │                 │   - Mixer Operations     │
│   - File System     │                 │   - Balance Control      │
└─────────────────────┘                 └──────────────────────────┘
```

## Component Details

### Root Daemon (config-server)
- **Location**: `/usr/bin/config-server`
- **Service**: `config-server.service` (system service)
- **Port**: 8080 (configurable)
- **Runs as**: root
- **Responsibilities**:
  - System configuration (hardware, network, etc.)
  - File system operations requiring root privileges
  - Package management
  - Proxies PipeWire requests to user daemon

### User Daemon (config-server-user)
- **Location**: `/usr/bin/config-server-user`
- **Service**: `config-server-user.service` (user service)
- **Port**: 1082 (configurable via environment)
- **Runs as**: configured user (from `/etc/hifiberry.user`)
- **Responsibilities**:
  - All PipeWire operations (volume, mixing, balance, etc.)
  - Direct access to user's PipeWire session
  - Simple HTTP API for PipeWire functions

## Setup Instructions

### 1. Install the Package
```bash
# Build and install the updated package
cd /home/matuschd/hifiberry-os/packages/configurator
./build.sh

# Install the package
sudo dpkg -i hifiberry-configurator_*.deb
```

### 2. Configure User for PipeWire
```bash
# Set the user that should run PipeWire operations
echo "matuschd" | sudo tee /etc/hifiberry.user

# Update configserver.json if needed
sudo nano /etc/configserver/configserver.json
```

Add or update the pipewire section:
```json
{
  "pipewire": {
    "user_file": "/etc/hifiberry.user"
  }
}
```

### 3. Enable User Daemon
```bash
# Switch to the configured user
su - matuschd

# Enable and start the user daemon
systemctl --user enable config-server-user.service
systemctl --user start config-server-user.service

# Check status
systemctl --user status config-server-user.service
```

### 4. Start Root Daemon
```bash
# The root daemon should already be enabled and started by the package
sudo systemctl status config-server.service

# If not running, start it
sudo systemctl start config-server.service
```

## API Endpoints

### Root Daemon (Port 8080)
All existing API endpoints remain the same. PipeWire endpoints are transparently proxied to the user daemon.

Examples:
- `GET /api/v1/pipewire/controls` - List volume controls
- `GET /api/v1/pipewire/volume/default` - Get default sink volume
- `POST /api/v1/pipewire/volume/default` - Set default sink volume
- `GET /api/v1/pipewire/monostereo` - Get monostereo mode
- `POST /api/v1/pipewire/balance` - Set balance

### User Daemon (Port 1082) - Internal API
The user daemon exposes its own API but this is primarily for internal communication:

- `GET /api/v1/volume/controls` - List volume controls
- `GET /api/v1/volume/{control}` - Get volume
- `POST /api/v1/volume/{control}` - Set volume
- `GET /api/v1/mixer/monostereo` - Get monostereo mode
- `POST /api/v1/mixer/balance` - Set balance
- `GET /api/v1/health` - Health check

## Environment Variables

### User Daemon
- `PIPEWIRE_DAEMON_PORT` - Port for user daemon (default: 1082)
- `PIPEWIRE_DAEMON_HOST` - Host for user daemon (default: 127.0.0.1)

## Troubleshooting

### Check User Daemon Status
```bash
# As the configured user
systemctl --user status config-server-user.service
journalctl --user -u config-server-user.service -f
```

### Check Communication
```bash
# Test user daemon directly
curl http://127.0.0.1:1082/api/v1/health

# Test via root daemon proxy
curl http://127.0.0.1:8080/api/v1/pipewire/controls
```

### Check PipeWire Access
```bash
# As the configured user, test PipeWire tools
pw-cli ls Node
wpctl status
```

### Check Configuration
```bash
# Verify user configuration
cat /etc/hifiberry.user
cat /etc/configserver/configserver.json
```

## Benefits

1. **Proper PipeWire Access**: User daemon runs in user session with correct permissions
2. **Security**: Root daemon doesn't need PipeWire access or user switching
3. **Isolation**: System configuration and audio operations are properly separated
4. **Maintainability**: Clear separation of concerns between daemons
5. **Backwards Compatibility**: Existing API endpoints continue to work unchanged

## Migration Notes

- Existing installations will continue to work after package upgrade
- The user daemon must be manually enabled for each user who needs PipeWire functionality
- All existing API clients can continue using the same endpoints on the root daemon
- The split is transparent to API consumers