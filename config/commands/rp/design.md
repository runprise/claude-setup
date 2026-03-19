# runprise Design System

Wende den runprise Design Guide an, wenn du UI-Komponenten, Styles oder Frontend-Code fuer runprise erstellst oder aenderst. Der vollstaendige Design Guide liegt unter `__HOME__/Development/runprise-designguide/index.html`.

---

## Farben

### Primaerfarbe — Warm Coral
| Token | Hex | Verwendung |
|-------|-----|------------|
| `--primary` | `#E8725C` | CTAs, Focus-Ring, Links |
| `--primary-on` | `#FFFFFF` | Text auf Primary |
| `--primary-dim` | `rgba(232,114,92,0.1)` | Primary 10% Opacity |
| `--primary-surface` | `#FFF6F3` | Selektierte Zeile, aktive Bereiche |
| Primary Hover | `#C4533E` | Hover/Pressed States |

### Hintergruende & Text
| Token | Hex | Verwendung |
|-------|-----|------------|
| `--bg` | `#FAF8F6` | Seiten-Hintergrund |
| `--bg2` | `#FFFFFF` | Card-Hintergrund |
| `--bg3` / `--neutral-bg` | `#F2EDE8` | Neutraler Hintergrund |
| `--fg` | `#1A1210` | Primaertext |
| `--fg2` / `--neutral-fg` | `#6A5A4A` | Sekundaertext |
| `--fg3` | `#8A7A72` | Tertiaertext / Muted |

### Borders & Schatten
| Token | Wert |
|-------|------|
| `--border` | `rgba(26,18,16,0.08)` |
| `--border-hover` | `rgba(26,18,16,0.16)` |
| `--card-shadow` | `0 4px 24px rgba(0,0,0,0.06)` |

### Warm-Gray-Skala
| Stufe | Hex |
|-------|-----|
| 50 | `#FAF8F6` |
| 100 | `#F2EDE8` |
| 200 | `#E8E0D8` |
| 300 | `#C8BEB4` |
| 400 | `#A89A8E` |
| 500 | `#8A7A72` |
| 600 | `#6A5A4A` |
| 700 | `#4A3A2A` |
| 800 | `#2A1E16` |
| 900 | `#1A1210` |

### Semantische Farben
| Typ | Farbe | Hintergrund | Kontext |
|-----|-------|-------------|---------|
| Success | `#2E7D32` | `#E8F5E9` | Vorkontiert, Verbucht |
| Warning | `#C4533E` | `#FFF0EB` | Dubletten, Hinweise |
| Error | `#D32F2F` | `#FFEBEE` | Storniert, Ueberfaellig |
| Info | `#1565C0` | `#E3F2FD` | In Bearbeitung |

### Feature-Farben
| Name | Hex | Kontext |
|------|-----|---------|
| Sprint | `#FF6B35` | Schnellbuchung |
| Guard | `#2563EB` | Pruefungen |
| Pace | `#059669` | Fortschritt |
| Coach | `#D97706` | Anleitungen |

### Flaechenverteilung
- 70% Neutral/Background (`#FAF8F6`)
- 20% Cards (`#FFFFFF`)
- 8% Primary Coral (`#E8725C`)
- 2% Dark (`#1A1210`)

### Kontrast-Regeln (WCAG)
- Coral auf Warm White: 3.2:1 — nur AA Large
- Coral auf Warm Black: 5.1:1 — AA
- Warm Black auf Warm White: 15.8:1 — AAA
- **Coral-Text niemals unter 16px/Bold verwenden**

---

## Typografie — Plus Jakarta Sans

### Schrift
- **Familie**: Plus Jakarta Sans (Variable, self-hosted)
- **Nur diese 4 Gewichte**: 400 Regular, 500 Medium, 600 Semibold, 700 Bold
- **Kein Light (300)** — zu duenn fuer UI
- **Keine anderen Schriften mischen**

