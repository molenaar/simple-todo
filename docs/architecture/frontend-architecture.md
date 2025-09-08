# Frontend Architecture

The frontend architecture leverages Astro's island architecture pattern with vanilla JavaScript and Tailwind CSS to create a performant, maintainable, and accessible user interface. This section details component organization, styling patterns, and client-side JavaScript architecture.

### Astro Component Architecture

The application follows Astro's component-first approach with clear separation between static and interactive elements:

```typescript
// src/layouts/BaseLayout.astro - Main application shell
---
interface Props {
  title: string;
  description?: string;
  canonicalURL?: string;
}

const { title, description = "Simple Todo App - Stay organized with ease", canonicalURL } = Astro.props;
---

<!DOCTYPE html>
<html lang="en" class="h-full">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{title}</title>
    <meta name="description" content={description} />
    {canonicalURL && <link rel="canonical" href={canonicalURL} />}
    
    <!-- Theme detection script (blocking to prevent FOUC) -->
    <script is:inline>
      (function() {
        const theme = localStorage.getItem('simple-todo:preferences:v1.0');
        if (theme) {
          const prefs = JSON.parse(theme);
          if (prefs.theme === 'dark' || 
              (prefs.theme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
            document.documentElement.classList.add('dark');
          }
        } else if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
          document.documentElement.classList.add('dark');
        }
      })();
    </script>
  </head>
  
  <body class="h-full bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800 transition-colors duration-300">
    <div id="app" class="h-full">
      <slot />
    </div>
    
    <!-- Global error boundary -->
    <div id="error-boundary" class="hidden fixed inset-0 bg-red-50 dark:bg-red-900/20 flex items-center justify-center z-50">
      <div class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-xl max-w-md mx-4">
        <h2 class="text-lg font-semibold text-red-600 dark:text-red-400 mb-2">Something went wrong</h2>
        <p id="error-message" class="text-gray-600 dark:text-gray-300 mb-4"></p>
        <button id="error-reload" class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded transition-colors">
          Reload Page
        </button>
      </div>
    </div>
  </body>
</html>
```

### Component Organization Strategy

Components are organized by functionality with clear boundaries between static and interactive elements:

```typescript
// src/components/ui/ - Reusable UI primitives
// Button.astro - Static button component
---
interface Props {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  type?: 'button' | 'submit' | 'reset';
  class?: string;
}

const { 
  variant = 'primary', 
  size = 'md', 
  disabled = false, 
  type = 'button',
  class: className = ''
} = Astro.props;

const baseClasses = 'inline-flex items-center justify-center font-medium rounded-lg transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2';

const variantClasses = {
  primary: 'bg-blue-600 hover:bg-blue-700 text-white focus:ring-blue-500 disabled:bg-blue-300',
  secondary: 'bg-gray-200 hover:bg-gray-300 text-gray-900 focus:ring-gray-500 disabled:bg-gray-100',
  danger: 'bg-red-600 hover:bg-red-700 text-white focus:ring-red-500 disabled:bg-red-300'
};

const sizeClasses = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-base',
  lg: 'px-6 py-3 text-lg'
};

const classes = [baseClasses, variantClasses[variant], sizeClasses[size], className].filter(Boolean).join(' ');
---

<button 
  type={type}
  disabled={disabled}
  class={classes}
>
  <slot />
</button>
```

```typescript
// src/components/features/ - Feature-specific components
// TaskManager.astro - Main task management interface (interactive island)
---
import TaskInput from './TaskInput.astro';
import TaskList from './TaskList.astro';
import TaskStats from './TaskStats.astro';
---

<div class="task-manager" data-component="task-manager">
  <header class="mb-8">
    <h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-2">
      Simple Todo
    </h1>
    <p class="text-gray-600 dark:text-gray-300">
      Stay organized with ease
    </p>
  </header>
  
  <!-- Task input - interactive -->
  <TaskInput />
  
  <!-- Task statistics - reactive -->
  <TaskStats />
  
  <!-- Task list - interactive -->
  <TaskList />
  
  <!-- Load task manager JavaScript -->
  <script>
    import { TaskManager } from '../scripts/components/TaskManager.js';
    
    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', initializeTaskManager);
    } else {
      initializeTaskManager();
    }
    
    function initializeTaskManager() {
      const container = document.querySelector('[data-component="task-manager"]');
      if (container) {
        new TaskManager(container);
      }
    }
  </script>
</div>
```

