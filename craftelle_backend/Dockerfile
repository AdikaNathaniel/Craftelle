# Build stage
FROM node:18-alpine as build

# Install dependencies required for canvas and node-gyp
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    cairo-dev \
    jpeg-dev \
    pango-dev \
    giflib-dev \
    pixman-dev

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev for building)
RUN npm install --legacy-peer-deps

# Copy TypeScript config
COPY tsconfig*.json ./
COPY nest-cli.json* ./

# Copy source code
COPY src ./src

# Build NestJS application
RUN npm run build

# Production stage
FROM node:18-alpine as production

# Runtime shared libraries for canvas (native modules are already compiled in the build stage)
RUN apk add --no-cache \
    cairo \
    jpeg \
    pango \
    giflib \
    pixman

WORKDIR /app

ENV NODE_ENV=production

# Copy package files
COPY package*.json ./

# Copy node_modules from build stage (this includes canvas already built)
COPY --from=build /app/node_modules ./node_modules

# Copy built application from build stage
COPY --from=build /app/dist ./dist

# Render injects PORT (default 10000); the app falls back to 9090 locally
EXPOSE 9090

# Use the production start script from package.json
CMD ["npm", "run", "start:prod"]
