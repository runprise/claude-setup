---
name: nextjs-app
description: Next.js 15 App Router with React 19 and shadcn/ui patterns
---
When working with Next.js projects:

## Architecture
- App Router (`app/` directory), not Pages Router
- Server Components by default, `"use client"` only when needed (state, effects, browser APIs)
- Server Actions for mutations (`"use server"`)
- Parallel routes and intercepting routes for complex layouts

## Components
- shadcn/ui components from `@/components/ui/`
- Radix UI primitives for headless behavior
- `cn()` utility for class merging (clsx + tailwind-merge)
- React Hook Form + Zod for form validation

## Data Fetching
- `fetch()` in Server Components with caching options
- TanStack React Table for data tables
- Avoid client-side fetching unless real-time needed

## Styling
- Tailwind CSS v4 utility classes
- CSS variables for theming
- Framer Motion for animations

## Testing
- Jest for unit tests
- @testing-library/react for component tests
- Playwright for E2E tests

## Build & Deploy
- `next build` with standalone output for Docker
- Multi-stage Docker builds with node:20-alpine
- Turbopack for development (`next dev --turbopack`)
