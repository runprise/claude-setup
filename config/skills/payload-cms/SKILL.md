---
name: payload-cms
description: Use when building with Payload CMS 3.x — collections, fields, hooks, access control, admin UI customization, custom components, plugins, migrations, and deployment. Triggers on "Payload", "Payload CMS", "payload.config", "collection config", "Payload admin panel", or any Payload-related development
---

# Payload CMS 3.x — Best Practices

## Stack

- Payload CMS 3.x mit Next.js 15 und React 19
- PostgreSQL via `@payloadcms/db-postgres`
- Lexical Editor fuer Rich Text (`@payloadcms/richtext-lexical`)
- Sharp fuer Bildverarbeitung
- TypeScript strict mode

## Projekt-Struktur

```
payload.config.ts          # Haupt-Config mit buildConfig()
collections/               # Eine Datei pro Collection
globals/                   # Global-Configs
lib/access/                # Access Control Funktionen
components/                # Custom Admin Components (React)
views/                     # Custom Admin Views
types/                     # Rollen, payload-types.ts
app/(payload)/             # Payload Admin UI (Next.js Route)
migrations/                # DB Migrations
plugins/                   # Custom Plugins
```

## Collection Patterns

- Export als `CollectionConfig` typisiert
- `slug` in kebab-case, Export-Name in PascalCase
- Access Control immer definieren: `read`, `create`, `update`, `delete`
- Access-Funktionen in `lib/access/` auslagern (z.B. `isAuthenticated`, `isAdmin`)
- `admin.useAsTitle` setzen fuer bessere Admin-UX
- `admin.group` fuer logische Gruppierung im Admin Panel
- Fields mit `saveToJWT: true` fuer Auth-relevante Felder

## Field Patterns

- Standard-Types: `text`, `number`, `select`, `relationship`, `upload`, `richText`, `array`, `group`, `blocks`
- `required: true` explizit setzen wo noetig
- `hasMany: true` bei Select fuer Multi-Select
- `defaultValue` wo sinnvoll
- Field-level Access mit separaten Funktionen (z.B. `isAdminFieldLevel`)
- Conditional Logic mit `admin.condition` fuer dynamische Felder

## Globals

- Fuer singleton-Daten (Settings, Brand Config, Footer, etc.)
- Gleiche Access-Control Patterns wie Collections

## Admin UI Customization

### Kritische Regel: Component Paths (v3)

In Payload 3.x werden Komponenten als **String-Pfade** registriert, NICHT als Imports:

```ts
// RICHTIG (v3): String-Pfad
admin: {
  components: {
    Field: '/components/StatusField'
  }
}

// FALSCH: Direkter Import (v2 Pattern, funktioniert in v3 nicht)
import { StatusField } from './components/StatusField'
admin: {
  components: {
    Field: StatusField  // ❌
  }
}
```

**Pfad-Regeln:**
- Pfade relativ zum Projektroot oder `config.admin.importMap.baseDir`
- Named Exports: `#ExportName` Suffix oder `exportName` Property
- Default Exports: kein Suffix noetig
- Datei-Extension kann weggelassen werden

### Server vs Client Components

Payload Admin Components sind standardmaessig **Server Components**. Fuer interaktive Komponenten:

```tsx
// components/StatusField.tsx
'use client'  // Nur wenn Interaktivitaet noetig (State, Events, Hooks)

import { useField } from '@payloadcms/ui'

export default function StatusField() {
  const { value, setValue } = useField<string>({ path: 'status' })
  return (
    <select value={value} onChange={(e) => setValue(e.target.value)}>
      <option value="draft">Draft</option>
      <option value="published">Published</option>
    </select>
  )
}
```

**Wann `'use client'`:**
- `useState`, `useEffect`, Event-Handler
- Payload UI Hooks: `useField`, `useForm`, `useDocumentInfo`, `useAuth`
- Browser APIs

**Wann Server Component (kein Directive):**
- Rein darstellende Komponenten (Logo, Banner, statischer Text)
- Daten-Fetching via `payload.find()` direkt im Component

### Root Components (Global Admin UI)

