# API Specification

Since Simple To-Do MVP uses localStorage for data persistence, this section defines the **client-side service layer APIs** that abstract data operations. This approach provides a clean interface that can later be replaced with server-side APIs without changing component code.

### Client-Side Service APIs

The application uses service classes that provide Promise-based APIs mimicking server-side patterns. This design choice enables seamless transition to Azure Functions APIs in future phases.

### TaskService API

**Purpose:** Manages all task-related operations with localStorage persistence and error handling.

```typescript
class TaskService {
  private static readonly STORAGE_KEY = 'simple-todo-tasks';
  private static readonly VERSION = 'v1';

  // GET /api/tasks equivalent
  static async getAllTasks(): Promise<Task[]> {
    try {
      const stored = localStorage.getItem(this.STORAGE_KEY);
      if (!stored) return [];
      
      const data = JSON.parse(stored);
      return data.tasks.map(this.deserializeTask);
    } catch (error) {
      console.error('Failed to load tasks:', error);
      return [];
    }
  }

  // POST /api/tasks equivalent  
  static async createTask(text: string): Promise<Task> {
    if (!text.trim() || text.length > 280) {
      throw new Error('Invalid task text: must be 1-280 characters');
    }

    const task: Task = {
      id: crypto.randomUUID(),
      text: text.trim(),
      completed: false,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    const tasks = await this.getAllTasks();
    tasks.unshift(task); // Add to beginning (newest first)
    await this.saveTasks(tasks);
    
    return task;
  }

  // PATCH /api/tasks/{id} equivalent
  static async updateTask(id: string, updates: Partial<Task>): Promise<Task> {
    const tasks = await this.getAllTasks();
    const taskIndex = tasks.findIndex(t => t.id === id && !t.deletedAt);
    
    if (taskIndex === -1) {
      throw new Error(`Task not found: ${id}`);
    }

    const updatedTask = {
      ...tasks[taskIndex],
      ...updates,
      updatedAt: new Date()
    };

    tasks[taskIndex] = updatedTask;
    await this.saveTasks(tasks);
    
    return updatedTask;
  }

  // DELETE /api/tasks/{id} equivalent (soft delete)
  static async deleteTask(id: string): Promise<void> {
    await this.updateTask(id, { deletedAt: new Date() });
  }

  // POST /api/tasks/{id}/restore equivalent
  static async restoreTask(id: string): Promise<Task> {
    const tasks = await this.getAllTasks();
    const task = tasks.find(t => t.id === id);
    
    if (!task?.deletedAt) {
      throw new Error(`Task not found or not deleted: ${id}`);
    }

    return await this.updateTask(id, { deletedAt: undefined });
  }

  // Utility methods
  private static async saveTasks(tasks: Task[]): Promise<void> {
    const data = {
      version: this.VERSION,
      tasks: tasks.map(this.serializeTask),
      lastModified: new Date().toISOString()
    };
    
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(data));
  }

  private static serializeTask(task: Task): any {
    return {
      ...task,
      createdAt: task.createdAt.toISOString(),
      updatedAt: task.updatedAt.toISOString(),
      deletedAt: task.deletedAt?.toISOString()
    };
  }

  private static deserializeTask(data: any): Task {
    return {
      ...data,
      createdAt: new Date(data.createdAt),
      updatedAt: new Date(data.updatedAt),
      deletedAt: data.deletedAt ? new Date(data.deletedAt) : undefined
    };
  }
}
```

### PreferenceService API

**Purpose:** Manages user preferences with validation and system preference detection.

