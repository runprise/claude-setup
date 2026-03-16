---
name: server-hardening
description: Server absichern (SSH, Fail2Ban, Updates) fuer Coolify/Docker/Traefik-Setups
disable-model-invocation: true
---
Arbeite per SSH auf dem Server und fuehre die folgenden Hardening-Schritte durch.
Der User gibt die SSH-Verbindung als $ARGUMENTS an (z.B. `root@192.168.1.10` oder einen SSH-Config-Host).

Falls kein Argument angegeben: per AskUserQuestion nach dem SSH-Ziel fragen.

## 0. SSH-Verbindung herstellen

Zuerst eine direkte Verbindung versuchen:

```
ssh -o ConnectTimeout=5 <ziel> 'echo OK'
```

Falls die direkte Verbindung fehlschlaegt (Timeout, Connection refused, Network unreachable):
Automatisch ueber den Jump-Host `jumper` verbinden:

```
ssh -o ConnectTimeout=5 -J jumper <ziel> 'echo OK'
```

Falls auch das fehlschlaegt: User informieren und abbrechen.

Fuer alle weiteren Befehle den gleichen Verbindungsweg verwenden:
- Direkt: `ssh <ziel> '<befehl>'`
- Via Jump-Host: `ssh -J jumper <ziel> '<befehl>'`

Vor jedem Schritt kurz zeigen was passiert.

---

## 1. System-Info und Status

```
uname -a && cat /etc/os-release
uptime
df -h
```

- OS-Version und Kernel zeigen
- Pruefen ob Debian/Ubuntu (die folgenden Schritte sind darauf ausgelegt)
- Bei anderem OS den User warnen und fragen ob fortgefahren werden soll

## 2. System aktualisieren

```
apt update && apt upgrade -y
```

## 3. Automatische Sicherheitsupdates

- `unattended-upgrades` installieren und aktivieren:

```
apt install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
```

- Pruefen ob `/etc/apt/apt.conf.d/20auto-upgrades` korrekt konfiguriert ist:

```
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

## 4. SSH absichern

- `/etc/ssh/sshd_config` pruefen und folgende Einstellungen sicherstellen:

```
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
```

- WICHTIG: Vor dem Neustart von sshd sicherstellen dass ein SSH-Key hinterlegt ist (`~/.ssh/authorized_keys` pruefen)
- Falls kein Key vorhanden: User WARNEN und NICHT umstellen - sonst sperrt man sich aus
- `systemctl restart sshd`

## 5. Fail2Ban

```
apt install -y fail2ban
```

- Falls `/etc/fail2ban/jail.local` nicht existiert, erstellen mit:

```
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
```

- `systemctl enable fail2ban && systemctl restart fail2ban`
- Status pruefen: `fail2ban-client status sshd`

## 6. Firewall (UFW)

- WICHTIG: Vor Aktivierung sicherstellen dass SSH erlaubt ist
- Pruefen ob Coolify/Docker-Ports benoetigt werden (80, 443, 8000 fuer Coolify UI)

```
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8000/tcp comment 'Coolify UI'
```

- User fragen ob weitere Ports geoeffnet werden sollen
- `ufw --force enable`
- ACHTUNG: Docker umgeht UFW standardmaessig. Falls Docker installiert ist, darauf hinweisen dass `/etc/docker/daemon.json` mit `"iptables": false` oder UFW-Docker-Workaround noetig sein kann

## 7. Docker und Coolify Check

Falls Docker installiert ist:

- Docker-Version pruefen: `docker --version`
- Pruefen ob Traefik als Reverse-Proxy laeuft: `docker ps | grep traefik`
- Coolify-Status pruefen: `docker ps | grep coolify`
- Pruefen ob Docker-Socket nur fuer root/docker-Gruppe zugaenglich ist
- Docker-Logs auf Fehler pruefen: `docker logs $(docker ps -q --filter name=traefik) --tail 20 2>/dev/null`

## 8. Abschluss-Report

Zusammenfassung als Checkliste zeigen:

- [ ] System aktualisiert
- [ ] Automatische Updates aktiv
- [ ] SSH nur per Key
- [ ] Fail2Ban aktiv
- [ ] Firewall aktiv
- [ ] Docker/Coolify Status geprueft

Bei Problemen konkrete Handlungsempfehlungen geben.