```ts
export default buildConfig({
  admin: {
    components: {
      // Branding
      graphics: {
        Logo: '/components/Logo',       // Login-Seite, groesser
        Icon: '/components/Icon',       // Sidebar/Favicon, kleiner
      },

      // Navigation
      Nav: '/components/CustomNav',
      beforeNavLinks: ['/components/CustomNavItem'],
      afterNavLinks: ['/components/NavFooter'],

      // Header
      header: ['/components/AnnouncementBanner'],
      actions: ['/components/ClearCache', '/components/Preview'],

      // Dashboard
      beforeDashboard: ['/components/WelcomeMessage'],
      afterDashboard: ['/components/Analytics'],

      // Auth
      beforeLogin: ['/components/SSOButtons'],
      logout: { Button: '/components/LogoutButton' },

      // Custom Views (neue Routen im Admin)
      views: {
        dashboard: { Component: '/views/CustomDashboard' },
        custom: {
          Component: '/views/ImportTool',
          path: '/import',  // erreichbar unter /admin/import
        },
      },
    },
  },
})
```

### Field Components

Jedes Feld kann seine Admin-UI komplett ueberschreiben:

```ts
{
  name: 'status',
  type: 'select',
  options: ['draft', 'published'],
  admin: {
    components: {
      Field: '/components/StatusField',           // Edit View
      Cell: '/components/StatusCell',              // List View Zelle
      Label: '/components/StatusLabel',            // Feld-Label
      Description: '/components/StatusDescription', // Hilfetext
      Error: '/components/StatusError',            // Fehlermeldung
    }
  }
}
```

### Collection/Global View Overrides

```ts
export const Posts: CollectionConfig = {
  slug: 'posts',
  admin: {
    views: {
      edit: {
        // Komplett eigene Edit-View
        Component: '/views/PostEditor',
        // Oder: eigene Root-View (ersetzt gesamtes Layout)
        root: {
          Component: '/views/PostEditorRoot',
        },
      },
    },
  },
}
```

### Custom CSS / Theming

```ts
export default buildConfig({
  admin: {
    css: '/styles/admin.css',  // Custom Stylesheet
    meta: {
      titleSuffix: '— My CMS',
      favicon: '/favicon.ico',
      ogImage: '/og-image.png',
    },
  },
})
```

In `/styles/admin.css` Payload CSS Custom Properties ueberschreiben:

```css
:root {
  --theme-elevation-0: #0E0D12;
  --theme-elevation-50: #1a1a2e;
  --theme-elevation-100: #2A2018;
  --color-base-0: #F0EDE8;
  --color-base-500: #B09A6A;
  --font-body: 'Inter', sans-serif;
}
```

## Access Control

- Rollenbasiert ueber JWT Claims (`saveToJWT`)
- Funktionen returnen `boolean` oder `Where`-Query fuer field-level Filtering
- Patterns: `isAuthenticated`, `isAdmin`, `isAdminOrSelf`, `hasAnyRole`

```ts
// Einfacher Check
const isAuthenticated: Access = ({ req: { user } }) => Boolean(user)

// Row-Level Security
const ownOnly: Access = ({ req: { user } }) => {
  if (user?.roles?.includes('admin')) return true
  return { author: { equals: user.id } }
}
```

- Indexierte Felder in Where-Queries verwenden (Performance!)
- Admin-Bypass: Admins immer `return true` bevor Query-Constraints greifen
- Field-Level Access fuer sensible Felder (z.B. Rollen nur durch Admins aenderbar)

## Hooks Best Practices

Hook-Reihenfolge: `beforeValidate` → `beforeChange` → [DB] → `afterChange` → `afterRead`

| Hook | Zweck | Beispiel |
|------|-------|---------|
| `beforeValidate` | Daten formatieren | Slug aus Titel generieren |
| `beforeChange` | Business-Logik | `publishedAt` bei Status-Wechsel |
| `afterChange` | Side-Effects | Notifications, Cache, externe APIs |
| `afterRead` | Computed Fields | View-Counter, berechnete Werte |
| `beforeDelete` | Cascade | Verknuepfte Dokumente mitloeschen |

**Infinite Loops vermeiden** — `context`-Flag nutzen:
```ts
afterChange: [async ({ doc, req, context }) => {
  if (context.skipHooks) return
  await req.payload.update({
    collection: 'posts', id: doc.id,
    data: { ... },
    context: { skipHooks: true }, req,
  })
}]
```

**`req` immer weitergeben** an verschachtelte Payload-Operationen (fuer Transactions).

## Versioning & Drafts

```ts
export const Pages: CollectionConfig = {
  slug: 'pages',
  versions: {
    drafts: {
      autosave: true,
      schedulePublish: true,
      validate: false,  // Drafts nicht validieren
    },
    maxPerDoc: 100,
  },
  access: {
    read: ({ req: { user } }) => {
      if (!user) return { _status: { equals: 'published' } }
      return true
    },
  },
}
```

