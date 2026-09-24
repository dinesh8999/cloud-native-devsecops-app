# Multi-stage secure build for Node.js Application

# ==========================================
# STAGE 1: Dependency Builder
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

# Copy dependency manifests
COPY app/package*.json ./

# Install only production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# ==========================================
# STAGE 2: Hardened Runtime Environment
# ==========================================
FROM node:20-alpine AS runner

# Set metadata labels for container traceability
LABEL org.opencontainers.image.title="Cloud-Native DevSecOps App" \
      org.opencontainers.image.description="Secured container for AWS ECS Fargate deployment" \
      org.opencontainers.image.vendor="DevSecOps Engineering"

WORKDIR /usr/src/app

# Security: Upgrade all packages to patch base image OS CVEs
RUN apk update && \
    apk upgrade --no-cache && \
    rm -rf /var/cache/apk/*

# Security: Set production environment
ENV NODE_ENV=production
ENV PORT=3000

# Copy node_modules from builder stage
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY app/package*.json ./
COPY app/src ./src

# Security: Use standard unprivileged 'node' user provided by official Alpine Node image (UID/GID 1000)
# Ensure files are owned by the unprivileged user
RUN chown -R node:node /usr/src/app

# Switch away from root
USER node

# Expose container port (Port 3000)
EXPOSE 3000

# Health check instruction for local container validation
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start server using node directly (avoid npm wrapper to allow proper signal propagation for SIGTERM)
CMD ["node", "src/server.js"]
