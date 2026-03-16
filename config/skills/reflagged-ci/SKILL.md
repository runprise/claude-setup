---
name: reflagged-ci
description: Use when building UI, applications, websites, or design components that should follow the Reflagged/Flagbit Corporate Identity - triggers on "Reflagged design", "Flagbit style", "Foundry theme", "brass UI", or any request for branded Reflagged interfaces
---

# Reflagged Brand Design System

## Overview

Reflagged is Flagbit's product brand built on a **"Quiet Luxury"** design philosophy — understated elegance with warm, material-inspired aesthetics. Every UI must feel like brass, stone, and wood translated into pixels.

## Core Principle

**60-30-10 color rule:** 60% neutral backgrounds, 30% primary brass accents, 10% semantic/module color.

## Dual Theme System (CSS Custom Properties)

### Dark Theme (Default)

```css
:root[data-theme="dark"] {
  /* Backgrounds */
  --bg:              #0E0D12;
  --bg2:             #2A2018;
  --bg3:             #362A20;

  /* Text */
  --fg:              #F0EDE8;
  --fg2:             #9A9088;
  --fg3:             #6A6058;

  /* Primary — Brass */
  --primary:         #B09A6A;
  --primary-on:      #1A1008;
  --primary-dim:     rgba(176,154,106,0.12);
  --primary-surface: #4A3A28;

  /* Secondary */
  --secondary:       #2C1E14;
  --secondary-dim:   rgba(44,30,20,0.25);

  /* Borders */
  --border:          rgba(176,154,106,0.1);
  --border-hover:    rgba(176,154,106,0.2);
  --card-shadow:     0 4px 24px rgba(0,0,0,0.4);

  /* Module Colors */
  --module-culture:   #7A9A7A;
  --module-agents:    #B08A7A;
  --module-knowledge: #6A8AB0;
  --module-content:   #B09A6A;
}
```

### Light Theme

```css
:root[data-theme="light"] {
  --bg:  #FAF8F5;  --bg2: #FFFFFF;  --bg3: #F2EDE8;
  --fg:  #2C1E14;  --fg2: #6A5A4A;  --fg3: #9A8A7A;
  --primary: #7A6A44;  --primary-on: #FAF8F5;
  --primary-dim: rgba(122,106,68,0.1);
  --primary-surface: #5C4A3A;
  --secondary: #5C4A3A;  --secondary-dim: rgba(92,74,58,0.1);
  --border: rgba(44,30,20,0.08);  --border-hover: rgba(44,30,20,0.16);
  --card-shadow: 0 4px 24px rgba(0,0,0,0.06);
  --module-culture: #5A7A5A;  --module-agents: #8A6A5A;
  --module-knowledge: #4A6A8A;  --module-content: #7A6A44;
}
```

### Semantic Colors

| Role | Hex | Usage |
|------|-----|-------|
| Success | `#6BA87A` | Confirmations, positive states |
| Warning | `#B09A6A` | Caution (uses primary brass) |
| Error | `#B06A6A` | Errors, destructive actions |
| Info | `#6A8AB0` | Informational, neutral alerts |

## Typography

Three font families — no exceptions:

| Font | Role | Weights | Fallback |
|------|------|---------|----------|
| **Red Hat Display** | Headlines, titles | 400–900 | system-ui, sans-serif |
| **Inter** | Body, UI text | 300–700 | system-ui, sans-serif |
| **JetBrains Mono** | Code, labels, metadata | 400–700 | monospace |

```html
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;700&family=Red+Hat+Display:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
```

### Scale

| Element | Font | Size | Weight | Spacing |
|---------|------|------|--------|---------|
| Hero heading | Red Hat Display | 2.4rem | 700 | -0.03em |
| Section title | Red Hat Display | 1.6rem | 600 | -0.02em |
| Subsection | Red Hat Display | 1.3rem | 700 | — |
| Body | Inter | 0.95rem | 400 | — |
| Small/caption | Inter | 0.85rem | 400 | — |
| Label/mono | JetBrains Mono | 0.6–0.7rem | 400–500 | 0.08–0.15em, uppercase |
| KPI value | Red Hat Display | 1.4rem | 700 | — |

**Line height:** 1.6 (body), 1.8 (story/readable blocks).

## Spacing & Layout

**Base unit:** 8px. All spacing in multiples.

| Token | Value |
|-------|-------|
| xs | 4px |
| sm | 8px |
| md | 16px |
| lg | 24px |
| xl | 32px |
| 2xl | 48px |
| 3xl | 64px |
| 4xl | 96px |

**Container:** `max-width: 1000px; margin: 0 auto; padding: 0 2rem;`

### Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| sm | 4px | Tags, badges |
| md | 8px | Buttons, inputs |
| lg | 12px | Small cards, semantic cards |
| xl | 16px | Main cards, sections |
| full | 9999px | Pills, avatars |

## Components

### Buttons

```css
/* Primary */
.btn-primary {
  background: var(--primary-surface);
  color: #F0EDE8;
  border: 1px solid transparent;
  border-radius: 8px;
  padding: 0.6rem 1.2rem;
  font-size: 0.8rem;
  font-weight: 600;
}
.btn-primary:hover { opacity: 1; border-color: var(--primary); }

/* Secondary (outlined) */
.btn-secondary {
  background: transparent;
  color: var(--primary);
  border: 1px solid var(--primary);
}
.btn-secondary:hover { background: var(--primary-dim); }
```

### Cards

```css
.card {
  background: var(--bg2);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 2rem;
  transition: border-color 0.3s ease;
}
.card:hover { border-color: var(--border-hover); }
```