```typescript
class PreferenceService {
  private static readonly STORAGE_KEY = 'simple-todo-preferences';
  private static readonly DEFAULT_PREFERENCES: UserPreferences = {
    theme: 'system',
    motionReduced: false,
    quotesEnabled: true,
    favoriteQuotes: []
  };

  // GET /api/preferences equivalent
  static async getPreferences(): Promise<UserPreferences> {
    try {
      const stored = localStorage.getItem(this.STORAGE_KEY);
      if (!stored) {
        return await this.initializePreferences();
      }
      
      const preferences = JSON.parse(stored);
      return { ...this.DEFAULT_PREFERENCES, ...preferences };
    } catch (error) {
      console.error('Failed to load preferences:', error);
      return await this.initializePreferences();
    }
  }

  // PATCH /api/preferences equivalent
  static async updatePreferences(updates: Partial<UserPreferences>): Promise<UserPreferences> {
    const current = await this.getPreferences();
    const updated = { ...current, ...updates };
    
    // Validation
    if (updates.theme && !['light', 'dark', 'system'].includes(updates.theme)) {
      throw new Error('Invalid theme preference');
    }

    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(updated));
    return updated;
  }

  // GET /api/preferences/theme/resolved equivalent
  static getResolvedTheme(preferences: UserPreferences): 'light' | 'dark' {
    if (preferences.theme !== 'system') {
      return preferences.theme;
    }
    
    // System preference detection
    return window.matchMedia('(prefers-color-scheme: dark)').matches 
      ? 'dark' 
      : 'light';
  }

  private static async initializePreferences(): Promise<UserPreferences> {
    const preferences = {
      ...this.DEFAULT_PREFERENCES,
      motionReduced: window.matchMedia('(prefers-reduced-motion: reduce)').matches
    };
    
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(preferences));
    return preferences;
  }
}
```

### QuoteService API

**Purpose:** Manages motivational quotes with rotation logic and favoriting.

```typescript
class QuoteService {
  private static readonly STORAGE_KEY = 'simple-todo-quote-cache';
  private static quotes: Quote[] = [
    {
      id: 'q1',
      text: 'The way to get started is to quit talking and begin doing.',
      author: 'Walt Disney',
      category: 'productivity',
      dateAdded: new Date('2024-01-01')
    },
    {
      id: 'q2', 
      text: 'Focus on being productive instead of busy.',
      author: 'Tim Ferriss',
      category: 'focus',
      dateAdded: new Date('2024-01-01')
    }
    // ... more quotes would be defined here
  ];

  // GET /api/quotes/daily equivalent
  static async getDailyQuote(): Promise<Quote> {
    const today = new Date().toDateString();
    const cached = this.getCachedQuote(today);
    
    if (cached) return cached;
    
    // Simple rotation based on date
    const dayIndex = new Date().getDate() % this.quotes.length;
    const quote = this.quotes[dayIndex];
    
    this.setCachedQuote(today, quote);
    return quote;
  }

  // GET /api/quotes/random equivalent
  static async getRandomQuote(): Promise<Quote> {
    const randomIndex = Math.floor(Math.random() * this.quotes.length);
    return this.quotes[randomIndex];
  }

  // POST /api/quotes/{id}/favorite equivalent
  static async toggleFavoriteQuote(quoteId: string, preferences: UserPreferences): Promise<UserPreferences> {
    const favoriteQuotes = [...preferences.favoriteQuotes];
    const index = favoriteQuotes.indexOf(quoteId);
    
    if (index === -1) {
      favoriteQuotes.push(quoteId);
    } else {
      favoriteQuotes.splice(index, 1);
    }
    
    return await PreferenceService.updatePreferences({ favoriteQuotes });
  }

  private static getCachedQuote(date: string): Quote | null {
    try {
      const cached = localStorage.getItem(this.STORAGE_KEY);
      if (!cached) return null;
      
      const data = JSON.parse(cached);
      return data[date] || null;
    } catch {
      return null;
    }
  }

  private static setCachedQuote(date: string, quote: Quote): void {
    try {
      const cached = JSON.parse(localStorage.getItem(this.STORAGE_KEY) || '{}');
      cached[date] = quote;
      localStorage.setItem(this.STORAGE_KEY, JSON.stringify(cached));
    } catch (error) {
      console.error('Failed to cache quote:', error);
    }
  }
}
```

### Future API Migration Path

When transitioning to Azure Functions, these service classes can be updated to call actual HTTP endpoints while maintaining the same Promise-based interface:

```typescript
// Future server-side API calls
static async createTask(text: string): Promise<Task> {
  const response = await fetch('/api/tasks', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text })
  });
  
  if (!response.ok) {
    throw new Error(`Failed to create task: ${response.status}`);
  }
  
  return await response.json();
}
```

This architecture provides clean separation between data operations and UI components while preparing for seamless cloud expansion.

---
