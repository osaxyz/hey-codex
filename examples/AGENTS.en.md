# AGENTS.md Template

This file provides instructions for Codex CLI when working on this project.
Place this file at the root of your project.

## Coding Standards

- Language: TypeScript
- Style: Functional programming preferred
- Naming: camelCase for variables/functions, PascalCase for types/classes
- Indentation: 2 spaces
- Line length: 100 characters max
- Semicolons: required

## Directory Structure

```
src/
  components/    # UI components
  hooks/         # Custom hooks
  utils/         # Utility functions
  types/         # Type definitions
  services/      # API/external service integrations
tests/
  unit/          # Unit tests
  integration/   # Integration tests
```

## Tech Stack

- Runtime: Node.js 22+
- Framework: (specify your framework)
- Testing: Vitest
- Linting: ESLint + Prettier

## Testing Policy

- All new functions must have unit tests
- Test file naming: `*.test.ts`
- Minimum coverage: 80%
- Use descriptive test names: `it('should return X when given Y')`

## Prohibited

- Do NOT use `any` type in TypeScript
- Do NOT use `var` declarations
- Do NOT commit console.log statements
- Do NOT use synchronous file operations in production code
- Do NOT store secrets in code

## Important Notes

- Always check existing patterns before creating new ones
- Prefer composition over inheritance
- Keep functions small and focused (max 30 lines)
- Handle errors explicitly, never swallow exceptions
