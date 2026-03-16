---
name: roxy
description: Roxy local dev proxy — custom .roxy domains with auto HTTPS for localhost services. Use when setting up local domains, configuring routes, debugging proxy issues, or managing certificates.
disable-model-invocation: true
---
Roxy ist ein lokaler Entwicklungs-Proxy der `.roxy`-Domains mit automatischem HTTPS bereitstellt. Ein Binary, CLI-first, keine Abhaengigkeiten.

**Repository:** https://github.com/rbas/roxy

## Wann diesen Skill verwenden

- Lokale Projekte mit Custom Domains aufsetzen
- HTTPS fuer lokale Entwicklung (OAuth, Webhooks, Stripe)
- Mehrere Services unter einer Domain mit Path-Routing
- Wildcard-Subdomains fuer Multi-Tenant-Apps
- Statische Dateien ueber eine .roxy-Domain servieren
- Roxy-Probleme debuggen (Zertifikate, DNS, Ports)

## Installation

### macOS (Homebrew)

```bash
brew tap rbas/roxy
brew install roxy
```

### Linux (Pre-built Binary)

```bash
curl -LO https://github.com/rbas/roxy/releases/latest/download/roxy-linux-x86_64.tar.gz
tar -xzf roxy-linux-x86_64.tar.gz
sudo mv roxy /usr/local/bin/
```

### Ersteinrichtung (einmalig)

```bash
# Root CA erstellen, DNS konfigurieren, Zertifikat ins System eintragen
sudo roxy install
```

**WICHTIG:** Nach `roxy install` den Browser neu starten — Zertifikate werden erst beim Start geladen.

