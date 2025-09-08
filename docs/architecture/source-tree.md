# Source Tree Structure

This document defines the source code organization and directory structure for the Simple To-Do project.

## Project Root Structure

```
simple-todo/
├── .bmad-core/              # BMAD methodology files
├── docs/                    # Documentation
│   ├── architecture/        # Sharded architecture docs
│   └── prd/                # Sharded PRD docs  
├── app/                     # Astro frontend application
│   ├── src/
│   │   ├── components/      # Astro components (.astro files)
│   │   ├── pages/           # Astro pages (routing)
│   │   ├── scripts/         # Vanilla JavaScript modules
│   │   ├── types/           # TypeScript type definitions
│   │   └── styles/          # Tailwind config and custom CSS
│   ├── public/              # Static assets
│   ├── package.json
│   └── astro.config.mjs
├── api/                     # Azure Functions (future expansion)
├── package.json             # Root orchestration
└── .github/workflows/       # GitHub Actions deployment
```

## Frontend Application Structure (app/)

```
app/src/
├── components/
│   ├── ui/                  # Reusable UI primitives
│   │   ├── Button.astro
│   │   ├── Input.astro
│   │   └── Modal.astro
│   └── features/            # Feature-specific components
│       ├── TaskManager.astro
│       ├── TaskInput.astro
│       ├── TaskList.astro
│       └── ThemeToggle.astro
├── pages/
│   └── index.astro          # Main application page
├── scripts/
│   ├── services/            # Business logic services
│   │   ├── TaskService.ts
│   │   ├── PreferenceService.ts
│   │   └── QuoteService.ts
│   ├── components/          # JavaScript component classes
│   │   └── TaskInput.ts
│   └── utils/               # Utility functions
│       └── validation.ts
├── types/
│   └── index.ts             # TypeScript type definitions
└── styles/
    └── global.css           # Global styles and Tailwind customization
```

## File Naming Conventions

- **Astro Components**: PascalCase with `.astro` extension (e.g., `TaskManager.astro`)
- **TypeScript Files**: camelCase with `.ts` extension (e.g., `taskService.ts`)
- **Type Definition Files**: camelCase with `.ts` extension (e.g., `types/index.ts`)
- **Configuration Files**: kebab-case (e.g., `astro.config.mjs`)
- **Documentation**: kebab-case with `.md` extension (e.g., `coding-standards.md`)

## Import/Export Patterns

- Use explicit imports and exports
- Prefer named exports over default exports
- Use index files for clean module organization
- Group imports by category (external, internal, types)