### Type Scale
| Token | Groesse | Gewicht | Letter-Spacing | Line-Height | Verwendung |
|-------|---------|---------|----------------|-------------|------------|
| Display | 2rem (32px) | 700 | -0.03em | 1.2 | Grosse Ueberschriften |
| H1 | 1.5rem (24px) | 700 | -0.02em | 1.2 | Seitentitel |
| H2 | 1.125rem (18px) | 600 | -0.01em | 1.3 | Abschnitte |
| Body | 0.875rem (14px) | 400 | default | 1.5 | Fliesstext |
| Small | 0.8125rem (13px) | 400 | default | 1.5 | Sekundaertext |
| XS | 0.75rem (12px) | 500 | default | default | Kleine Labels |
| Label | 0.6875rem (11px) | 600 | 0.03em | default | Uppercase Labels |

### Zahlen
- `font-variant-numeric: tabular-nums` fuer Tabellen und Betraege

---

## Spacing — 4px Basis-Grid

| Token | Wert | Verwendung |
|-------|------|------------|
| `--space-1` | 4px | Kompakter Abstand |
| `--space-2` | 8px | Badge-Gap, kleine Luecken |
| `--space-3` | 12px | Input-Padding, Button SM |
| `--space-4` | 16px | Card-Padding min, Button MD |
| `--space-6` | 24px | Card-Padding normal, Card-Gap |
| `--space-8` | 32px | Section-Gap |
| `--space-12` | 48px | Grosse Section-Trennung |
| `--space-16` | 64px | Kapitel-Trennung |

### Border Radius
| Token | Wert | Verwendung |
|-------|------|------------|
| `--radius-sm` | 4px | Badges |
| `--radius-md` | 8px | Buttons, Inputs |
| `--radius-lg` | 12px | Cards, Dropdowns |
| `--radius-xl` | 16px | Modals |
| `--radius-full` | 9999px | Avatare, Dots |

---

## Komponenten

### Buttons
**Varianten**: Primary, Secondary, Ghost, Success, Destructive
**Groessen**: SM (4px 12px, 12px), MD (8px 16px, 13px), LG (12px 24px, 14px)

| Variante | Background | Border | Text |
|----------|-----------|--------|------|
| Primary | `#E8725C` | — | `#FFFFFF` |
| Secondary | transparent | `#E8725C` | `#E8725C` |
| Ghost | transparent | transparent | `#1A1210` |
| Success | `#2E7D32` | — | `#FFFFFF` |
| Destructive | `#D32F2F` | — | `#FFFFFF` |

### Badges
- Padding: 3px 10px, Border-Radius: 4px, Font-Size: 11px, Font-Weight: 600
- Varianten: success, warning, error, info, neutral

### Inputs
- Border-Radius: 8px, Border: 1.5px solid var(--border), Padding: 8px 12px
- Focus: Border `#E8725C`, Box-Shadow `0 0 0 3px rgba(232,114,92,0.12)`

### Sidebar
- **Immer Dark-Theme** unabhaengig vom App-Theme
- Items: 44px x 44px, Border-Radius: 8px, Background: `#1A1210`
- Inaktiv: `#8A7A72`, Aktiv: Background `rgba(232,114,92,0.15)`, Icon `#E8725C`

---

## Regeln — Do's & Don'ts

### IMMER
- Warm Coral `#E8725C` als einzige Primaerfarbe fuer CTAs und Focus-Rings
- Plus Jakarta Sans als einzige Schrift
- 4px-Grid fuer alle Abstaende
- `tabular-nums` fuer Zahlenkolonnen
- Warme Grau-Toene (nicht kuehles Grau)
- Focus-Ring in Coral, nicht Blau
- Ausreichend Kontrast (WCAG AA)

### NIEMALS
- Blaue CTAs oder Focus-Rings (`#2563EB` ist nur fuer Guard/Info)
- Kuehle Grau-Toene (#f5f5f5, #e5e5e5, #737373)
- Font-Weight 300 (Light)
- Coral-Text unter 16px/Bold
- Andere Schriften als Plus Jakarta Sans
- Ungerade Spacing-Werte (5px, 7px, 13px etc.)
- Schatten staerker als `0 4px 24px rgba(0,0,0,0.06)`

### Vorher/Nachher-Leitlinie
Wenn bestehender runprise-Code diese Muster zeigt, korrigiere sie:
- Blaue Buttons/Links → Coral `#E8725C`
- Blauer Focus-Ring → Coral Focus-Ring
- Inter/System-Font → Plus Jakarta Sans
- Kuehle Grau-Toene → Warme Grau-Skala
- Inkonsistente Badge-Farben → Semantisches Badge-System
