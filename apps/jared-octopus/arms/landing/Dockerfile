# syntax=docker/dockerfile:1

# ARM-compatible base — works on Raspberry Pi, Mac M-series, AWS Graviton
FROM --platform=linux/arm64 node:20-alpine

LABEL maintainer="dontriskit"
LABEL description="Submarine landing page — AI-controlled ocean explorer"
LABEL version="0.1.0"

# Create app directory
WORKDIR /app

# Install dependencies first (layer cache)
COPY package.json ./
RUN npm install --omit=dev

# Copy source
COPY src/ ./src/

# Non-root user for security
RUN addgroup -S submarine && adduser -S submarine -G submarine
USER submarine

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

ENV PORT=3000
ENV NODE_ENV=production

CMD ["node", "src/index.js"]
