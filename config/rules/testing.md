# E2E / Playwright Testing

## Browser-Auswahl

Es stehen zwei Browser-Backends zur Verfuegung:

- **Chrome** (`playwright`-Tools) — Vollstaendiger Browser mit visuellem Rendering. Verwenden wenn der User "mit Chrome testen" sagt oder visuelle Pruefung/Screenshots noetig sind.
- **Lightpanda** (`playwright-light`-Tools) — Schneller headless Browser ohne grafisches Rendering. Verwenden wenn der User "schnell testen", "mit Lightpanda testen" oder "headless" sagt.

**Default:** Wenn nicht anders angegeben, `playwright-light` (Lightpanda) verwenden — schneller und ressourcenschonender.

Bei Lightpanda sicherstellen, dass der CDP-Server laeuft (wird normalerweise per SessionStart-Hook gestartet). Falls Verbindungsfehler: `~/.local/bin/lightpanda serve --host 127.0.0.1 --port 9222 &` manuell starten.

## Credentials aus `.env.test` lesen

- Vor jedem E2E- oder Playwright-Test: `.env.test` im Projektroot lesen
- Variablen daraus verwenden: `TEST_BASE_URL`, `TEST_USER`, `TEST_PASSWORD` (und weitere projektspezifische)
- Falls `.env.test` nicht existiert: User nach Zugangsdaten fragen und Datei anlegen (Template: `~/.claude/templates/env.test.example`)
- `.env.test` niemals committen
- Bei neuer `.env.test`: pruefen ob `.gitignore` den Eintrag `.env.test` enthaelt, sonst ergaenzen
