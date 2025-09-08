# Database Schema

The Simple To-Do application uses localStorage as its primary data persistence layer for the MVP. This section defines the storage structure, validation patterns, and optimization strategies that ensure data integrity and performance.

### localStorage Schema Structure

The application uses a structured approach to localStorage with namespaced keys and versioned schemas to support future migrations:

```typescript
// Root namespace for all application data
const STORAGE_PREFIX = 'simple-todo';
const SCHEMA_VERSION = '1.0';

// Storage keys with consistent namespacing
enum StorageKeys {
  TASKS = `${STORAGE_PREFIX}:tasks:v${SCHEMA_VERSION}`,
  PREFERENCES = `${STORAGE_PREFIX}:preferences:v${SCHEMA_VERSION}`,
  QUOTES_CACHE = `${STORAGE_PREFIX}:quotes:v${SCHEMA_VERSION}`,
  METADATA = `${STORAGE_PREFIX}:metadata:v${SCHEMA_VERSION}`
}

// Application metadata for storage management
interface StorageMetadata {
  version: string;
  createdAt: string; // ISO timestamp
  lastModified: string; // ISO timestamp
  taskCount: number;
  storageSize: number; // Estimated bytes
}
```

### Task Storage Schema

Tasks are stored as an array of Task objects with comprehensive metadata for future expansion:

```typescript
// Primary task storage structure
interface TaskStorage {
  version: string;
  lastModified: string; // ISO timestamp
  tasks: Task[];
}

// Individual task with complete metadata
interface Task {
  id: string; // UUID v4
  text: string; // User-entered task description
  completed: boolean;
  createdAt: string; // ISO timestamp
  updatedAt: string; // ISO timestamp
  completedAt?: string; // ISO timestamp, optional
  deletedAt?: string; // ISO timestamp for soft deletion
  priority?: 'low' | 'medium' | 'high'; // Future expansion
  tags?: string[]; // Future expansion
  dueDate?: string; // ISO timestamp, future expansion
}

// Example localStorage entry
const exampleTaskStorage: TaskStorage = {
  version: "1.0",
  lastModified: "2025-09-08T10:30:00.000Z",
  tasks: [
    {
      id: "550e8400-e29b-41d4-a716-446655440000",
      text: "Complete architecture documentation",
      completed: false,
      createdAt: "2025-09-08T10:15:00.000Z",
      updatedAt: "2025-09-08T10:15:00.000Z"
    },
    {
      id: "550e8400-e29b-41d4-a716-446655440001",
      text: "Review PRD requirements",
      completed: true,
      createdAt: "2025-09-08T09:00:00.000Z",
      updatedAt: "2025-09-08T09:45:00.000Z",
      completedAt: "2025-09-08T09:45:00.000Z"
    }
  ]
};
```

### User Preferences Storage

Preferences are stored as a flat structure for efficient access and updates:

```typescript
// User preferences with default values
interface UserPreferences {
  version: string;
  theme: 'light' | 'dark' | 'system'; // Default: 'system'
  reducedMotion: boolean; // Default: respects prefers-reduced-motion
  showQuotes: boolean; // Default: true
  taskSortOrder: 'created' | 'updated' | 'alphabetical'; // Default: 'created'
  maxTasks: number; // Default: 1000 (performance consideration)
  confirmDelete: boolean; // Default: true
  lastModified: string; // ISO timestamp
}

// Example preferences storage
const examplePreferences: UserPreferences = {
  version: "1.0",
  theme: "system",
  reducedMotion: false,
  showQuotes: true,
  taskSortOrder: "created",
  maxTasks: 1000,
  confirmDelete: true,
  lastModified: "2025-09-08T10:30:00.000Z"
};
```

### Quote Cache Storage

Daily quotes are cached to ensure consistent experience and reduce computation:

```typescript
// Quote cache with rotation tracking
interface QuoteCacheStorage {
  version: string;
  currentDate: string; // YYYY-MM-DD format
  dailyQuoteIndex: number; // Current quote rotation index
  lastRefreshDate: string; // YYYY-MM-DD format
  customQuotes: Quote[]; // User-added quotes (future expansion)
  lastModified: string; // ISO timestamp
}

// Individual quote structure
interface Quote {
  id: string; // UUID for user quotes, index for built-in
  text: string;
  author?: string;
  category?: 'motivation' | 'productivity' | 'mindfulness'; // Future expansion
  isCustom: boolean; // Differentiates user vs. built-in quotes
}

// Example quote cache
const exampleQuoteCache: QuoteCacheStorage = {
  version: "1.0",
  currentDate: "2025-09-08",
  dailyQuoteIndex: 42,
  lastRefreshDate: "2025-09-08",
  customQuotes: [],
  lastModified: "2025-09-08T10:30:00.000Z"
};
```

### Data Validation Patterns

Comprehensive validation ensures data integrity across all storage operations:

