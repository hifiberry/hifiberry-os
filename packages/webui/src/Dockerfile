# Use Node.js 22 Alpine for a clean, lightweight build environment
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Install git (needed to clone the repository)
RUN apk add --no-cache git

# Copy the source code
COPY hbos-ui/ ./

# Copy the custom Vite configuration for UI base path
COPY vite.config.ui.ts ./

# Install dependencies
RUN npm install

# Build the Vue.js application with custom config
RUN npx vite build --config vite.config.ui.ts

# The built files will be in /app/dist/
