# HiFiBerry Bluetooth Audio REST API Documentation

## Overview

The HiFiBerry Bluetooth Audio REST API provides a web-based interface for managing Bluetooth audio functionality on HiFiBerry systems. The API allows remote control of Bluetooth pairing, device management, audio configuration, and system status monitoring.

**Base URL:** `http://<hifiberry-ip>:1082/api`

**Content Type:** `application/json`

**CORS:** Enabled for cross-origin requests

## Authentication

Currently, no authentication is required. The API is designed for use in trusted network environments.

## Error Handling

All endpoints return JSON responses with the following structure:

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional success message"
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error description"
}
```

### HTTP Status Codes
- `200` - Success
- `400` - Bad Request (invalid parameters)
- `404` - Endpoint not found
- `500` - Internal server error

## API Endpoints

### System Status

#### Get Bluetooth Adapter Status
```http
GET /api/status
```

Returns comprehensive information about the Bluetooth adapter and system state.

**Response:**
```json
{
  "success": true,
  "adapter": {
    "address": "B8:27:EB:XX:XX:XX",
    "name": "HiFiBerry Audio",
    "powered": true,
    "discoverable": false,
    "pairable": true
  },
  "pairing": {
    "has_pin": true,
    "pin": "1234"
  }
}
```

**Response Fields:**
- `adapter.address` - MAC address of Bluetooth adapter
- `adapter.name` - Human-readable device name
- `adapter.powered` - Whether Bluetooth is powered on
- `adapter.discoverable` - Whether device is visible to other devices
- `adapter.pairable` - Whether device accepts pairing requests
- `pairing.has_pin` - Whether a PIN is configured
- `pairing.pin` - Current PIN code (only returned if configured)

### Audio Configuration

#### Check Audio Backend Status
```http
GET /api/audio/check
```

Returns information about the audio system backend.

**Response:**
```json
{
  "success": true,
  "pipewire_running": true,
  "wireplumber_running": true,
  "pulseaudio_running": false,
  "backend": "pipewire"
}
```

**Response Fields:**
- `pipewire_running` - Whether PipeWire daemon is active
- `wireplumber_running` - Whether WirePlumber session manager is active
- `pulseaudio_running` - Whether PulseAudio daemon is active
- `backend` - Active audio backend (`pipewire`, `pulseaudio`, or `none`)

#### Setup Audio Profiles
```http
POST /api/audio/setup
```

Configures Bluetooth audio profiles (A2DP sink, AVRCP) for optimal audio streaming.

**Response:**
```json
{
  "success": true,
  "message": "Audio profiles configured successfully"
}
```

### PIN Management

#### Get Current PIN
```http
GET /api/pairing/pin
```

Returns the currently configured PIN code.

**Response:**
```json
{
  "success": true,
  "pin": "1234",
  "has_pin": true
}
```

#### Generate Random PIN
```http
POST /api/pairing/pin/generate
```

Generates and saves a new random 4-digit PIN code.

**Response:**
```json
{
  "success": true,
  "pin": "5678",
  "message": "Random PIN generated and saved"
}
```

#### Set Custom PIN
```http
POST /api/pairing/pin/set
```

Sets a custom PIN code for Bluetooth pairing.

**Request Body:**
```json
{
  "pin": "1234"
}
```

**Parameters:**
- `pin` (string, required) - 4-8 digit numeric PIN code

**Response:**
```json
{
  "success": true,
  "pin": "1234",
  "message": "PIN saved successfully"
}
```

**Validation:**
- PIN must be numeric
- PIN must be 4-8 digits long
- PIN is stored in `/etc/hifiberry/btaudio.conf`

### Discoverable Mode

#### Make Device Discoverable
```http
POST /api/discoverable/start
```

Makes the Bluetooth adapter visible to other devices for pairing.

**Request Body:**
```json
{
  "timeout": 120
}
```

**Parameters:**
- `timeout` (integer, optional) - Discoverable timeout in seconds (0 = infinite, default: 0)

**Response:**
```json
{
  "success": true,
  "message": "System is now discoverable",
  "timeout": 120
}
```

#### Hide from Discovery
```http
POST /api/discoverable/stop
```

Hides the Bluetooth adapter from discovery by other devices.

**Response:**
```json
{
  "success": true,
  "message": "System is no longer discoverable"
}
```

### Device Management

#### List Paired Devices
```http
GET /api/devices/paired
```

Returns a list of all paired Bluetooth devices.

**Response:**
```json
{
  "success": true,
  "devices": [
    {
      "path": "/org/bluez/hci0/dev_XX_XX_XX_XX_XX_XX",
      "address": "XX:XX:XX:XX:XX:XX",
      "name": "iPhone",
      "connected": true,
      "trusted": true
    }
  ],
  "count": 1
}
```

**Device Fields:**
- `path` - DBus object path for the device
- `address` - MAC address of the device
- `name` - Human-readable device name
- `connected` - Whether device is currently connected
- `trusted` - Whether device is marked as trusted

#### Remove Specific Device
```http
DELETE /api/devices/{mac_address}
```

Removes (unpairs) a specific device by MAC address.

**Path Parameters:**
- `mac_address` - MAC address in format `XX:XX:XX:XX:XX:XX`

**Response:**
```json
{
  "success": true,
  "message": "Device XX:XX:XX:XX:XX:XX removed successfully"
}
```

#### Remove All Devices
```http
DELETE /api/devices/all
```

Removes (unpairs) all paired devices.

**Response:**
```json
{
  "success": true,
  "message": "All paired devices removed"
}
```

## Web Interface

### HTML Interface
```http
GET /
```

Returns a complete HTML interface for testing and managing the Bluetooth system. The interface includes:

- Real-time system status display
- PIN code management
- Discoverable mode controls
- Audio configuration tools
- Paired device management
- Device removal functions

## Usage Examples

### JavaScript/Browser

```javascript
// Initialize API client
const api = new HiFiBerryBluetoothAPI('http://192.168.1.100:1082');