## Rich Text (Lexical)

- Features explizit importieren und konfigurieren
- `FixedToolbarFeature` + `InlineToolbarFeature` als Standard
- `HeadingFeature`, `BoldFeature`, `ItalicFeature`, `LinkFeature` als Basis
- `UploadFeature` fuer Bild-Einbettung

## Plugin Development

Plugins modifizieren die Config via Funktion:

```ts
import type { Config, Plugin } from 'payload'

export const myPlugin: Plugin = (incomingConfig: Config): Config => {
  return {
    ...incomingConfig,
    collections: incomingConfig.collections.map((collection) => ({
      ...collection,
      fields: [
        ...collection.fields,
        {
          name: 'lastModifiedBy',
          type: 'relationship',
          relationTo: 'users',
          hooks: {
            beforeChange: [({ req }) => ({
              value: req?.user?.id,
              relationTo: req?.user?.collection,
            })],
          },
          admin: { position: 'sidebar', readOnly: true },
        },
      ],
    })),
  }
}
```

**Plugin-Regeln:**
- Immer `...incomingConfig` spreaden, nie ueberschreiben
- Collections/Globals/Fields additiv erweitern
- Eigene Collections mit eindeutigem Prefix benennen
- Plugin-Config als Parameter akzeptieren fuer Konfigurierbarkeit

## API & Endpoints

- REST API automatisch unter `/api/<collection-slug>`
- GraphQL unter `/api/graphql`
- Local API: `payload.find()`, `payload.create()`, `payload.update()`, `payload.delete()`

Custom Endpoints:
```ts
endpoints: [{
  path: '/preview',
  method: 'post',
  handler: async (req) => {
    if (!req.user) throw new APIError('Unauthorized', 401)
    await addDataAndFileToRequest(req)
    const results = await req.payload.find({
      collection: req.data.collection,
      where: req.data.where,
      limit: 10, depth: 0,
    })
    return Response.json(results)
  }
}]
```

## Typen-Generierung

- `payload generate:types` nach Schema-Aenderungen ausfuehren
- Generierte Types in `types/payload-types.ts`
- Diese Types in Frontend-Code importieren fuer Type Safety

## Migrations

```bash
# Migration erstellen nach Schema-Aenderung
npx payload migrate:create

# Migrations ausfuehren
npx payload migrate

# Migration-Status pruefen
npx payload migrate:status
```

- Migrations werden automatisch beim Start ausgefuehrt wenn `migrate` in Config aktiviert
- Manuelle SQL in Migrations nur wenn noetig (Daten-Transformationen)
- Migrations immer committen und im Team synchron halten

## Validation

- Custom Validation via `validate` Funktion auf Field-Ebene
- Return `true` fuer gueltig oder Error-String fuer Fehlermeldung
- `required`, `min`, `max`, `minLength`, `maxLength` bevorzugen vor Custom Validation

## Performance

- `index: true` auf Felder setzen die in Queries/Filtern verwendet werden
- `depth` limitieren bei Relationship-Queries (Standard: 1-2, nicht unbegrenzt)
- `select` nutzen um nur benoetigte Felder abzufragen
- Versions/Drafts: `maxPerDoc` begrenzen (z.B. 10-25) um DB-Bloat zu vermeiden
- `defaultColumns` im Admin setzen um unnoetige Relationship-Lookups zu vermeiden
- Pagination immer nutzen: `limit` und `page` Parameter

## Deployment

- `next build` baut Payload mit
- `DATABASE_URL` als Env-Variable (PostgreSQL Connection String)
- `PAYLOAD_SECRET` fuer Auth-Token Signierung
- Docker multi-stage Build mit Node.js
- `payload migrate` vor oder beim Startup ausfuehren

## Don'ts

- Nie Komponenten direkt importieren in Config — immer String-Pfade (v3)
- Nie `depth: 0` global setzen — pro Query entscheiden
- Nie Access Control weglassen — auch fuer interne Collections definieren
- Nie Hooks ohne `context`-Flag verschachteln — Infinite Loop Gefahr
- Nie `payload-types.ts` manuell editieren — wird ueberschrieben
- Nie Migrations loeschen die schon deployed sind
- Nie `req` vergessen bei verschachtelten Payload-Operationen in Hooks
