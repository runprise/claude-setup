---
name: n8n-as-code
description: n8n-Workflows als TypeScript erstellen, validieren und synchronisieren mit n8nac CLI
disable-model-invocation: true
---
Erstelle und verwalte n8n-Workflows als typsicheren TypeScript-Code mit dem `n8nac` CLI.

Falls $ARGUMENTS angegeben: als Beschreibung des gewuenschten Workflows verwenden.
Falls kein Argument: per AskUserQuestion fragen was der Workflow tun soll.

---

## Voraussetzungen

- `n8nac` muss installiert sein (`npm install -g n8nac` oder via `npx n8nac`)
- Fuer Sync: `n8nac init` muss im Projekt gelaufen sein (n8nac-config.json vorhanden)
- Fuer reine Workflow-Erstellung: keine n8n-Instanz noetig

## Workflow erstellen

### 1. Recherche - passende Nodes finden

Bevor du einen Workflow schreibst, suche nach den richtigen Nodes und Templates:

```bash
# Nodes suchen
npx --yes n8nac skills search "<beschreibung>"

# Node-Details und Schema abrufen
npx --yes n8nac skills node-info <nodeName>

# Community-Templates als Inspiration
npx --yes n8nac skills examples search "<beschreibung>"

# Template herunterladen und als Referenz nutzen
npx --yes n8nac skills examples download <id> -o reference.workflow.ts
```

### 2. Workflow als TypeScript schreiben

Dateiname: `<workflow-name>.workflow.ts`

Grundstruktur:

```typescript
import { workflow, node, links } from '@n8n-as-code/transformer';

@workflow({ name: 'Mein Workflow', active: true })
export class MeinWorkflow {

  @node()
  Trigger = {
    type: 'n8n-nodes-base.webhook',
    parameters: { path: '/hook', method: 'POST' },
    position: [250, 300]
  };

  @node()
  Process = {
    type: 'n8n-nodes-base.httpRequest',
    parameters: {
      url: 'https://api.example.com/data',
      method: 'GET'
    },
    position: [450, 300]
  };

  @node()
  Notify = {
    type: 'n8n-nodes-base.slack',
    parameters: {
      resource: 'message',
      operation: 'post',
      channel: '#alerts',
      text: '={{ $json.message }}'
    },
    position: [650, 300]
  };

  @links([
    { from: 'Trigger', to: 'Process' },
    { from: 'Process', to: 'Notify' }
  ])
  connections = {};
}
```

### Wichtige Regeln fuer TypeScript-Workflows

- **Dateiendung** muss `.workflow.ts` sein
- **@workflow** braucht `name`, optional `id` (nur bei existierenden Workflows), `active`, `settings`
- **@node** Property-Namen werden automatisch zu PascalCase Node-Namen
- **@links** definiert die Verbindungen zwischen Nodes
- **Ausdruecke** mit `={{ ... }}` fuer dynamische Werte (n8n Expression Syntax)
- **Mehrere Outputs**: `.out(0)`, `.out(1)` oder `.out('true')`, `.out('false')`
- **Position**: [x, y] Koordinaten, 200px Abstand zwischen Nodes ist ein guter Standard

### Haeufige Node-Typen

| Kategorie | Node-Typ | Beschreibung |
|-----------|----------|--------------|
| Trigger | `n8n-nodes-base.webhook` | HTTP Webhook |
| Trigger | `n8n-nodes-base.scheduleTrigger` | Zeitgesteuert (Cron) |
| HTTP | `n8n-nodes-base.httpRequest` | REST API Aufrufe |
| Logik | `n8n-nodes-base.if` | Bedingung |
| Logik | `n8n-nodes-base.switch` | Mehrfach-Verzweigung |
| Logik | `n8n-nodes-base.code` | Custom JS/Python Code |
| Logik | `n8n-nodes-base.set` | Daten setzen/transformieren |
| Chat | `n8n-nodes-base.slack` | Slack Nachrichten |
| Email | `n8n-nodes-base.gmail` | Gmail senden/lesen |
| DB | `n8n-nodes-base.postgres` | PostgreSQL Queries |
| AI | `@n8n/n8n-nodes-langchain.agent` | AI Agent |
| AI | `@n8n/n8n-nodes-langchain.chainLlm` | LLM Chain |

Bei Unsicherheit immer `npx --yes n8nac skills node-info <name>` fuer das vollstaendige Schema nutzen.

### 3. Workflow validieren

```bash
npx --yes n8nac skills validate <datei>.workflow.ts
npx --yes n8nac skills validate <datei>.workflow.ts --strict
```

Validierung vor dem Push ist Pflicht. Bei Fehlern: korrigieren und erneut validieren.

### 4. Sync mit n8n-Instanz (optional)

Nur wenn `n8nac-config.json` im Projekt existiert:

```bash
# Status aller Workflows anzeigen
npx n8nac list

# Workflow zur n8n-Instanz pushen
npx n8nac push <datei>.workflow.ts

# Workflow von n8n-Instanz pullen
npx n8nac pull <workflowId>

# Konflikte loesen
npx n8nac resolve <workflowId> --mode keep-current
npx n8nac resolve <workflowId> --mode keep-incoming
```

### 5. Konvertierung

```bash
# JSON zu TypeScript
npx n8nac convert workflow.json --format typescript

# Bulk-Konvertierung
npx n8nac convert-batch workflows/ --format typescript
```

## Projekt-Struktur

```
projekt/
├── n8nac-config.json          # Verbindungsconfig (nach n8nac init)
├── workflows/
│   └── instance/project/
│       ├── workflow-1.workflow.ts
│       └── workflow-2.workflow.ts
└── .git/
```

## Wichtig

- IMMER `npx --yes n8nac skills node-info <name>` nutzen um Node-Parameter zu verifizieren - nicht raten
- IMMER validieren bevor gepusht wird
- Expressions nutzen n8n-Syntax: `={{ $json.field }}`, `={{ $node["NodeName"].json.field }}`
- Bei AI/LangChain-Nodes: Prefix ist `@n8n/n8n-nodes-langchain.` statt `n8n-nodes-base.`
