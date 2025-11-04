#!/bin/bash

set -e

echo "==================================="
echo "Minimal AI Stack Installer"
echo "Services: n8n, Langfuse, Qdrant, SearXNG, Supabase, Cloudflare Tunnel"
echo "==================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root (use sudo)${NC}"
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Install Docker: https://docs.docker.com/engine/install/"
    exit 1
fi

# Check if docker-compose is available
if ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not available${NC}"
    echo "Docker Compose is required (included in Docker 20.10+)"
    exit 1
fi

# Function to generate random string
generate_random() {
    openssl rand -hex 32
}

# Function to generate password hash for Caddy
generate_password_hash() {
    local password=$1
    docker run --rm caddy:2-alpine caddy hash-password --plaintext "$password"
}

# Check if .env exists
if [ -f .env ]; then
    echo -e "${YELLOW}Warning: .env file already exists${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Using existing .env file"
        ENV_EXISTS=1
    fi
fi

if [ -z "$ENV_EXISTS" ]; then
    echo -e "${GREEN}Generating new .env file...${NC}"

    # Copy template
    cp .env.minimal .env

    # Generate secrets
    echo "Generating secure random secrets..."

    POSTGRES_PASSWORD=$(generate_random)
    N8N_ENCRYPTION_KEY=$(generate_random)
    N8N_USER_MANAGEMENT_JWT_SECRET=$(generate_random)
    CLICKHOUSE_PASSWORD=$(generate_random)
    MINIO_ROOT_PASSWORD=$(generate_random)
    LANGFUSE_SALT=$(generate_random)
    NEXTAUTH_SECRET=$(generate_random)
    ENCRYPTION_KEY=$(generate_random)
    JWT_SECRET=$(generate_random)
    QDRANT_API_KEY=$(generate_random)

    # Generate Supabase JWT keys
    echo "Generating Supabase JWT keys..."
    ANON_KEY=$(docker run --rm supabase/gotrue:v2.170.0 gotrue jwt --secret "$JWT_SECRET" --exp 31536000 --iss supabase --aud authenticated --role anon)
    SERVICE_ROLE_KEY=$(docker run --rm supabase/gotrue:v2.170.0 gotrue jwt --secret "$JWT_SECRET" --exp 31536000 --iss supabase --aud authenticated --role service_role)

    # Prompts for user input
    echo ""
    echo -e "${GREEN}Please provide the following information:${NC}"
    echo ""

    read -p "Enter domain for n8n (e.g., n8n.yourdomain.com): " N8N_HOSTNAME
    read -p "Enter domain for Langfuse (e.g., langfuse.yourdomain.com): " LANGFUSE_HOSTNAME
    read -p "Enter domain for Qdrant (e.g., qdrant.yourdomain.com): " QDRANT_HOSTNAME
    read -p "Enter domain for SearXNG (e.g., search.yourdomain.com): " SEARXNG_HOSTNAME
    read -p "Enter domain for Supabase (e.g., supabase.yourdomain.com): " SUPABASE_HOSTNAME

    echo ""
    read -p "Enter Cloudflare Tunnel Token: " CLOUDFLARE_TUNNEL_TOKEN

    echo ""
    read -p "Enter SearXNG username: " SEARXNG_USERNAME
    read -sp "Enter SearXNG password: " SEARXNG_PASSWORD
    echo ""
    SEARXNG_PASSWORD_HASH=$(generate_password_hash "$SEARXNG_PASSWORD")

    echo ""
    read -p "Enter Supabase Dashboard username: " DASHBOARD_USERNAME
    read -sp "Enter Supabase Dashboard password: " DASHBOARD_PASSWORD
    echo ""

    echo ""
    read -p "Enter Langfuse admin email: " LANGFUSE_INIT_USER_EMAIL
    read -sp "Enter Langfuse admin password: " LANGFUSE_INIT_USER_PASSWORD
    echo ""

    LANGFUSE_INIT_PROJECT_PUBLIC_KEY="pk_lf_$(openssl rand -hex 16)"
    LANGFUSE_INIT_PROJECT_SECRET_KEY="sk_lf_$(openssl rand -hex 24)"

    read -p "Enter your email for Let's Encrypt (optional): " LETSENCRYPT_EMAIL
    LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL:-admin@example.com}

    # Update .env file
    sed -i "s|POSTGRES_PASSWORD=|POSTGRES_PASSWORD=$POSTGRES_PASSWORD|" .env
    sed -i "s|N8N_ENCRYPTION_KEY=|N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY|" .env
    sed -i "s|N8N_USER_MANAGEMENT_JWT_SECRET=|N8N_USER_MANAGEMENT_JWT_SECRET=$N8N_USER_MANAGEMENT_JWT_SECRET|" .env
    sed -i "s|CLICKHOUSE_PASSWORD=|CLICKHOUSE_PASSWORD=$CLICKHOUSE_PASSWORD|" .env
    sed -i "s|MINIO_ROOT_PASSWORD=|MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD|" .env
    sed -i "s|LANGFUSE_SALT=|LANGFUSE_SALT=$LANGFUSE_SALT|" .env
    sed -i "s|NEXTAUTH_SECRET=|NEXTAUTH_SECRET=$NEXTAUTH_SECRET|" .env
    sed -i "s|ENCRYPTION_KEY=|ENCRYPTION_KEY=$ENCRYPTION_KEY|" .env
    sed -i "s|JWT_SECRET=|JWT_SECRET=$JWT_SECRET|" .env
    sed -i "s|ANON_KEY=|ANON_KEY=$ANON_KEY|" .env
    sed -i "s|SERVICE_ROLE_KEY=|SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY|" .env
    sed -i "s|QDRANT_API_KEY=|QDRANT_API_KEY=$QDRANT_API_KEY|" .env
    sed -i "s|SEARXNG_USERNAME=|SEARXNG_USERNAME=$SEARXNG_USERNAME|" .env
    sed -i "s|SEARXNG_PASSWORD=|SEARXNG_PASSWORD=$SEARXNG_PASSWORD|" .env
    sed -i "s|SEARXNG_PASSWORD_HASH=|SEARXNG_PASSWORD_HASH=$SEARXNG_PASSWORD_HASH|" .env
    sed -i "s|DASHBOARD_USERNAME=|DASHBOARD_USERNAME=$DASHBOARD_USERNAME|" .env
    sed -i "s|DASHBOARD_PASSWORD=|DASHBOARD_PASSWORD=$DASHBOARD_PASSWORD|" .env
    sed -i "s|N8N_HOSTNAME=|N8N_HOSTNAME=$N8N_HOSTNAME|" .env
    sed -i "s|LANGFUSE_HOSTNAME=|LANGFUSE_HOSTNAME=$LANGFUSE_HOSTNAME|" .env
    sed -i "s|QDRANT_HOSTNAME=|QDRANT_HOSTNAME=$QDRANT_HOSTNAME|" .env
    sed -i "s|SEARXNG_HOSTNAME=|SEARXNG_HOSTNAME=$SEARXNG_HOSTNAME|" .env
    sed -i "s|SUPABASE_HOSTNAME=|SUPABASE_HOSTNAME=$SUPABASE_HOSTNAME|" .env
    sed -i "s|CLOUDFLARE_TUNNEL_TOKEN=|CLOUDFLARE_TUNNEL_TOKEN=$CLOUDFLARE_TUNNEL_TOKEN|" .env
    sed -i "s|LETSENCRYPT_EMAIL=.*|LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL|" .env
    sed -i "s|LANGFUSE_INIT_USER_EMAIL=|LANGFUSE_INIT_USER_EMAIL=$LANGFUSE_INIT_USER_EMAIL|" .env
    sed -i "s|LANGFUSE_INIT_USER_PASSWORD=|LANGFUSE_INIT_USER_PASSWORD=$LANGFUSE_INIT_USER_PASSWORD|" .env
    sed -i "s|LANGFUSE_INIT_PROJECT_PUBLIC_KEY=|LANGFUSE_INIT_PROJECT_PUBLIC_KEY=$LANGFUSE_INIT_PROJECT_PUBLIC_KEY|" .env
    sed -i "s|LANGFUSE_INIT_PROJECT_SECRET_KEY=|LANGFUSE_INIT_PROJECT_SECRET_KEY=$LANGFUSE_INIT_PROJECT_SECRET_KEY|" .env

    echo -e "${GREEN}✓ Configuration file created${NC}"
