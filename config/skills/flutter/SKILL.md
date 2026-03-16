---
name: flutter
description: Flutter/Dart app development patterns and conventions
---
When working with Flutter/Dart projects:

## Project Structure
- Feature-first directory structure (`lib/features/`, `lib/core/`, `lib/shared/`)
- Separate data, domain, and presentation layers per feature
- Barrel files (`index.dart`) for clean exports

## Dart Conventions
- Null safety enabled, avoid `!` operator - use null-aware operators (`?.`, `??`, `??=`)
- Prefer `final` over `var`, `const` constructors where possible
- Use named parameters for >2 parameters
- Typedef for complex function signatures
- Extension methods for utility additions to existing types

## State Management
- Riverpod preferred (or BLoC/Cubit if project uses it)
- Immutable state objects with `freezed` or `copyWith`
- Avoid global mutable state

## Widget Patterns
- Composition over inheritance - small, focused widgets
- Extract widget methods into separate widget classes (not helper methods)
- Use `const` constructors to optimize rebuilds
- Keys only where needed (lists, animations, form fields)
- Prefer `SizedBox` over `Container` for spacing

## Navigation
- GoRouter for declarative routing
- Type-safe route parameters

## Networking & Data
- Dio for HTTP with interceptors for auth/logging
- Retrofit or manual API service classes
- JSON serialization with `json_serializable` or `freezed`
- Repository pattern for data access abstraction

## Testing
- `flutter test` for unit and widget tests
- `flutter test --coverage` for coverage reports
- `mocktail` or `mockito` for mocking
- Widget tests with `WidgetTester` for UI behavior
- Integration tests in `integration_test/`
- Golden tests for visual regression

## Build & Deploy
- Flavors for dev/staging/production environments
- `flutter build apk --release` / `flutter build ios --release`
- `flutter analyze` before commits
- `dart fix --apply` for automated fixes

## Performance
- Use `ListView.builder` for long lists, never `ListView` with children
- `RepaintBoundary` for complex animations
- Profile with Flutter DevTools, watch for unnecessary rebuilds
- Avoid expensive operations in `build()` methods
