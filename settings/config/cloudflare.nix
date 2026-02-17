{
  # Cloudflare Tunnel configuration.
  # Single tunnel for all services (PDS, Matrix, etc.)
  
  # Tunnel UUID from `cloudflared tunnel create server`
  # Replace this after running that command.
  tunnelId = "63ec1b18-1358-4ee2-9093-713b4e7d9325";

  # Ingress routes - maps hostnames to internal services
  # These are configured automatically by service modules (pds.nix, matrix.nix, etc.)
  # but can be overridden here if needed.
}
