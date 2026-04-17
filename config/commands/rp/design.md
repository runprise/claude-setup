# runprise Design System — Near Black & Chartreuse

Wende den runprise Design Guide an, wenn du UI-Komponenten, Styles oder Frontend-Code fuer runprise erstellst oder aenderst. Der vollstaendige Design Guide liegt unter `__HOME__/Development/runprise-designguide/index.html`. Das Theme liegt in `src/themes/runprise/index.css`.

---

## Farbsystem — Near Black & Chartreuse (60-30-10)

### Primaerfarbe — Chartreuse (Signal, 10%)
| Token (shadcn HSL) | Hex | Verwendung |
|---------------------|-----|------------|
| `--primary: 84 82% 56%` | `#B4E834` | CTAs, Focus-Ring, Links, Akzente |
| `--primary-foreground: 240 27% 7%` | `#0E0E14` | Text auf Chartreuse |
| Primary Hover | `#9ACC2A` | Hover/Pressed States |
| Primary Surface | `#F5FDE8` (Light) / `#1A2210` (Dark) | Selektierte Zeile, aktive Bereiche |
| Primary Dim | `rgba(180,232,52,0.1)` | Subtle Backgrounds |

### Near Black (Dominant, 60%)
| Hex | Verwendung |
|-----|------------|
| `#0E0E14` | Primaerfarbe, dominanter Hintergrund (Dark), Text (Light) |
| `#1A1A22` | Dark Surface — Cards, erhoehte Flaechen (30%) |
| `#26262E` | Elevated Surface — Dropdowns, Popovers (Dark) |

### Hintergruende & Text
| Token | Light | Dark | Verwendung |
|-------|-------|------|------------|
| `--background` | `#FFFFFF` | `#0E0E14` | Seiten-Hintergrund |
| `--card` | `#FAFAFA` | `#1A1A22` | Card-Hintergrund |
| `--muted` | `#F5F5F5` | `#26262E` | Neutraler Hintergrund |
| `--foreground` | `#0E0E14` | `#F0F0F2` | Primaertext |
| `--muted-foreground` | `#737373` | `#707078` | Tertiaertext / Muted |
| `--border` | `#E5E5E5` | `rgba(240,240,242,0.08)` | Borders |

### Neutrale Grau-Skala (Tailwind Neutral — KEIN Farbstich)
| Stufe | Hex |
|-------|-----|
| 50 | `#FAFAFA` |
| 100 | `#F5F5F5` |
| 200 | `#E5E5E5` |
| 300 | `#D4D4D4` |
| 400 | `#A3A3A3` |
| 500 | `#737373` |
| 600 | `#525252` |
| 700 | `#404040` |
| 800 | `#262626` |
| 900 | `#171717` |

### Semantische Farben (Tailwind-Palette)
| Typ | Light | Dark | Kontext |
|-----|-------|------|---------|
| Success | `#10b981` | `#34d399` | Vorkontiert, Verbucht |
| Warning | `#f59e0b` | `#fbbf24` | Dubletten, Hinweise |
| Error | `#ef4444` | `#f87171` | Storniert, Ueberfaellig |
| Info | `#3b82f6` | `#60a5fa` | In Bearbeitung |

### Feature-Farben
| Name | Hex | Kontext |
|------|-----|---------|
| Sprint | `#FF6B35` | Schnellbuchung |
| Guard | `#2563EB` | Pruefungen |
| Pace | `#059669` | Fortschritt |
| Coach | `#D97706` | Anleitungen |

### Flaechenverteilung
- 60% Schwarz/Near Black (`#0E0E14`)
- 30% Dark Surface (`#1A1A22`)
- 10% Signal/Chartreuse (`#B4E834`)

### Kontrast-Regeln (WCAG)
- Chartreuse auf Near Black: 12.1:1 — AAA
- Near Black auf White: 19.2:1 — AAA
- Gray-500 auf White: 4.5:1 — AA
- **Chartreuse auf White: 1.8:1 — FAIL! Nur auf dunklem Hintergrund verwenden!**

