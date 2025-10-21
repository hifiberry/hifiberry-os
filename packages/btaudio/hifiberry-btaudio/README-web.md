# HiFiBerry Bluetooth Audio Web Integration

This package provides a complete web-based solution for integrating HiFiBerry Bluetooth audio functionality into web applications.

## Components

### 1. Web API Server (`btaudio-web-api`)
A REST API server that exposes Bluetooth audio functionality via HTTP endpoints.

**Features:**
- Complete REST API for all Bluetooth operations
- Built-in HTML interface for testing and management
- CORS support for web applications
- JSON responses for easy integration
- Secure PIN management

### 2. JavaScript Client Library (`hifiberry-bluetooth-api.js`)
A comprehensive JavaScript library for web applications.

**Features:**
- Promise-based API client
- Built-in error handling and validation
- Polling support for real-time updates
- Helper functions for common operations
- React/Vue/Angular compatible

### 3. Example Integration (`example-integration.html`)
Complete examples showing different integration approaches.

## Quick Start

### Installation

```bash
# Install the web package
sudo apt install hifiberry-btaudio-web

# Start the web service
sudo systemctl start hifiberry-btaudio-web

# Enable auto-start
sudo systemctl enable hifiberry-btaudio-web
```

### Basic Usage

```html
<!DOCTYPE html>
<html>
<head>
    <title>My App</title>
</head>
<body>
    <!-- Simple interface -->
    <div id="bluetooth-control"></div>
    
    <!-- Include the library -->
    <script src="/opt/hifiberry/share/btaudio/hifiberry-bluetooth-api.js"></script>
    
    <script>
        // Create complete interface with one line
        HiFiBerryHelpers.createPairingInterface(
            'bluetooth-control',
            'http://192.168.1.100:8080'  // Your HiFiBerry IP
        );
    </script>
</body>
</html>
```

### Advanced Usage

```javascript
// Custom integration
const btAPI = new HiFiBerryBluetoothAPI('http://192.168.1.100:8080');

// Start pairing workflow
async function startPairing() {
    try {
        // Generate PIN and make discoverable
        const pin = await btAPI.generateRandomPin();
        await btAPI.makeDiscoverable(300); // 5 minutes
        
        alert(`Pairing mode active! PIN: ${pin.pin}`);
        
        // Monitor for new devices
        const poller = btAPI.startDevicePolling((error, devices) => {
            if (!error) {
                updateDeviceList(devices.devices);
            }
        });
        
        // Stop after timeout
        setTimeout(() => {
            poller.stop();
            btAPI.hideFromDiscovery();
        }, 300000);
        
    } catch (error) {
        alert('Error: ' + error.message);
    }
}
```

## API Reference

### REST Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/status` | Get Bluetooth adapter status |
| GET | `/api/pairing/pin` | Get current PIN |
| POST | `/api/pairing/pin/generate` | Generate random PIN |
| POST | `/api/pairing/pin/set` | Set custom PIN |
| POST | `/api/discoverable/start` | Make discoverable |
| POST | `/api/discoverable/stop` | Hide from discovery |
| GET | `/api/devices/paired` | List paired devices |
| DELETE | `/api/devices/{mac}` | Remove specific device |
| DELETE | `/api/devices/all` | Remove all devices |
| GET | `/api/audio/check` | Check audio backend status |
| POST | `/api/audio/setup` | Setup audio profiles |

### JavaScript API

```javascript
const api = new HiFiBerryBluetoothAPI('http://your-hifiberry:8080');

// Status and information
await api.getStatus()
await api.checkAudio()

// PIN management
await api.getCurrentPin()
await api.generateRandomPin()
await api.setCustomPin('1234')

// Discoverable mode
await api.makeDiscoverable(120)  // 2 minutes
await api.hideFromDiscovery()

// Device management
await api.getPairedDevices()
await api.removeDevice('AA:BB:CC:DD:EE:FF')
await api.removeAllDevices()

// Audio configuration
await api.setupAudioProfiles()

// Convenience methods
await api.enablePairing({ pin: '1234', timeout: 120 })
await api.disablePairing()

// Real-time monitoring
const statusPoller = api.startStatusPolling((error, status) => {
    // Handle status updates
});

const devicePoller = api.startDevicePolling((error, devices) => {
    // Handle device list changes
});

// Stop polling
statusPoller.stop();
devicePoller.stop();
```

## Integration Examples

### React Component

