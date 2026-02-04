FROM nginx:alpine

# Install yq for YAML parsing and dos2unix for line ending conversion
RUN apk add --no-cache yq bash dos2unix

# Copy configuration files
COPY redirects.yaml /etc/nginx/redirects.yaml
COPY generate-nginx-config.sh /docker-entrypoint.d/00-generate-nginx-config.sh

# Fix line endings and make the script executable
RUN dos2unix /docker-entrypoint.d/00-generate-nginx-config.sh && \
    chmod +x /docker-entrypoint.d/00-generate-nginx-config.sh

# Expose port 80
EXPOSE 80

# Use default nginx entrypoint which runs scripts in /docker-entrypoint.d/