**Linux mit Snap-Browsern:** Firefox/Chromium via Snap koennen das System-Truststore nicht lesen. Extra-Schritt mit `certutil` noetig (siehe https://github.com/rbas/roxy/blob/main/docs/linux.md).

## Befehle

### Domain registrieren

```bash
# Einfach: eine Domain → ein Port
roxy register myapp.roxy --route "/=3000"

# Mehrere Routes: Frontend + API + Admin
roxy register myapp.roxy \
  --route "/=3000" \
  --route "/api=3001" \
  --route "/admin=8080"

# Wildcard: Base-Domain + alle Subdomains
roxy register myapp.roxy --wildcard --route "/=3000"
# → myapp.roxy, blog.myapp.roxy, api.myapp.roxy ...

# Statische Dateien servieren
roxy register docs.roxy --route "/=/var/www/docs"

# Spezifischer Host (nicht localhost)
roxy register backend.roxy --route "/=192.168.1.50:3000"
```

### Routes verwalten

```bash
roxy route add myapp.roxy /webhooks 9000
roxy route remove myapp.roxy /webhooks
roxy route list myapp.roxy

# Wildcard-Routes
roxy route add --wildcard myapp.roxy /api 3001
roxy route list --wildcard myapp.roxy
```

### Domain entfernen

```bash
roxy unregister myapp.roxy
roxy unregister --wildcard myapp.roxy   # nur Wildcard entfernen
```

### Daemon steuern

```bash
sudo roxy start                # Hintergrund (Standard)
sudo roxy start --foreground   # Vordergrund (zum Debuggen)
sudo roxy stop
sudo roxy restart
sudo roxy reload               # Konfiguration neu laden
roxy status                    # Status anzeigen
```

### Logs

```bash
roxy logs                # Letzte 50 Zeilen
roxy logs -n 100         # Letzte 100 Zeilen
roxy logs -f             # Live verfolgen (wie tail -f)
roxy logs --clear        # Log-Datei leeren
```

### Alle Domains anzeigen

```bash
roxy list
```

### Auto-Start bei Boot

```bash
# macOS
sudo brew services start roxy

# Linux (systemd)
sudo systemctl enable --now roxy
```

## Typische Setups

### Full-Stack App (Frontend + API)

```bash
roxy register myapp.roxy \
  --route "/=3000" \
  --route "/api=3001"
# https://myapp.roxy       → Frontend (z.B. Next.js)
# https://myapp.roxy/api   → Backend (z.B. Express)
```

### Stripe/OAuth Webhooks

```bash
roxy register shop.roxy --route "/=3000" --route "/api=3001"
# Webhook-URL in Stripe: https://shop.roxy/api/webhooks
# Funktioniert lokal mit echtem HTTPS — kein ngrok noetig
```

### Multi-Tenant SaaS (Wildcard)

```bash
roxy register myapp.roxy --wildcard --route "/=3000"
# https://myapp.roxy          → Hauptapp
# https://acme.myapp.roxy     → Tenant "acme"
# https://globex.myapp.roxy   → Tenant "globex"
```

### Mehrere Projekte parallel

```bash
roxy register frontend.roxy --route "/=3000"
roxy register backend.roxy --route "/=8080"
roxy register docs.roxy --route "/=/var/www/docs"
# Alle Domains gleichzeitig erreichbar, kein Port-Konflikt
```

### Docker-Container Zugriff

In `docker-compose.yml`:

```yaml
services:
  myservice:
    extra_hosts:
      - "myservice.roxy:host-gateway"
```

Container kann dann `https://myservice.roxy` erreichen.

## Konfiguration

Konfigurationsdatei: `/etc/roxy/config.toml`

```toml
[daemon]
http_port = 80
https_port = 443
dns_port = 1053
log_level = "info"     # error, warn, info, debug

[domains.myapp-roxy]
domain = "myapp.roxy"
https_enabled = true

[[domains.myapp-roxy.routes]]
path = "/"
target = "127.0.0.1:3000"

[paths]
data_dir = "/etc/roxy"
pid_file = "/var/run/roxy.pid"
log_file = "/var/log/roxy/roxy.log"
certs_dir = "/etc/roxy/certs"
```

## Dateien und Verzeichnisse

```
/etc/roxy/
├── config.toml          # Hauptkonfiguration
├── ca.key               # Root CA Private Key
├── ca.crt               # Root CA Zertifikat
└── certs/
    ├── <domain>.key     # Domain Private Key
    └── <domain>.crt     # Domain Zertifikat

/var/run/roxy.pid        # PID-Datei (wenn Daemon laeuft)
/var/log/roxy/roxy.log   # Log-Datei

# DNS-Konfiguration:
/etc/resolver/roxy                          # macOS
/etc/systemd/resolved.conf.d/roxy.conf      # Linux
```

## Troubleshooting

### Browser zeigt Zertifikatswarnung

→ Browser nach `sudo roxy install` neu starten. Browser cachen Zertifikate beim Start.

→ Linux Snap-Browser: Extra `certutil`-Schritt noetig.

### "Connection Refused"

```bash
roxy status                    # Laeuft der Daemon?
sudo roxy start                # Falls nicht
dig myapp.roxy                 # DNS pruefen (macOS)
resolvectl query myapp.roxy    # DNS pruefen (Linux)
```

### Port bereits belegt

```bash
sudo lsof -i :80    # Wer nutzt Port 80?
sudo lsof -i :443   # Wer nutzt Port 443?
sudo lsof -i :1053  # Wer nutzt Port 1053?
```

Alternative Ports in `/etc/roxy/config.toml` konfigurieren.

### Zertifikat zeigt falschen Domainnamen

→ `sudo roxy restart` nach dem Registrieren neuer Domains.

### Debug-Logging aktivieren

```bash
ROXY_LOG=debug sudo roxy start --foreground
```

### Roxy komplett deinstallieren

```bash
sudo roxy uninstall
```

## Proxy-Verhalten

Roxy setzt Standard-Proxy-Header auf jede weitergeleitete Anfrage:

| Header | Wert |
|--------|------|
| `X-Forwarded-Host` | Originaler `Host`-Header |
| `X-Forwarded-Proto` | `http` oder `https` |
| `X-Forwarded-For` | Client-IP |

Hop-by-hop Header (`Connection`, `Keep-Alive`, `Transfer-Encoding` etc.) werden gemaess RFC 7230 entfernt.

## Shell Completions

```bash
roxy completions fish > ~/.config/fish/completions/roxy.fish
roxy completions zsh > ~/.zfunc/_roxy
roxy completions bash > ~/.local/share/bash-completion/completions/roxy
```
