# runprise Design System — Auto-Erkennung

## Wann gilt diese Regel?

Wende diese Regel an, wenn das aktuelle Projekt ein **runprise-Projekt** ist. Erkennungsmerkmale:
- Verzeichnisname enthaelt "runprise"
- `package.json` hat "runprise" im `name`-Feld
- Es existiert eine Datei `src/themes/default/index.css` oder aehnliche runprise-spezifische Strukturen
- Der User erwaehnt "runprise" im Kontext

## Was tun bei Erkennung?

Wenn du UI-Komponenten, Styles, Templates oder Frontend-Code fuer ein runprise-Projekt erstellst oder aenderst:

1. **Rufe automatisch `/rp:design` auf**, bevor du CSS, Farben, Typografie oder Komponenten schreibst — dort liegen alle Design-Tokens
2. Halte dich strikt an die dort definierten Werte

## Kurzreferenz der wichtigsten Regeln (immer beachten)

- **Primaerfarbe**: Warm Coral `#E8725C` — einzige CTA- und Focus-Ring-Farbe
- **Schrift**: Plus Jakarta Sans — einzige erlaubte Schrift, Gewichte 400/500/600/700
- **Grau-Toene**: Nur warme Grays (#FAF8F6 bis #1A1210) — niemals kuehle Grays
- **Spacing**: 4px-Grid (4, 8, 12, 16, 24, 32, 48, 64)
- **Border-Radius**: sm=4px, md=8px, lg=12px, xl=16px
- **Focus-Ring**: Coral, nicht Blau
- **NIEMALS**: Blaue CTAs, Font-Weight 300, Coral-Text unter 16px/Bold, kuehle Grays
