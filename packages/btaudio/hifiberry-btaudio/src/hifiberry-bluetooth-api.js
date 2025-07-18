/**
 * HiFiBerry Bluetooth Audio API Client
 * JavaScript library for interacting with the HiFiBerry Bluetooth Audio Web API
 */

class HiFiBerryBluetoothAPI {
    constructor(baseUrl = 'http://localhost/api/btaudio') {
        this.baseUrl = baseUrl.replace(/\/$/, ''); // Remove trailing slash
        this.apiBase = this.baseUrl + '/api';
    }

    /**
     * Make API request
     * @param {string} endpoint - API endpoint
     * @param {string} method - HTTP method
     * @param {Object} data - Request data
     * @returns {Promise<Object>} API response
     */
    async request(endpoint, method = 'GET', data = null) {
        const url = this.apiBase + endpoint;
        const options = {
            method: method,
            headers: {
                'Content-Type': 'application/json',
            },
        };

        if (data) {
            options.body = JSON.stringify(data);
        }

        try {
            const response = await fetch(url, options);
            const result = await response.json();
            
            if (!response.ok) {
                throw new Error(result.error || `HTTP ${response.status}`);
            }
            
            return result;
        } catch (error) {
            if (error.name === 'TypeError') {
                throw new Error(`Network error: Could not connect to ${this.baseUrl}`);
            }
            throw error;
        }
    }

    // Status and Information
    async getStatus() {
        return this.request('/status');
    }

    async checkAudio() {
        return this.request('/audio/check');
    }

    // PIN Management
    async getCurrentPin() {
        return this.request('/pairing/pin');
    }

    async generateRandomPin() {
        return this.request('/pairing/pin/generate', 'POST');
    }

    async setCustomPin(pin) {
        if (!pin || typeof pin !== 'string' || !/^\d{4,8}$/.test(pin)) {
            throw new Error('PIN must be 4-8 digits');
        }
        return this.request('/pairing/pin/set', 'POST', { pin });
    }

    // Discoverable Mode
    async makeDiscoverable(timeout = 0) {
        return this.request('/discoverable/start', 'POST', { timeout });
    }

    async hideFromDiscovery() {
        return this.request('/discoverable/stop', 'POST');
    }

    // Device Management
    async getPairedDevices() {
        return this.request('/devices/paired');
    }

    async removeDevice(macAddress) {
        if (!macAddress || !/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/.test(macAddress)) {
            throw new Error('Invalid MAC address format');
        }
        return this.request(`/devices/${macAddress}`, 'DELETE');
    }

    async removeAllDevices() {
        return this.request('/devices/all', 'DELETE');
    }

    // Audio Configuration
    async setupAudioProfiles() {
        return this.request('/audio/setup', 'POST');
    }

    // Convenience methods with validation and error handling
    async enablePairing(options = {}) {
        const { pin = null, timeout = 0, setupAudio = true } = options;
        
        try {
            // Setup audio profiles first if requested
            if (setupAudio) {
                await this.setupAudioProfiles();
            }

            // Set PIN if provided
            if (pin) {
                await this.setCustomPin(pin);
            }

            // Make discoverable
            await this.makeDiscoverable(timeout);

            return {
                success: true,
                message: 'Pairing mode enabled successfully',
                timeout: timeout,
                pin: pin
            };
        } catch (error) {
            return {
                success: false,
                error: error.message
            };
        }
    }

    async disablePairing() {
        try {
            await this.hideFromDiscovery();
            return {
                success: true,
                message: 'Pairing mode disabled'
            };
        } catch (error) {
            return {
                success: false,
                error: error.message
            };
        }
    }

    // Event-like methods for real-time updates (polling-based)
    startStatusPolling(callback, interval = 5000) {
        const poll = async () => {
            try {
                const status = await this.getStatus();
                callback(null, status);
            } catch (error) {
                callback(error, null);
            }
        };

        poll(); // Initial call
        const intervalId = setInterval(poll, interval);
        
        return {
            stop: () => clearInterval(intervalId)
        };
    }

    startDevicePolling(callback, interval = 3000) {
        const poll = async () => {
            try {
                const devices = await this.getPairedDevices();
                callback(null, devices);
            } catch (error) {
                callback(error, null);
            }
        };

        poll(); // Initial call
        const intervalId = setInterval(poll, interval);
        
        return {
            stop: () => clearInterval(intervalId)
        };
    }
}

// Export for different module systems
if (typeof module !== 'undefined' && module.exports) {
    // Node.js/CommonJS
    module.exports = HiFiBerryBluetoothAPI;
} else if (typeof define === 'function' && define.amd) {
    // AMD
    define([], () => HiFiBerryBluetoothAPI);
} else {
    // Browser global
    window.HiFiBerryBluetoothAPI = HiFiBerryBluetoothAPI;
}

