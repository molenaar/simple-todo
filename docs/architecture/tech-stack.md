# Tech Stack

This is the **DEFINITIVE** technology selection for the entire Simple To-Do project. All development must use these exact versions and tools. This selection balances simplicity, performance, educational value, and future expandability.

### Technology Stack Table

| Category | Technology | Version | Purpose | Rationale |
|----------|------------|---------|---------|-----------|
| **Frontend Language** | TypeScript | 5.3+ | Type-safe development with strict mode | Eliminates runtime errors, improves developer experience, educational clarity for BMAD demonstration |
| **Frontend Framework** | Astro | 5.0+ | Static site generation with selective hydration | Zero-JS by default, optimal performance, component-based architecture without framework complexity |
| **UI Component Library** | Native Astro Components | 5.0+ | .astro file components with TypeScript | No external dependencies, maximum performance, educational transparency |
| **State Management** | Vanilla JavaScript + localStorage | ES2022+ | Client-side persistence and DOM manipulation | Simplicity, privacy-first, no framework overhead, demonstrates fundamental concepts |
| **Backend Language** | N/A (MVP) | - | localStorage-only for MVP phase | Zero infrastructure complexity, privacy-first design, rapid development |
| **Backend Framework** | N/A (MVP) | - | Future: Node.js 20+ Azure Functions | Prepared for API expansion without architecture changes |
| **API Style** | N/A (MVP) | - | Future: RESTful JSON APIs | Standard approach for future Azure Functions integration |
| **Database** | Browser localStorage | Native | Client-side JSON data persistence | Zero infrastructure, privacy compliance, offline functionality |
| **Cache** | Browser Cache | Native | Static asset and localStorage caching | Built-in browser performance optimization |
| **File Storage** | N/A (MVP) | - | Future: Azure Blob Storage | Prepared for cloud expansion when needed |
| **Authentication** | N/A (MVP) | - | Future: Azure Static Web Apps Auth | Simple integration path for user management |
| **Frontend Testing** | Vitest | 2.0+ | Unit testing for utilities and logic | Fast, modern testing framework aligned with Vite ecosystem |
| **Backend Testing** | N/A (MVP) | - | Future: Vitest for Azure Functions | Consistent testing approach across stack |
| **E2E Testing** | Playwright | 1.40+ | Complete user workflow validation | Cross-browser testing, accessibility validation integration |
| **Build Tool** | Astro CLI | 5.0+ | Static site generation and optimization | Built-in optimization, zero configuration complexity |
| **Bundler** | Vite | 5.0+ | Fast development and production builds | Integrated with Astro, excellent TypeScript support |
| **IaC Tool** | N/A | - | Manual Azure Static Web Apps setup | Simplicity over infrastructure complexity for MVP |
| **CI/CD** | GitHub Actions | Latest | Automated deployment to Azure Static Web Apps | Native GitHub integration, zero additional costs |
| **Monitoring** | Azure Static Web Apps Analytics | Built-in | Basic usage analytics and performance monitoring | Integrated solution, privacy-conscious |
| **Logging** | Browser DevTools | Native | Client-side debugging and error tracking | Development-focused approach for MVP |
| **CSS Framework** | Tailwind CSS | 4.0+ | Utility-first styling with design system | Rapid development, consistent design, excellent performance |

### Key Technology Decisions

**Why Astro v5?**
- Zero-JavaScript by default aligns with performance requirements (<1 second load times)
- Component-based architecture provides educational clarity for BMAD methodology
- Built-in TypeScript support with strict mode
- Excellent developer experience with hot reload and debugging

**Why Vanilla JavaScript over React/Vue?**
- Eliminates framework complexity for a simple todo app
- Demonstrates fundamental web development concepts clearly
- Zero runtime dependencies = maximum performance
- Educational value for developers learning core technologies

**Why Tailwind CSS v4?**
- Utility-first approach speeds development
- Built-in design system ensures consistency
- Excellent dark/light theme support
- Zero runtime JavaScript for styling

**Why localStorage over Database?**
- Privacy-first design (no data collection)
- Zero infrastructure costs and complexity
- Offline functionality by default
- Perfect for MVP scope

**Why Node 20+?**
- Latest LTS version with optimal performance
- Required for Astro v5 compatibility
- Future-proof for Azure Functions expansion
- Enhanced TypeScript support

---