### Tags / Badges

```css
.tag {
  display: inline-block;
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.55rem;
  font-weight: 500;
  background: var(--primary-dim);
  color: var(--primary);
}
```

### Inputs

```css
.input {
  background: var(--bg3);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 0.75rem 1rem;
  font-family: 'Inter', sans-serif;
  font-size: 0.9rem;
  color: var(--fg);
}
.input:focus { border-color: var(--primary); outline: none; }
```

### Status Labels

```css
.status {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.6rem;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  padding: 0.25rem 0.6rem;
  border-radius: 3px;
}
```

## Module Colors (Four Pillars)

Each Reflagged pillar has an assigned color:

| Pillar | Color | Domain |
|--------|-------|--------|
| Culture | `#7A9A7A` | Values, behavior |
| Agents | `#B08A7A` | Automation, AI |
| Knowledge | `#6A8AB0` | Information, learning |
| Content | `#B09A6A` | Creation, communication |

Products use subdomain pattern: `[tool].rfl.gd` (e.g. `compass.rfl.gd`, `scout.rfl.gd`, `lore.rfl.gd`, `mint.rfl.gd`).

## Logo & Branding

### The Stack (Icon Mark)

Three horizontal bars with rounded left ends, progressively wider, with opacity layers (Kano model):

```svg
<svg viewBox="0 0 32 30" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M32,0 H23 A3,3 0 0,0 20,3 A3,3 0 0,0 23,6 H32 Z" fill="var(--primary)"/>
  <path d="M32,11 H12 A2,2 0 0,0 10,13 A2,2 0 0,0 12,15 H32 Z" fill="var(--primary)" opacity="0.45"/>
  <path d="M32,23 H1.5 A1.5,1.5 0 0,0 0,24.5 A1.5,1.5 0 0,0 1.5,26 H32 Z" fill="var(--primary)" opacity="0.25"/>
</svg>
```

| Bar | Opacity | Meaning |
|-----|---------|---------|
| Top (shortest) | 100% | Primary / Delight |
| Middle | 45% | Support / Performance |
| Bottom (widest) | 25% | Foundation / Basic |

**Color:** Brass `#B09A6A` on dark, olive `#7A6A44` on light. Monochrome allowed.
**Minimum size:** 16px height. **Clear space:** Equal to bar height on all sides.

### Combination Logo (Stack + Product Name)

The combination logo pairs the Stack icon with the **product name** (NOT "Reflagged"). "Reflagged" is the umbrella brand — in product UIs, always use the specific product name.

```html
<div style="display:flex; align-items:flex-start; gap:0.6rem;">
  <!-- Stack icon: 36×34px, margin-top aligns with text baseline -->
  <svg width="36" height="34" viewBox="0 0 32 30" style="margin-top:6.5px; flex-shrink:0;">
    <!-- ... Stack paths ... -->
  </svg>
  <span style="font-family:'Red Hat Display',sans-serif; font-size:2.6rem; font-weight:700; letter-spacing:-0.025em; color:var(--fg);">
    Scout<!-- or Content, Compass, Lore, Mint, etc. -->
  </span>
</div>
```

**Rules:**
- Text uses **Red Hat Display**, 2.6rem, weight 700, letter-spacing -0.025em
- Stack icon aligns to top of text with `margin-top: 6.5px`
- Gap between icon and text: `0.6rem`
- Never write "Reflagged Scout" — just "Scout" with the Stack icon

### Product Tag (`name.rfl.gd`)

Products are identified by a two-part tag: the product name in the pillar color + `.rfl.gd` domain suffix in neutral. This is the primary way to reference products in navigation, headers, and cards.

```html
<div class="product-tag">
  <span class="product-tag-name">Scout</span>
  <span class="product-tag-domain">.rfl.gd</span>
</div>
```

```css
.product-tag {
  display: inline-flex;
  align-items: center;
  border-radius: 6px;
  overflow: hidden;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.65rem;
  font-weight: 500;
  letter-spacing: 0.08em;
}
.product-tag-name {
  padding: 0.3rem 0.5rem;
  background: var(--module-agents); /* Use pillar color */
  color: #F0EDE8;
  text-transform: lowercase;
}
.product-tag-domain {
  padding: 0.3rem 0.5rem;
  background: var(--bg3);
  color: var(--fg2);
}
```

| Product | Pillar | Tag Color | URL |
|---------|--------|-----------|-----|
| Compass | Culture | `--module-culture` (#7A9A7A) | compass.rfl.gd |
| Scout | Agents | `--module-agents` (#B08A7A) | scout.rfl.gd |
| Lore | Knowledge | `--module-knowledge` (#6A8AB0) | lore.rfl.gd |
| Mint | Content | `--module-content` (#B09A6A) | mint.rfl.gd |

### Naming Rules

- **"Reflagged"** appears only on the company/brand level (e.g. landing pages, legal, about sections)
- In product UIs: use only the **product name** (e.g. "Scout", not "Reflagged Scout")
- The Stack icon replaces the word "Reflagged" in product contexts
- Domain suffix `.rfl.gd` (abbreviation of "reflagged") connects products to the brand
- Product tag format `name.rfl.gd` is the canonical product identifier

## Don'ts

- No colors outside the Foundry palette
- No bright/saturated colors — muted only
- No font families beyond the three approved
- No crowded layouts — whitespace is a design element
- No patterns as primary content (texture/accent only)
- Always implement both dark and light themes
- Always test WCAG AA contrast (4.5:1 small text, 3:1 large)