// Start pairing workflow
async function startPairing() {
    try {
        // Generate PIN and make discoverable
        const pin = await api.generateRandomPin();
        await api.makeDiscoverable(300); // 5 minutes
        
        console.log(`Pairing active with PIN: ${pin.pin}`);
        
        // Monitor devices
        const poller = api.startDevicePolling((error, devices) => {
            if (!error) {
                console.log('Paired devices:', devices.devices);
            }
        });
        
        // Stop after timeout
        setTimeout(() => {
            poller.stop();
            api.hideFromDiscovery();
        }, 300000);
        
    } catch (error) {
        console.error('Pairing error:', error.message);
    }
}

// Check system readiness
async function checkSystem() {
    const status = await api.getStatus();
    const audio = await api.checkAudio();
    
    return {
        ready: status.adapter.powered && audio.backend !== 'none',
        bluetooth: status,
        audio: audio
    };
}
```

### curl Examples

#### Get System Status
```bash
curl -X GET http://192.168.1.100:1082/api/status
```

#### Generate PIN and Make Discoverable
```bash
# Generate PIN
curl -X POST http://192.168.1.100:1082/api/pairing/pin/generate

# Make discoverable for 2 minutes
curl -X POST http://192.168.1.100:1082/api/discoverable/start \
  -H "Content-Type: application/json" \
  -d '{"timeout": 120}'
```

#### Set Custom PIN
```bash
curl -X POST http://192.168.1.100:1082/api/pairing/pin/set \
  -H "Content-Type: application/json" \
  -d '{"pin": "1234"}'
```

#### List and Remove Devices
```bash
# List paired devices
curl -X GET http://192.168.1.100:1082/api/devices/paired

# Remove specific device
curl -X DELETE http://192.168.1.100:1082/api/devices/AA:BB:CC:DD:EE:FF

# Remove all devices
curl -X DELETE http://192.168.1.100:1082/api/devices/all
```

### Python Example

```python
import requests
import json

class HiFiBerryAPI:
    def __init__(self, base_url):
        self.base_url = base_url.rstrip('/')
        self.api_url = f"{self.base_url}/api"
    
    def get_status(self):
        response = requests.get(f"{self.api_url}/status")
        return response.json()
    
    def generate_pin(self):
        response = requests.post(f"{self.api_url}/pairing/pin/generate")
        return response.json()
    
    def make_discoverable(self, timeout=0):
        data = {"timeout": timeout}
        response = requests.post(f"{self.api_url}/discoverable/start", 
                               json=data)
        return response.json()
    
    def get_devices(self):
        response = requests.get(f"{self.api_url}/devices/paired")
        return response.json()

# Usage
api = HiFiBerryAPI('http://192.168.1.100:1082')

# Start pairing
pin_result = api.generate_pin()
discover_result = api.make_discoverable(120)

print(f"Pairing enabled with PIN: {pin_result['pin']}")
print("System discoverable for 2 minutes")
```

## Integration Patterns

### React Component

```jsx
import { useState, useEffect } from 'react';

function BluetoothManager({ hifiberryIP }) {
    const [api] = useState(() => 
        new HiFiBerryBluetoothAPI(`http://${hifiberryIP}:1082`)
    );
    const [status, setStatus] = useState(null);
    const [devices, setDevices] = useState([]);
    
    useEffect(() => {
        const statusPoller = api.startStatusPolling((error, status) => {
            if (!error) setStatus(status);
        });
        
        const devicePoller = api.startDevicePolling((error, devices) => {
            if (!error) setDevices(devices.devices);
        });
        
        return () => {
            statusPoller.stop();
            devicePoller.stop();
        };
    }, [api]);
    
    const startPairing = async () => {
        await api.enablePairing({ timeout: 120 });
    };
    
    return (
        <div>
            <h3>Bluetooth Audio</h3>
            {status && (
                <div>
                    <p>Device: {status.adapter.name}</p>
                    <p>Status: {status.adapter.discoverable ? 'Discoverable' : 'Hidden'}</p>
                    <button onClick={startPairing}>Start Pairing</button>
                </div>
            )}
            <h4>Paired Devices</h4>
            <ul>
                {devices.map(device => (
                    <li key={device.address}>
                        {device.name} - {device.connected ? 'Connected' : 'Paired'}
                    </li>
                ))}
            </ul>
        </div>
    );
}
```

### Vue.js Component

```vue
<template>
    <div class="bluetooth-control">
        <h3>Bluetooth Audio Control</h3>
        <div v-if="status">
            <p>Device: {{ status.adapter.name }}</p>
            <p>Discoverable: {{ status.adapter.discoverable ? 'Yes' : 'No' }}</p>
            <button @click="startPairing">Start Pairing</button>
        </div>
        <div v-if="devices.length">
            <h4>Paired Devices</h4>
            <ul>
                <li v-for="device in devices" :key="device.address">
                    {{ device.name }} - {{ device.connected ? 'Connected' : 'Paired' }}
                </li>
            </ul>
        </div>
    </div>