### Vanilla JavaScript Architecture

Client-side JavaScript follows a modular component pattern with clear separation of concerns:

```typescript
// src/scripts/services/ - Business logic layer
// TaskService.ts - Core task management
import type { Task, TaskStorage } from '../types/index.js';
import { StorageManager } from './StorageManager.js';
import { ValidationService } from './ValidationService.js';

export class TaskService {
  private static readonly STORAGE_KEY = 'simple-todo:tasks:v1.0';
  
  // Create new task with validation
  static async createTask(text: string): Promise<Task> {
    const trimmedText = text.trim();
    
    if (!ValidationService.isValidTaskText(trimmedText)) {
      throw new Error('Task text must be between 1 and 280 characters');
    }
    
    const task: Task = {
      id: this.generateUUID(),
      text: trimmedText,
      completed: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    const storage = await this.getTaskStorage();
    storage.tasks.unshift(task); // Add to beginning for newest-first display
    storage.lastModified = new Date().toISOString();
    
    await this.saveTaskStorage(storage);
    this.dispatchTaskEvent('task-created', { task });
    
    return task;
  }
  
  // Update existing task
  static async updateTask(id: string, updates: Partial<Task>): Promise<Task | null> {
    const storage = await this.getTaskStorage();
    const taskIndex = storage.tasks.findIndex(task => task.id === id && !task.deletedAt);
    
    if (taskIndex === -1) {
      return null;
    }
    
    const task = storage.tasks[taskIndex];
    const updatedTask = {
      ...task,
      ...updates,
      updatedAt: new Date().toISOString()
    };
    
    // Add completion timestamp if marking complete
    if (updates.completed === true && !task.completed) {
      updatedTask.completedAt = new Date().toISOString();
    }
    
    storage.tasks[taskIndex] = updatedTask;
    storage.lastModified = new Date().toISOString();
    
    await this.saveTaskStorage(storage);
    this.dispatchTaskEvent('task-updated', { task: updatedTask, previousTask: task });
    
    return updatedTask;
  }
  
  // Soft delete task (enables undo)
  static async deleteTask(id: string): Promise<boolean> {
    const storage = await this.getTaskStorage();
    const taskIndex = storage.tasks.findIndex(task => task.id === id);
    
    if (taskIndex === -1) {
      return false;
    }
    
    const task = storage.tasks[taskIndex];
    task.deletedAt = new Date().toISOString();
    task.updatedAt = new Date().toISOString();
    
    storage.lastModified = new Date().toISOString();
    await this.saveTaskStorage(storage);
    
    this.dispatchTaskEvent('task-deleted', { task });
    return true;
  }
  
  // Get active tasks (not soft-deleted)
  static async getActiveTasks(): Promise<Task[]> {
    const storage = await this.getTaskStorage();
    return storage.tasks
      .filter(task => !task.deletedAt)
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }
  
  // Custom event system for reactive updates
  private static dispatchTaskEvent(type: string, detail: any): void {
    const event = new CustomEvent(type, { detail, bubbles: true });
    document.dispatchEvent(event);
  }
  
  // Storage operations with error handling
  private static async getTaskStorage(): Promise<TaskStorage> {
    try {
      const stored = localStorage.getItem(this.STORAGE_KEY);
      
      if (!stored) {
        return {
          version: '1.0',
          lastModified: new Date().toISOString(),
          tasks: []
        };
      }
      
      const parsed = JSON.parse(stored);
      return ValidationService.validateTaskStorage(parsed) ? parsed : this.getDefaultStorage();
      
    } catch (error) {
      console.error('Failed to load tasks:', error);
      return this.getDefaultStorage();
    }
  }
  
  private static async saveTaskStorage(storage: TaskStorage): Promise<void> {
    try {
      const serialized = JSON.stringify(storage);
      localStorage.setItem(this.STORAGE_KEY, serialized);
      
      // Update storage metadata
      StorageManager.updateMetadata({
        taskCount: storage.tasks.filter(t => !t.deletedAt).length,
        lastModified: storage.lastModified
      });
      
    } catch (error) {
      if (error.name === 'QuotaExceededError') {
        // Attempt cleanup and retry
        const cleanupResult = await StorageManager.performCleanup();
        if (cleanupResult.removedTasks > 0) {
          localStorage.setItem(this.STORAGE_KEY, JSON.stringify(storage));
        } else {
          throw new Error('Storage quota exceeded - unable to save task');
        }
      } else {
        throw error;
      }
    }
  }
  
  private static generateUUID(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      const r = Math.random() * 16 | 0;
      const v = c == 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }
}
```