fi

# Create necessary directories
echo ""
echo "Creating directories..."
mkdir -p searxng n8n/backup shared supabase/volumes/{api,db,logs,functions/main}

# Copy SearXNG config if doesn't exist
if [ ! -f searxng/settings.yml ]; then
    if [ -f searxng/settings-base.yml ]; then
        cp searxng/settings-base.yml searxng/settings.yml
        echo -e "${GREEN}✓ SearXNG configuration created${NC}"
    fi
fi

# Pull images
echo ""
echo -e "${GREEN}Pulling Docker images...${NC}"
docker compose -f docker-compose.minimal.yml pull

# Start services
echo ""
echo -e "${GREEN}Starting services...${NC}"
docker compose -f docker-compose.minimal.yml up -d

# Wait for services to be healthy
echo ""
echo "Waiting for services to start (this may take a few minutes)..."
sleep 10

# Check service status
echo ""
echo -e "${GREEN}Service Status:${NC}"
docker compose -f docker-compose.minimal.yml ps

echo ""
echo "==================================="
echo -e "${GREEN}Installation Complete!${NC}"
echo "==================================="
echo ""
echo "Access your services at:"
echo "  • n8n:      https://$N8N_HOSTNAME"
echo "  • Langfuse: https://$LANGFUSE_HOSTNAME"
echo "  • Qdrant:   https://$QDRANT_HOSTNAME"
echo "  • SearXNG:  https://$SEARXNG_HOSTNAME"
echo "  • Supabase: https://$SUPABASE_HOSTNAME"
echo ""
echo "Credentials:"
echo "  • SearXNG:  $SEARXNG_USERNAME / $SEARXNG_PASSWORD"
echo "  • Supabase: $DASHBOARD_USERNAME / $DASHBOARD_PASSWORD"
echo "  • Langfuse: $LANGFUSE_INIT_USER_EMAIL / $LANGFUSE_INIT_USER_PASSWORD"
echo "  • Qdrant API Key: $QDRANT_API_KEY"
echo ""
echo "  • Supabase ANON_KEY: $ANON_KEY"
echo "  • Supabase SERVICE_ROLE_KEY: $SERVICE_ROLE_KEY"
echo ""
echo "Important: Save these credentials securely!"
echo ""
echo "To view logs: docker compose -f docker-compose.minimal.yml logs -f [service-name]"
echo "To stop: docker compose -f docker-compose.minimal.yml down"
echo "To restart: docker compose -f docker-compose.minimal.yml restart"
echo ""