</template>

<script>
export default {
    props: ['hifiberryIP'],
    data() {
        return {
            api: null,
            status: null,
            devices: []
        };
    },
    mounted() {
        this.api = new HiFiBerryBluetoothAPI(`http://${this.hifiberryIP}:1082`);
        this.startPolling();
    },
    methods: {
        startPolling() {
            this.api.startStatusPolling((error, status) => {
                if (!error) this.status = status;
            });
            
            this.api.startDevicePolling((error, devices) => {
                if (!error) this.devices = devices.devices;
            });
        },
        async startPairing() {
            await this.api.enablePairing({ timeout: 120 });
        }
    }
};
</script>
```

## Configuration

### Service Configuration

The web API service is configured via systemd and can be customized:

```bash
# Edit service configuration
sudo systemctl edit hifiberry-btaudio-web
```

Add custom configuration:
```ini
[Service]
ExecStart=
ExecStart=/usr/bin/btaudio-web-api --host 0.0.0.0 --port 1082

# Custom environment variables
Environment=BLUETOOTH_CONFIG_DIR=/etc/hifiberry
Environment=BLUETOOTH_DATA_DIR=/var/lib/hifiberry-btaudio
```

### File Locations

- **Executable:** `/usr/bin/btaudio-web-api`
- **Config file:** `/etc/hifiberry/btaudio.conf`
- **JavaScript library:** `/usr/share/hifiberry-btaudio/hifiberry-bluetooth-api.js`
- **Example integration:** `/usr/share/hifiberry-btaudio/example-integration.html`
- **Service file:** `/etc/systemd/system/hifiberry-btaudio-web.service`
- **Data directory:** `/var/lib/hifiberry-btaudio/`

### Security Considerations

1. **Network Access:** The API accepts connections from any IP by default
2. **Firewall:** Use `ufw` or `iptables` to restrict access:
   ```bash
   sudo ufw allow from 192.168.1.0/24 to any port 1082
   ```
3. **Reverse Proxy:** For production, use nginx or Apache with HTTPS:
   ```nginx
   location /btaudio/ {
       proxy_pass http://localhost:1082/;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
   }
   ```

### CORS Configuration

The API includes permissive CORS headers by default:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

For production environments, consider restricting origins.

## Troubleshooting

### Common Issues

#### Service Not Starting
```bash
# Check service status
sudo systemctl status hifiberry-btaudio-web

# View logs
sudo journalctl -u hifiberry-btaudio-web -f

# Test manually
sudo /usr/bin/btaudio-web-api --host 127.0.0.1 --port 1082
```

#### Connection Refused
1. Verify service is running: `sudo systemctl status hifiberry-btaudio-web`
2. Check firewall settings: `sudo ufw status`
3. Test local connection: `curl http://localhost:1082/api/status`

#### Bluetooth Errors
1. Ensure Bluetooth service is running: `sudo systemctl status bluetooth`
2. Check adapter presence: `hciconfig`
3. Verify permissions: User must be in `bluetooth` group

#### Permission Errors
```bash
# Add user to bluetooth group
sudo usermod -a -G bluetooth $USER

# Ensure config directory permissions
sudo chown -R root:bluetooth /etc/hifiberry
sudo chmod -R 664 /etc/hifiberry
```

### Debugging API Calls

Enable verbose logging:
```bash
# Run API server with debug output
sudo /usr/bin/btaudio-web-api --host 0.0.0.0 --port 1082 --debug
```

Test endpoints individually:
```bash
# Test each endpoint
curl -v http://localhost:1082/api/status
curl -v http://localhost:1082/api/audio/check
curl -v http://localhost:1082/api/devices/paired
```

## Version Information

- **API Version:** 1.0
- **Protocol:** HTTP/1.1
- **Default Port:** 1082
- **Supported Methods:** GET, POST, DELETE, OPTIONS
- **Response Format:** JSON
- **Character Encoding:** UTF-8

## Support

For additional support and documentation:
- **Project Website:** https://www.hifiberry.com
- **Documentation:** https://www.hifiberry.com/docs/
- **Support Forum:** https://www.hifiberry.com/support/