### Component JavaScript Pattern

Individual components use a consistent initialization and lifecycle pattern:

```typescript
// src/scripts/components/TaskInput.ts - Interactive task input component
export class TaskInput {
  private container: HTMLElement;
  private input: HTMLInputElement;
  private charCounter: HTMLElement;
  private submitButton: HTMLButtonElement;
  
  constructor(container: HTMLElement) {
    this.container = container;
    this.initializeElements();
    this.bindEvents();
    this.setupValidation();
  }
  
  private initializeElements(): void {
    this.input = this.container.querySelector('[data-task-input]') as HTMLInputElement;
    this.charCounter = this.container.querySelector('[data-char-counter]') as HTMLElement;
    this.submitButton = this.container.querySelector('[data-submit-button]') as HTMLButtonElement;
    
    if (!this.input || !this.charCounter || !this.submitButton) {
      throw new Error('TaskInput: Required elements not found');
    }
  }
  
  private bindEvents(): void {
    // Real-time validation
    this.input.addEventListener('input', this.handleInput.bind(this));
    this.input.addEventListener('keydown', this.handleKeyDown.bind(this));
    
    // Form submission
    this.container.addEventListener('submit', this.handleSubmit.bind(this));
    
    // Listen for external task events
    document.addEventListener('task-created', this.handleTaskCreated.bind(this));
  }
  
  private setupValidation(): void {
    // Initialize character counter
    this.updateCharacterCount();
    
    // Set initial button state
    this.updateSubmitButton();
  }
  
  private handleInput(event: Event): void {
    this.updateCharacterCount();
    this.updateSubmitButton();
    
    // Accessibility: announce character count for screen readers
    if (this.input.value.length > 250) {
      this.announceToScreenReader(`${280 - this.input.value.length} characters remaining`);
    }
  }
  
  private handleKeyDown(event: KeyboardEvent): void {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      this.submitTask();
    }
  }
  
  private async handleSubmit(event: Event): Promise<void> {
    event.preventDefault();
    await this.submitTask();
  }
  
  private async submitTask(): Promise<void> {
    const text = this.input.value.trim();
    
    if (!text || text.length > 280) {
      this.showValidationError('Please enter a task between 1 and 280 characters');
      return;
    }
    
    try {
      this.setLoading(true);
      await TaskService.createTask(text);
      // Task created event will trigger handleTaskCreated
    } catch (error) {
      this.showValidationError(error.message || 'Failed to create task');
    } finally {
      this.setLoading(false);
    }
  }
  
  private handleTaskCreated(event: CustomEvent): void {
    // Reset form after successful task creation
    this.input.value = '';
    this.updateCharacterCount();
    this.updateSubmitButton();
    
    // Maintain focus for rapid task entry
    this.input.focus();
    
    // Accessibility: announce success
    this.announceToScreenReader(`Task "${event.detail.task.text}" created successfully`);
  }
  
  private updateCharacterCount(): void {
    const length = this.input.value.length;
    const remaining = 280 - length;
    
    this.charCounter.textContent = `${remaining} characters remaining`;
    this.charCounter.className = remaining < 20 
      ? 'text-red-600 dark:text-red-400 font-medium'
      : 'text-gray-500 dark:text-gray-400';
  }
  
  private updateSubmitButton(): void {
    const text = this.input.value.trim();
    const isValid = text.length > 0 && text.length <= 280;
    
    this.submitButton.disabled = !isValid;
    this.submitButton.className = isValid
      ? 'bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500'
      : 'bg-gray-300 text-gray-500 px-4 py-2 rounded-lg cursor-not-allowed';
  }
  
  private setLoading(loading: boolean): void {
    this.input.disabled = loading;
    this.submitButton.disabled = loading;
    
    if (loading) {
      this.submitButton.innerHTML = '<span class="animate-spin">⏳</span> Creating...';
    } else {
      this.submitButton.textContent = 'Add Task';
    }
  }
  
  private showValidationError(message: string): void {
    // Show temporary error message
    const errorElement = document.createElement('div');
    errorElement.className = 'text-red-600 dark:text-red-400 text-sm mt-1';
    errorElement.textContent = message;
    
    // Remove any existing error
    const existingError = this.container.querySelector('.validation-error');
    if (existingError) {
      existingError.remove();
    }
    
    errorElement.classList.add('validation-error');
    this.input.parentNode?.insertBefore(errorElement, this.input.nextSibling);
    
    // Auto-remove after 3 seconds
    setTimeout(() => errorElement.remove(), 3000);
    
    // Accessibility: announce error
    this.announceToScreenReader(message);
  }
  
  private announceToScreenReader(message: string): void {
    const announcement = document.createElement('div');
    announcement.setAttribute('aria-live', 'polite');
    announcement.setAttribute('aria-atomic', 'true');
    announcement.className = 'sr-only';
    announcement.textContent = message;
    
    document.body.appendChild(announcement);
    setTimeout(() => announcement.remove(), 1000);
  }
}
```

