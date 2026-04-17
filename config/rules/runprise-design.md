# runprise Design System — Auto-Erkennung

## Wann gilt diese Regel?

Wende diese Regel an, wenn das aktuelle Projekt ein **runprise-Projekt** ist. Erkennungsmerkmale:
- Verzeichnisname enthaelt "runprise"
- `package.json` hat "runprise" im `name`-Feld
- Es existiert eine Datei `src/themes/runprise/index.css` oder aehnliche runprise-spezifische Strukturen
- Der User erwaehnt "runprise" im Kontext

## Was tun bei Erkennung?

Wenn du UI-Komponenten, Styles, Templates oder Frontend-Code fuer ein runprise-Projekt erstellst oder aenderst:

1. **Rufe automatisch `/rp:design` auf**, bevor du CSS, Farben, Typografie oder Komponenten schreibst — dort liegen alle Design-Tokens
2. Halte dich strikt an die dort definierten Werte

## Kurzreferenz der wichtigsten Regeln (immer beachten)

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
- **NIEMALS**: Chartreuse-Text auf weissem Hintergrund (Kontrast 1.8:1 = FAIL!)
- **NIEMALS**: Warme Grays, Coral/Orange als Primary, Font-Weight 300
- **Textmarker**: Auf hellem Hintergrund Chartreuse als BG-Highlight hinter schwarzem Text
