// Production API configuration for HiFiBerry OS
// This file overrides the development API settings when deployed

// DEVICE_IP = window.location.hostname // Use current hostname in production
// PORT = window.location.port || 80 // Use current port or default to 80
// API runs on the same server at /api path in production

export const DEVICE_IP = window.location.hostname
export const PORT = window.location.port || 80
export const API_PREFIX = '/api'

// In production, API runs on the same server at /api path
export const API_BASE_URL = `${window.location.protocol}//${window.location.host}${API_PREFIX}`