### Textmarker-Prinzip
Chartreuse auf Weiss hat zu wenig Kontrast. Stattdessen: Chartreuse als Textmarker-Hintergrund (untere 55%) hinter schwarzem Text — wie ein invertierter Highlighter.
```css
background: linear-gradient(to top, #B4E834 55%, transparent 55%);
color: #0E0E14;
```

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
| Primary | `#B4E834` | — | `#0E0E14` |
| Secondary | transparent | `#B4E834` | `#B4E834` |
| Ghost | transparent | `var(--border)` | `var(--fg)` |
| Success | `#10b981` | — | `#FFFFFF` |
| Destructive | `#ef4444` | — | `#FFFFFF` |

### Badges — C3 Uppercase Micro
- **Font-Size: 9px**, Font-Weight: 700, Letter-Spacing: 0.06em, Text-Transform: Uppercase
- Border: 1px solid, Border-Radius: 4px, Padding: 3px 8px
- Varianten: success (border+text: `--success`), warning (`--warning`), error (`--error`), info (`--info`), neutral (`--border-hover` + `--fg3`)

### Inputs
- Border-Radius: 8px, Border: 1.5px solid var(--border), Padding: 8px 12px
- Focus: Border `#B4E834`, Box-Shadow `0 0 0 3px rgba(180,232,52,0.12)`

### Sidebar
- **Immer Dark-Theme** unabhaengig vom App-Theme
- Background: `#0A0A0A` (neutral-dunkel)
- Items: 44px x 44px, Border-Radius: 8px
- Inaktiv: `#737373`, Aktiv: Background `rgba(180,232,52,0.15)`, Icon `#B4E834`
- Icons: Lucide (FileText, BarChart3, Settings, LayoutDashboard etc.)

---

## Regeln — Do's & Don'ts

### IMMER
- Chartreuse `#B4E834` als einzige Signalfarbe fuer CTAs und Focus-Rings
- Chartreuse NUR auf dunklem Hintergrund als Text/Farbe verwenden
- Auf hellem Hintergrund: Textmarker-Effekt (Chartreuse-BG hinter schwarzem Text)
- Plus Jakarta Sans als einzige Schrift
- 4px-Grid fuer alle Abstaende
- `tabular-nums` fuer Zahlenkolonnen
- Neutrale Grau-Toene (Tailwind Neutral, KEIN Farbstich)
- Focus-Ring in Chartreuse, nicht Blau
- C3 Uppercase Micro fuer Status-Badges

### NIEMALS
- Chartreuse als Text auf weissem Hintergrund (Kontrast 1.8:1 = FAIL)
- Warme/braune Grau-Toene (#FAF8F6, #8A7A72, #1A1210 — das war die alte CI)
- Coral/Orange als Primary (#E8725C — das war die alte CI)
- Font-Weight 300 (Light)
- Andere Schriften als Plus Jakarta Sans
- Ungerade Spacing-Werte (5px, 7px, 13px etc.)
- Blaue CTAs oder Focus-Rings (`#2563EB` ist nur fuer Guard/Info)

### Migration (Alt → Neu)
Wenn bestehender runprise-Code diese Muster zeigt, korrigiere sie:
- Coral Buttons/Links `#E8725C` → Chartreuse `#B4E834` (mit schwarzem Text)
- Coral Focus-Ring → Chartreuse Focus-Ring
- Warme Grau-Toene (#FAF8F6, #F2EDE8, #8A7A72) → Neutrale Grays (#FAFAFA, #F5F5F5, #737373)
- Warmer dunkler Hintergrund `#1A1210` / `#2A1E16` → Near Black `#0E0E14` / `#1A1A22`
- Alte Badges (11px, bg+text) → C3 Uppercase Micro (9px, outline, uppercase)
- Sidebar warm-dark `#2A1E16` → Neutral-dark `#0A0A0A`
