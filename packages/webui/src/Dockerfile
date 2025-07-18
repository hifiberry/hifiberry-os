# Use Node.js 22 Alpine for a clean, lightweight build environment
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Install git (needed to clone the repository)
RUN apk add --no-cache git

# Copy the source code
COPY hbos-ui/ ./

# Install dependencies
RUN npm install

# Build the Vue.js application using the source vite config
RUN npx vite build --config vite.config.ts

# The built files will be in /app/dist/
