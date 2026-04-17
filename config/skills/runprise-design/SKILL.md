---
name: runprise-design
description: >
  Use when building UI, applications, websites, or design components for
  Runprise projects. Covers the Near Black & Chartreuse design system: 60-30-10
  color rule with Chartreuse (#B4E834) signal accent, Near Black (#0E0E14)
  dominant surface, neutral Tailwind grays, Plus Jakarta Sans typography, 4px
  spacing grid, C3 Uppercase Micro badges, dark sidebar pattern. Triggers on
  "runprise", "Runprise UI", "Runprise Theme", "Near Black Chartreuse",
  "runprise design", "runprise CI", detection of a runprise package.json name,
  or presence of src/themes/runprise/index.css.
---

# Runprise Design System — Near Black & Chartreuse

Strikt eingehaltenes Design-System fuer alle Runprise-Frontend-Artefakte. Voller Token-Referenz im Slash-Command `/rp:design` (Farben, Typografie, Spacing, Komponenten, Do's & Don'ts).

## Auto-Erkennung

Dieser Skill gilt wenn:
- Verzeichnisname enthaelt "runprise"
- `package.json` hat "runprise" im `name`-Feld
- Es existiert eine Datei `src/themes/runprise/index.css` oder aehnliche runprise-spezifische Strukturen
- Der User erwaehnt "runprise" im Kontext

## Bei Erkennung

Vor jeder UI-, Style-, Template- oder Frontend-Code-Aenderung:

1. **`/rp:design` konsultieren** — dort liegen die vollstaendigen Design-Tokens
2. Sich strikt an die dort definierten Werte halten

## Kurzreferenz (immer beachten)

- **Signalfarbe**: Chartreuse `#B4E834` — einzige CTA- und Focus-Ring-Farbe
- **Dominant**: Near Black `#0E0E14` — 60% der Flaeche
- **Verhaeltnis**: 60% Schwarz, 30% Dark Surface (`#1A1A22`), 10% Chartreuse
- **Schrift**: Plus Jakarta Sans — einzige erlaubte Schrift, Gewichte 400/500/600/700
- **Grau-Toene**: Nur neutrale Tailwind Grays (#FAFAFA bis #171717) — KEIN Farbstich
- **Spacing**: 4px-Grid (4, 8, 12, 16, 24, 32, 48, 64)
- **Border-Radius**: sm=4px, md=8px, lg=12px, xl=16px
- **Focus-Ring**: Chartreuse `#B4E834`, nicht Blau
- **Badges**: C3 Uppercase Micro (9px, outline, uppercase, letter-spacing 0.06em)
- **Sidebar**: Immer dunkel `#0A0A0A`, Chartreuse-Highlight
- **Textmarker**: Auf hellem Hintergrund Chartreuse als BG-Highlight hinter schwarzem Text

## NIEMALS

- Chartreuse-Text auf weissem Hintergrund (Kontrast 1.8:1 = FAIL)
- Warme/braune Grays (#FAF8F6, #8A7A72 — alte CI)
- Coral/Orange als Primary (#E8725C — alte CI)
- Font-Weight 300 (Light)
- Andere Schriften als Plus Jakarta Sans
- Ungerade Spacing-Werte (5px, 7px, 13px)
- Blaue CTAs oder Focus-Rings

## Vollstaendige Tokens

```
/rp:design
```

Slash-Command gibt die komplette Token-Referenz (Farbvariablen, Type-Scale, Komponenten-Specs, Migrations-Guide Alt→Neu) aus.
