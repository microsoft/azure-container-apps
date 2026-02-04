FROM nginx:alpine

# Install yq for YAML parsing
RUN apk add --no-cache yq bash

# Copy configuration files
COPY redirects.yaml /etc/nginx/redirects.yaml
COPY generate-nginx-config.sh /docker-entrypoint.d/00-generate-nginx-config.sh

# Make the script executable
RUN chmod +x /docker-entrypoint.d/00-generate-nginx-config.sh

# Expose port 80
EXPOSE 80

# Use default nginx entrypoint which runs scripts in /docker-entrypoint.d/