```jsx
import { useState, useEffect } from 'react';

function BluetoothControl({ hifiberryIP }) {
    const [api] = useState(() => new HiFiBerryBluetoothAPI(`http://${hifiberryIP}:8080`));
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
    
    const handleStartPairing = async () => {
        try {
            await api.enablePairing({ timeout: 120 });
        } catch (error) {
            alert('Error: ' + error.message);
        }
    };
    
    return (
        <div>
            {status && (
                <div>
                    <h3>{status.adapter.name}</h3>
                    <p>Discoverable: {status.adapter.discoverable ? 'Yes' : 'No'}</p>
                    <button onClick={handleStartPairing}>Start Pairing</button>
                </div>
            )}
            <ul>
                {devices.map(device => (
                    <li key={device.address}>
                        {device.name} ({device.connected ? 'Connected' : 'Paired'})
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
        <div v-if="status">
            <h3>{{ status.adapter.name }}</h3>
            <p>Status: {{ status.adapter.discoverable ? 'Discoverable' : 'Hidden' }}</p>
            <button @click="startPairing">Start Pairing</button>
        </div>
        <ul>
            <li v-for="device in devices" :key="device.address">
                {{ device.name }} ({{ device.connected ? 'Connected' : 'Paired' }})
            </li>
        </ul>
    </div>
</template>

<script>
export default {
    props: ['hifiberryIP'],
    data() {
        return {
            api: null,
            status: null,
            devices: [],
            statusPoller: null,
            devicePoller: null
        };
    },
    mounted() {
        this.api = new HiFiBerryBluetoothAPI(`http://${this.hifiberryIP}:8080`);
        this.startPolling();
    },
    beforeDestroy() {
        this.stopPolling();
    },
    methods: {
        startPolling() {
            this.statusPoller = this.api.startStatusPolling((error, status) => {
                if (!error) this.status = status;
            });
            
            this.devicePoller = this.api.startDevicePolling((error, devices) => {
                if (!error) this.devices = devices.devices;
            });
        },
        stopPolling() {
            if (this.statusPoller) this.statusPoller.stop();
            if (this.devicePoller) this.devicePoller.stop();
        },
        async startPairing() {
            try {
                await this.api.enablePairing({ timeout: 120 });
            } catch (error) {
                alert('Error: ' + error.message);
            }
        }
    }
};
</script>
```

## Configuration

### Service Configuration

The web API service runs on port 8080 by default. To change this:

```bash
sudo systemctl edit hifiberry-btaudio-web
```

Add:
```ini
[Service]
ExecStart=
ExecStart=/opt/hifiberry/bin/btaudio-web-api --host 0.0.0.0 --port 8080
```

### Security

- The API accepts connections from any IP by default
- Use firewall rules to restrict access if needed
- Consider using a reverse proxy with HTTPS for production
- PIN codes are stored securely in `/etc/hifiberry/btaudio.conf`

### CORS

The API includes CORS headers for web application compatibility. For production:

1. Use a reverse proxy (nginx, Apache)
2. Configure specific origins instead of wildcard
3. Use HTTPS for secure connections

## Troubleshooting

### Service Not Starting

```bash
# Check service status
sudo systemctl status hifiberry-btaudio-web

# Check logs
sudo journalctl -u hifiberry-btaudio-web -f

# Test manually
sudo /opt/hifiberry/bin/btaudio-web-api --host 127.0.0.1 --port 8080
```

### Connection Issues

1. Ensure the main btaudio service is running:
   ```bash
   sudo systemctl status hifiberry-btaudio
   ```

2. Check Bluetooth service:
   ```bash
   sudo systemctl status bluetooth
   ```

3. Verify network connectivity:
   ```bash
   curl http://localhost:8080/api/status
   ```

### JavaScript Errors

1. Check CORS configuration
2. Verify the correct IP address and port
3. Ensure the service is accessible from the web application
4. Check browser console for detailed error messages

## Files

- `/opt/hifiberry/bin/btaudio-web-api` - Web API server
- `/opt/hifiberry/share/btaudio/hifiberry-bluetooth-api.js` - JavaScript client library
- `/opt/hifiberry/share/btaudio/example-integration.html` - Integration examples
- `/etc/systemd/system/hifiberry-btaudio-web.service` - SystemD service
- `/etc/hifiberry/btaudio.conf` - Configuration file

## Support

For support and updates, visit: https://www.hifiberry.com/support/
