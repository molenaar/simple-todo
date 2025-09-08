# Coding Standards

This document defines the coding standards and conventions for the Simple To-Do project.

## TypeScript Standards

- Use strict mode TypeScript configuration
- Prefer `const` and `let` over `var`
- Use explicit type annotations for function parameters and return types
- Follow consistent naming conventions:
  - PascalCase for classes and interfaces
  - camelCase for functions and variables
  - UPPER_CASE for constants
  - kebab-case for file names

## Code Organization

- One class/interface per file
- Use index.ts files for clean module exports
- Group related functionality in modules
- Separate business logic from UI components

## Astro Component Standards

- Use `.astro` extension for Astro components
- Place styles at the bottom of component files
- Use TypeScript for component scripts
- Follow component prop interface patterns

## JavaScript Standards

- Use ES6+ features consistently
- Prefer arrow functions for callbacks
- Use template literals for string interpolation
- Handle errors gracefully with try-catch blocks

## CSS/Tailwind Standards

- Use Tailwind utility classes primarily
- Create custom components in @layer components for reusable patterns
- Use semantic HTML elements
- Ensure accessibility with proper ARIA labels

## File and Directory Structure

- Use descriptive, meaningful file and directory names
- Keep components in logical groupings
- Separate concerns (services, components, types, utils)
- Follow established project structure patterns