### Tailwind CSS Architecture

The application uses Tailwind CSS v4 with Astro's official integration, following the framework guide for optimal configuration and performance:

```javascript
// tailwind.config.mjs - Tailwind configuration for Astro
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  darkMode: 'class', // Enable class-based dark mode
  theme: {
    extend: {
      colors: {
        // Custom color palette for the application
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
        gray: {
          50: '#f9fafb',
          100: '#f3f4f6',
          200: '#e5e7eb',
          300: '#d1d5db',
          400: '#9ca3af',
          500: '#6b7280',
          600: '#4b5563',
          700: '#374151',
          800: '#1f2937',
          900: '#111827',
        }
      },
      animation: {
        // Custom animations for task interactions
        'task-enter': 'task-enter 300ms ease-out forwards',
        'task-complete': 'task-complete 500ms ease-in-out',
        'task-delete': 'task-delete 300ms ease-in forwards',
        'fade-in': 'fade-in 200ms ease-out',
        'slide-up': 'slide-up 300ms ease-out',
      },
      keyframes: {
        'task-enter': {
          '0%': { transform: 'translateX(16px)', opacity: '0' },
          '100%': { transform: 'translateX(0)', opacity: '1' }
        },
        'task-complete': {
          '0%': { transform: 'scale(1)' },
          '50%': { transform: 'scale(1.05)' },
          '100%': { transform: 'scale(1)' }
        },
        'task-delete': {
          '0%': { transform: 'translateX(0)', opacity: '1' },
          '100%': { transform: 'translateX(-100%)', opacity: '0' }
        },
        'fade-in': {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' }
        },
        'slide-up': {
          '0%': { transform: 'translateY(16px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' }
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
      },
      maxWidth: {
        '8xl': '88rem',
      }
    },
  },
  plugins: [
    // Add form plugin for better form styling
    require('@tailwindcss/forms'),
  ],
}
```

The global CSS file integrates Tailwind with custom CSS properties for theme management:

```css
/* src/styles/global.css - Enhanced Tailwind integration */
@import 'tailwindcss/base';
@import 'tailwindcss/components';
@import 'tailwindcss/utilities';

/* Theme-aware CSS custom properties */
:root {
  /* Light theme colors using Tailwind color palette */
  --color-primary: theme('colors.blue.600');
  --color-primary-hover: theme('colors.blue.700');
  --color-surface: theme('colors.white');
  --color-surface-secondary: theme('colors.gray.50');
  --color-text: theme('colors.gray.900');
  --color-text-secondary: theme('colors.gray.600');
  --color-border: theme('colors.gray.200');
  --color-success: theme('colors.green.600');
  --color-warning: theme('colors.amber.600');
  --color-error: theme('colors.red.600');
  
  /* Animation durations following design system */
  --duration-fast: 150ms;
  --duration-normal: 300ms;
  --duration-slow: 500ms;
  
  /* Spacing scale aligned with Tailwind */
  --spacing-component: theme('spacing.6');
  --spacing-section: theme('spacing.12');
}

.dark {
  /* Dark theme colors using Tailwind color palette */
  --color-primary: theme('colors.blue.500');
  --color-primary-hover: theme('colors.blue.600');
  --color-surface: theme('colors.gray.800');
  --color-surface-secondary: theme('colors.gray.900');
  --color-text: theme('colors.gray.100');
  --color-text-secondary: theme('colors.gray.300');
  --color-border: theme('colors.gray.700');
  --color-success: theme('colors.green.500');
  --color-warning: theme('colors.amber.500');
  --color-error: theme('colors.red.500');
}

/* Base layer customizations */
@layer base {
  html {
    font-family: Inter, system-ui, sans-serif;
  }
  
  /* Improved focus visibility */
  *:focus-visible {
    @apply outline-none ring-2 ring-blue-500 ring-offset-2 dark:ring-offset-gray-800;
  }
}

/* Component layer for reusable patterns */
@layer components {
  .btn {
    @apply inline-flex items-center justify-center font-medium rounded-lg transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed;
  }
  
  .btn-primary {
    @apply btn bg-blue-600 hover:bg-blue-700 text-white focus-visible:ring-blue-500;
  }
  
  .btn-secondary {
    @apply btn bg-gray-200 hover:bg-gray-300 text-gray-900 focus-visible:ring-gray-500 dark:bg-gray-700 dark:hover:bg-gray-600 dark:text-gray-100;
  }
  
  .btn-danger {
    @apply btn bg-red-600 hover:bg-red-700 text-white focus-visible:ring-red-500;
  }
  
  .input {
    @apply block w-full rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:focus:border-blue-400 dark:focus:ring-blue-400;
  }
  
  .card {
    @apply bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700;
  }
  
  .task-item {
    @apply card p-4 transition-all duration-300 hover:shadow-md hover:border-gray-300 dark:hover:border-gray-600;
  }
  
  .task-item.completed {
    @apply opacity-75 bg-gray-50 dark:bg-gray-800/50;
  }
}

/* Utility layer for custom utilities */
@layer utilities {
  /* Accessibility-first animation control */
  @media (prefers-reduced-motion: reduce) {
    .animate-task-enter,
    .animate-task-complete,
    .animate-task-delete,
    .animate-fade-in,
    .animate-slide-up {
      animation: none !important;
    }
    
    * {
      transition-duration: 0.01ms !important;
      scroll-behavior: auto !important;
    }
  }
  
  /* High contrast mode support */
  @media (prefers-contrast: high) {
    .border {
      @apply border-2;
    }
    
    .text-gray-600 {
      @apply text-gray-900;
    }
    
    .dark .text-gray-300 {
      @apply text-white;
    }
  }
  
  /* Screen reader only utility */
  .sr-only {
    @apply absolute w-px h-px p-0 -m-px overflow-hidden whitespace-nowrap border-0;
  }
}

/* Custom animations that work with Tailwind classes */
.animate-task-enter {
  animation: task-enter var(--duration-normal) ease-out forwards;
}

.animate-task-complete {
  animation: task-complete var(--duration-slow) ease-in-out;
}

.animate-task-delete {
  animation: task-delete var(--duration-normal) ease-in forwards;
}
```

### Responsive Design Strategy

The application implements a mobile-first responsive approach using Tailwind's breakpoint system:

```typescript
// Responsive breakpoints following Tailwind defaults
const breakpoints = {
  sm: '640px',   // Small devices (phones in landscape)
  md: '768px',   // Medium devices (tablets)  
  lg: '1024px',  // Large devices (desktops)
  xl: '1280px',  // Extra large devices
  '2xl': '1536px' // 2x Extra large devices
};

// Component responsive patterns
// TaskInput.astro example
---
---
<div class="task-input-container">
  <form class="space-y-4 sm:space-y-0 sm:flex sm:gap-4">
    <div class="flex-1">
      <input 
        type="text"
        class="input text-sm sm:text-base"
        placeholder="What needs to be done?"
        maxlength="280"
        data-task-input
      />
      <div class="mt-1 text-xs sm:text-sm text-gray-500 dark:text-gray-400" data-char-counter>
        280 characters remaining
      </div>
    </div>
    <button 
      type="submit" 
      class="btn-primary w-full sm:w-auto px-4 py-2 sm:px-6"
      data-submit-button
    >
      <span class="hidden sm:inline">Add Task</span>
      <span class="sm:hidden">Add</span>
    </button>
  </form>
</div>
```

This frontend architecture ensures optimal performance through Astro's static generation, maintains accessibility standards, and provides a smooth user experience with progressive enhancement patterns. The modular JavaScript architecture enables easy testing and future expansion while the Tailwind CSS system ensures consistent, maintainable styling.

---