// Example usage and helper functions
const HiFiBerryHelpers = {
    /**
     * Create a simple pairing interface
     */
    createPairingInterface(containerId, apiBaseUrl) {
        const container = document.getElementById(containerId);
        if (!container) {
            throw new Error(`Container element with ID '${containerId}' not found`);
        }

        const api = new HiFiBerryBluetoothAPI(apiBaseUrl);
        
        container.innerHTML = `
            <div class="hifiberry-bt-interface">
                <h3>Bluetooth Audio Pairing</h3>
                <div class="status-section">
                    <div id="bt-status">Loading...</div>
                </div>
                <div class="pin-section">
                    <label>PIN Code: </label>
                    <input type="text" id="pin-input" placeholder="4-8 digits" maxlength="8">
                    <button id="set-pin-btn">Set PIN</button>
                    <button id="generate-pin-btn">Generate Random</button>
                </div>
                <div class="pairing-section">
                    <button id="start-pairing-btn" class="primary">Start Pairing Mode</button>
                    <button id="stop-pairing-btn">Stop Pairing</button>
                </div>
                <div class="devices-section">
                    <h4>Paired Devices</h4>
                    <div id="devices-list">Loading...</div>
                </div>
            </div>
            <style>
                .hifiberry-bt-interface { font-family: Arial, sans-serif; max-width: 500px; }
                .hifiberry-bt-interface button { padding: 8px 12px; margin: 4px; border: none; border-radius: 4px; cursor: pointer; }
                .hifiberry-bt-interface button.primary { background: #007cba; color: white; }
                .hifiberry-bt-interface button:hover { opacity: 0.8; }
                .hifiberry-bt-interface input { padding: 8px; margin: 4px; border: 1px solid #ddd; border-radius: 4px; }
                .hifiberry-bt-interface .status-section, .pin-section, .pairing-section, .devices-section { margin: 15px 0; padding: 10px; border: 1px solid #eee; border-radius: 4px; }
                .device-item { padding: 8px; margin: 4px 0; background: #f9f9f9; border-radius: 4px; }
            </style>
        `;

        // Event handlers
        document.getElementById('set-pin-btn').onclick = async () => {
            const pin = document.getElementById('pin-input').value;
            try {
                await api.setCustomPin(pin);
                updateStatus();
                document.getElementById('pin-input').value = '';
            } catch (error) {
                alert('Error setting PIN: ' + error.message);
            }
        };

        document.getElementById('generate-pin-btn').onclick = async () => {
            try {
                const result = await api.generateRandomPin();
                updateStatus();
                alert('Generated PIN: ' + result.pin);
            } catch (error) {
                alert('Error generating PIN: ' + error.message);
            }
        };

        document.getElementById('start-pairing-btn').onclick = async () => {
            try {
                await api.enablePairing({ timeout: 120 }); // 2 minutes
                updateStatus();
            } catch (error) {
                alert('Error starting pairing: ' + error.message);
            }
        };

        document.getElementById('stop-pairing-btn').onclick = async () => {
            try {
                await api.disablePairing();
                updateStatus();
            } catch (error) {
                alert('Error stopping pairing: ' + error.message);
            }
        };

        // Update functions
        const updateStatus = async () => {
            try {
                const status = await api.getStatus();
                const statusDiv = document.getElementById('bt-status');
                statusDiv.innerHTML = `
                    <strong>${status.adapter.name}</strong> (${status.adapter.address})<br>
                    Powered: ${status.adapter.powered ? '✓' : '✗'} | 
                    Discoverable: ${status.adapter.discoverable ? '✓' : '✗'} | 
                    PIN: ${status.pairing.has_pin ? '✓' : '✗'}
                `;
            } catch (error) {
                document.getElementById('bt-status').innerHTML = 'Error: ' + error.message;
            }
        };

        const updateDevices = async () => {
            try {
                const result = await api.getPairedDevices();
                const devicesDiv = document.getElementById('devices-list');
                
                if (result.devices.length === 0) {
                    devicesDiv.innerHTML = 'No paired devices';
                } else {
                    devicesDiv.innerHTML = result.devices.map(device => `
                        <div class="device-item">
                            <strong>${device.name}</strong><br>
                            ${device.address} ${device.connected ? '(Connected)' : ''}
                            <button onclick="removeDevice('${device.address}')" style="float: right; background: #dc3545; color: white;">Remove</button>
                        </div>
                    `).join('');
                }
            } catch (error) {
                document.getElementById('devices-list').innerHTML = 'Error: ' + error.message;
            }
        };

        // Global function for remove button
        window.removeDevice = async (address) => {
            if (confirm(`Remove device ${address}?`)) {
                try {
                    await api.removeDevice(address);
                    updateDevices();
                } catch (error) {
                    alert('Error removing device: ' + error.message);
                }
            }
        };

        // Initial load and polling
        updateStatus();
        updateDevices();
        
        setInterval(updateStatus, 5000);
        setInterval(updateDevices, 3000);

        return api;
    }
};

// Also export helpers
if (typeof module !== 'undefined' && module.exports) {
    module.exports.HiFiBerryHelpers = HiFiBerryHelpers;
} else {
    window.HiFiBerryHelpers = HiFiBerryHelpers;
}
