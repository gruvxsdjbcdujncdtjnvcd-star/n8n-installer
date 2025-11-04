# Cloudflare Tunnel Setup Guide

This guide explains how to properly set up Cloudflare Tunnel with the n8n-installer stack.

## Prerequisites

1. Cloudflare account with a domain
2. Cloudflare Tunnel created
3. Tunnel token obtained

## Configuration Steps

### 1. Configure Cloudflare Tunnel

In your Cloudflare Zero Trust dashboard:

1. Go to **Networks → Tunnels**
2. Create or select your tunnel
3. Under **Public Hostname**, add a route:
   - **Public hostname**: `*.yourdomain.com` (wildcard)
   - **Service**:
     - Type: `HTTP`
     - URL: `caddy:80`

### 2. Set Environment Variables

In your `.env` file, set:

```bash
# Cloudflare Tunnel Token (from Cloudflare dashboard)
CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token_here

# Service Hostnames (without https://)
N8N_HOSTNAME=n8n.yourdomain.com
LANGFUSE_HOSTNAME=langfuse.yourdomain.com
QDRANT_HOSTNAME=qdrant.yourdomain.com
SEARXNG_HOSTNAME=searxng.yourdomain.com

# Email for Let's Encrypt (not used with Cloudflare Tunnel, but required by Caddy)
LETSENCRYPT_EMAIL=your@email.com
```

### 3. Start Services

```bash
# Start with Cloudflare Tunnel profile
docker-compose --profile cloudflare-tunnel --profile n8n --profile langfuse --profile qdrant --profile searxng up -d
```

## How It Works

```
Internet → Cloudflare → cloudflared container → Caddy (HTTP:80) → Services
          (HTTPS)       (in Docker network)      (no SSL)
```

### Key Points

1. **SSL termination at Cloudflare**: Cloudflare handles all SSL/TLS certificates
2. **HTTP between cloudflared and Caddy**: No need for SSL inside Docker network
3. **Caddy routes by hostname**: Uses host-based routing to direct traffic
4. **Single network**: All containers share the default bridge network

## Troubleshooting

### Check cloudflared Status

```bash
docker logs cloudflared --tail 50
```

Look for: `Registered tunnel connection`

### Check Caddy Configuration

```bash
docker exec caddy cat /etc/caddy/Caddyfile
docker logs caddy --tail 50
```

### Test Internal Connectivity

```bash
# Test if cloudflared can reach Caddy
docker exec cloudflared wget -O- http://caddy:80 --header="Host: n8n.yourdomain.com" --timeout=5

# Test if Caddy can reach n8n
docker exec caddy wget -O- http://n8n:5678 --timeout=5
```

### Common Issues

#### HTTP 525 Error

**Cause**: SSL handshake failed between Cloudflare and origin

**Solution**: Ensure `auto_https off` is set in Caddyfile (already configured)

#### DNS Resolution Fails

**Cause**: cloudflared can't resolve service names

**Solution**: Ensure cloudflared has `depends_on: caddy` (already configured)

#### Service Not Found

**Cause**: Container names don't match Caddyfile references

**Solution**: Check that:
- `langfuse-web` (not `localai-langfuse-web-1`)
- `n8n` (container_name in docker-compose)
- `qdrant` (container_name in docker-compose)
- `searxng` (container_name in docker-compose)

## Network Architecture

All services run on Docker's default bridge network:
- `caddy`: Reverse proxy listening on port 80
- `cloudflared`: Connects to Cloudflare and routes to caddy:80
- `n8n`, `langfuse-web`, `qdrant`, `searxng`: Backend services

## Security Notes

1. No ports exposed to host (except Caddy's 80/443 for direct access if needed)
2. All external traffic goes through Cloudflare Tunnel
3. SSL/TLS managed by Cloudflare
4. Services only accessible via configured hostnames

## Alternative: Direct SSL Mode

If you want to use direct SSL without Cloudflare Tunnel:

1. Remove `--profile cloudflare-tunnel` from docker-compose command
2. In Caddyfile, replace `auto_https off` with:
   ```
   {
       email {$LETSENCRYPT_EMAIL}
   }
   ```
3. Change hostname-based routing to separate blocks:
   ```
   {$N8N_HOSTNAME} {
       reverse_proxy n8n:5678
   }
   ```
4. Ensure ports 80 and 443 are exposed on your host
