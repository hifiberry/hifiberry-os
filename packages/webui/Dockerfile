# Use Node.js 22 Alpine for a clean, lightweight build environment
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Install git (needed to clone the repository)
RUN apk add --no-cache git

# Copy the source code
COPY hbos-ui/ ./

# Install dependencies and build the Vue.js application
RUN npm install && npm run build

# The built files will be in /app/dist/
