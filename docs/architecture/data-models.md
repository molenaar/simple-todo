# Data Models

Based on the PRD requirements, I'll define the core data entities for Simple To-Do. These TypeScript interfaces will be shared across components and provide the foundation for data validation and localStorage persistence.

### Task

**Purpose:** Core entity representing a user's task with completion state and metadata for persistence and user experience.

**Key Attributes:**
- id: string - Unique identifier using crypto.randomUUID() for client-side generation
- text: string - Task description with 280 character limit (Twitter-like constraint)
- completed: boolean - Completion status for visual distinction and filtering
- createdAt: Date - Creation timestamp for chronological sorting (newest first)
- updatedAt: Date - Last modification timestamp for data integrity tracking
- deletedAt?: Date - Soft deletion timestamp for undo functionality within session

#### TypeScript Interface
```typescript
interface Task {
  id: string;
  text: string;
  completed: boolean;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date; // For soft deletion and undo functionality
}
```

#### Relationships
- Tasks are independent entities (no parent-child relationships in MVP)
- Tasks belong to a single user session (localStorage scoped)

### UserPreferences

**Purpose:** Stores user customization settings with persistence across browser sessions for personalized experience.

**Key Attributes:**
- theme: 'light' | 'dark' | 'system' - Theme preference with system detection fallback
- motionReduced: boolean - Accessibility preference for users with motion sensitivity
- quotesEnabled: boolean - Toggle for motivational quotes display
- lastActiveQuote?: string - Current quote ID for persistence across sessions
- favoriteQuotes: string[] - User-favorited quote IDs for future personalization

#### TypeScript Interface
```typescript
interface UserPreferences {
  theme: 'light' | 'dark' | 'system';
  motionReduced: boolean;
  quotesEnabled: boolean;
  lastActiveQuote?: string;
  favoriteQuotes: string[];
}
```

#### Relationships
- One UserPreferences per browser/device
- Independent of tasks (separate localStorage keys)

### Quote

**Purpose:** Motivational quotes data structure for inspiration system with rotation and favoriting capabilities.

**Key Attributes:**
- id: string - Unique identifier for quote referencing and favoriting
- text: string - Quote content with length validation (max 200 characters)
- author?: string - Quote attribution (optional for anonymous quotes)
- category: string - Theme categorization ('productivity', 'motivation', 'focus')
- dateAdded: Date - When quote was added to system for rotation algorithms

#### TypeScript Interface
```typescript
interface Quote {
  id: string;
  text: string;
  author?: string;
  category: 'productivity' | 'motivation' | 'focus' | 'general';
  dateAdded: Date;
}
```

#### Relationships
- Referenced by UserPreferences.lastActiveQuote and favoriteQuotes
- Stored as static collection with local caching

### AppState

**Purpose:** Runtime application state management for UI coordination and data persistence orchestration.

**Key Attributes:**
- tasks: Task[] - Current task collection with real-time updates
- preferences: UserPreferences - User settings with immediate UI reflection
- currentQuote: Quote | null - Active quote for display with rotation logic
- isLoading: boolean - Global loading state for user feedback
- lastSyncTime: Date - Last localStorage sync for data integrity

#### TypeScript Interface
```typescript
interface AppState {
  tasks: Task[];
  preferences: UserPreferences;
  currentQuote: Quote | null;
  isLoading: boolean;
  lastSyncTime: Date;
}
```

#### Relationships
- Aggregates all other data models
- Managed by TaskService and PreferenceService utilities
- Synced to localStorage on every state change

---
