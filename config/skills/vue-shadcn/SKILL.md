---
name: vue-shadcn
description: Vue 3 + shadcn-vue component conventions and patterns
---
When working with Vue 3 components using shadcn-vue (reka-ui/radix-vue):

## Component Structure
- Always use `<script setup lang="ts">` with Composition API
- Props via `defineProps<{}>()` with TypeScript interfaces
- Emits via `defineEmits<{}>()`, not options API
- Use `computed()` and `watch()` from vue, not Options API equivalents

## shadcn-vue Patterns
- Import components from `@/components/ui/` (e.g. `@/components/ui/button`)
- Use `class-variance-authority` (cva) for component variants
- Combine classes with `cn()` utility (clsx + tailwind-merge)
- Radix Vue / Reka UI primitives for headless behavior

## State Management
- Pinia stores with Composition API style (`defineStore` with setup function)
- Avoid Options API stores

## Form Handling
- vee-validate with Zod schemas for form validation
- Use `useForm()` composable, not `<Form>` component directly when complex

## Styling
- Tailwind CSS utility classes, avoid custom CSS unless necessary
- Dark mode via CSS variables, not Tailwind dark: prefix
- Responsive: mobile-first with sm/md/lg/xl breakpoints

## Testing
- Vitest for unit tests, Playwright for E2E
- `@vue/test-utils` mount/shallowMount for component tests
- Test user behavior, not implementation details