```typescript
// Schema validation utilities
class StorageValidator {
  
  // Task validation with comprehensive checks
  static validateTask(task: unknown): task is Task {
    if (typeof task !== 'object' || task === null) return false;
    
    const t = task as any;
    return (
      typeof t.id === 'string' &&
      this.isValidUUID(t.id) &&
      typeof t.text === 'string' &&
      t.text.length > 0 &&
      t.text.length <= 280 && // PRD requirement
      typeof t.completed === 'boolean' &&
      typeof t.createdAt === 'string' &&
      this.isValidISOTimestamp(t.createdAt) &&
      typeof t.updatedAt === 'string' &&
      this.isValidISOTimestamp(t.updatedAt) &&
      (t.completedAt === undefined || this.isValidISOTimestamp(t.completedAt)) &&
      (t.deletedAt === undefined || this.isValidISOTimestamp(t.deletedAt))
    );
  }
  
  // Preferences validation with type safety
  static validatePreferences(prefs: unknown): prefs is UserPreferences {
    if (typeof prefs !== 'object' || prefs === null) return false;
    
    const p = prefs as any;
    return (
      typeof p.version === 'string' &&
      ['light', 'dark', 'system'].includes(p.theme) &&
      typeof p.reducedMotion === 'boolean' &&
      typeof p.showQuotes === 'boolean' &&
      ['created', 'updated', 'alphabetical'].includes(p.taskSortOrder) &&
      typeof p.maxTasks === 'number' &&
      p.maxTasks > 0 &&
      p.maxTasks <= 10000 &&
      typeof p.confirmDelete === 'boolean'
    );
  }
  
  // Utility validation methods
  static isValidUUID(uuid: string): boolean {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    return uuidRegex.test(uuid);
  }
  
  static isValidISOTimestamp(timestamp: string): boolean {
    const date = new Date(timestamp);
    return !isNaN(date.getTime()) && date.toISOString() === timestamp;
  }
}
```

### Storage Optimization Strategies

Performance and space optimization patterns for localStorage management:

```typescript
// Storage management utilities
class StorageManager {
  
  // Calculate storage usage for monitoring
  static getStorageStats(): StorageStats {
    let totalSize = 0;
    let appSize = 0;
    
    for (let key in localStorage) {
      const itemSize = localStorage.getItem(key)?.length || 0;
      totalSize += itemSize;
      
      if (key.startsWith(STORAGE_PREFIX)) {
        appSize += itemSize;
      }
    }
    
    return {
      totalSize,
      appSize,
      availableSpace: 5 * 1024 * 1024 - totalSize, // 5MB typical limit
      taskCount: this.getTaskCount(),
      utilizationPercent: (totalSize / (5 * 1024 * 1024)) * 100
    };
  }
  
  // Cleanup strategy for storage optimization
  static performCleanup(): CleanupResult {
    const tasks = this.getTasks();
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    
    // Remove tasks soft-deleted more than 30 days ago
    const cleanTasks = tasks.filter(task => {
      if (!task.deletedAt) return true;
      const deletedDate = new Date(task.deletedAt);
      return deletedDate > thirtyDaysAgo;
    });
    
    const removedCount = tasks.length - cleanTasks.length;
    
    if (removedCount > 0) {
      this.saveTasks(cleanTasks);
    }
    
    return {
      removedTasks: removedCount,
      newStorageSize: this.getStorageStats().appSize,
      freedSpace: this.calculateFreedSpace(removedCount)
    };
  }
  
  // Batch operations for performance
  static batchUpdateTasks(updates: TaskUpdate[]): void {
    const tasks = this.getTasks();
    const taskMap = new Map(tasks.map(task => [task.id, task]));
    
    // Apply all updates in memory
    updates.forEach(update => {
      const task = taskMap.get(update.id);
      if (task) {
        Object.assign(task, update.changes, {
          updatedAt: new Date().toISOString()
        });
      }
    });
    
    // Single write operation
    this.saveTasks(Array.from(taskMap.values()));
  }
}

// Supporting interfaces
interface StorageStats {
  totalSize: number;
  appSize: number;
  availableSpace: number;
  taskCount: number;
  utilizationPercent: number;
}

interface CleanupResult {
  removedTasks: number;
  newStorageSize: number;
  freedSpace: number;
}

interface TaskUpdate {
  id: string;
  changes: Partial<Task>;
}
```

### Migration Strategy

Forward-compatible migration system for future schema updates:

```typescript
// Migration system for schema evolution
class SchemaMigrator {
  
  // Detect and migrate legacy data
  static migrateToCurrentVersion(): MigrationResult {
    const currentVersion = SCHEMA_VERSION;
    const metadata = this.getStorageMetadata();
    
    if (!metadata || metadata.version !== currentVersion) {
      return this.performMigration(metadata?.version || '0.0', currentVersion);
    }
    
    return { migrated: false, fromVersion: currentVersion, toVersion: currentVersion };
  }
  
  // Version-specific migration logic
  private static performMigration(fromVersion: string, toVersion: string): MigrationResult {
    let migrationSteps: MigrationStep[] = [];
    
    // Example: Migrating from hypothetical 0.9 to 1.0
    if (fromVersion === '0.9' && toVersion === '1.0') {
      migrationSteps = [
        { step: 'add-uuid-to-tasks', description: 'Convert numeric IDs to UUIDs' },
        { step: 'add-timestamps', description: 'Add createdAt/updatedAt timestamps' },
        { step: 'normalize-preferences', description: 'Update preference structure' }
      ];
    }
    
    // Execute migration steps
    migrationSteps.forEach(step => this.executeMigrationStep(step));
    
    // Update metadata
    this.updateStorageMetadata({ version: toVersion });
    
    return {
      migrated: true,
      fromVersion,
      toVersion,
      steps: migrationSteps
    };
  }
}

interface MigrationResult {
  migrated: boolean;
  fromVersion: string;
  toVersion: string;
  steps?: MigrationStep[];
}

interface MigrationStep {
  step: string;
  description: string;
}
```

This database schema design ensures data integrity, performance optimization, and future expandability while maintaining the simplicity required for the MVP localStorage implementation. The schema supports all PRD requirements while preparing for potential future migrations to server-side storage.

---
