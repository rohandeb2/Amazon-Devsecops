# ----------------------------------------
# Stage 1 — Application Build
# Produces optimized static assets
# ----------------------------------------
FROM node:16-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm ci --no-audit --no-fund

COPY . .

RUN npm run build


# ----------------------------------------
# Stage 2 — Runtime Image
# Serves static assets via Nginx
# ----------------------------------------
FROM nginx:alpine

# Remove default configuration
RUN rm -rf /usr/share/nginx/html/*

# Copy build artifacts
COPY --from=build /app/build /usr/share/nginx/html

# Copy custom nginx config (required for SPA routing)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

# Healthcheck for container orchestration
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:80 || exit 1

CMD ["nginx", "-g", "daemon off;"]