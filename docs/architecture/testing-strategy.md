# Testing Strategy

The Simple To-Do application implements a comprehensive testing strategy that ensures code quality, functionality, accessibility, and performance across all components. This multi-layered approach provides confidence in deployments while maintaining development velocity.

### Testing Pyramid & Coverage Goals

The testing strategy follows the testing pyramid principle with specific coverage targets:

```typescript
// Testing coverage targets and strategy
export const TESTING_STRATEGY = {
  // Unit tests (70% of total tests)
  unit: {
    coverageTarget: 90,
    focus: ['services', 'utilities', 'validation', 'business-logic'],
    tools: ['Vitest', 'Testing Library'],
    location: 'src/**/*.test.ts'
  },
  
  // Integration tests (20% of total tests)
  integration: {
    coverageTarget: 80,
    focus: ['component-interactions', 'localStorage', 'event-flow'],
    tools: ['Vitest', 'JSDOM', 'Testing Library'],
    location: 'src/**/*.integration.test.ts'
  },
  
  // End-to-End tests (10% of total tests)
  e2e: {
    coverageTarget: 100, // Critical user journeys
    focus: ['user-workflows', 'cross-browser', 'accessibility'],
    tools: ['Playwright', 'Axe-core'],
    location: 'e2e/**/*.spec.ts'
  }
} as const;
```

### Unit Testing Implementation

Comprehensive unit testing for services, utilities, and business logic:

```typescript
// src/scripts/services/__tests__/TaskService.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TaskService } from '../TaskService';
import { ValidationService } from '../ValidationService';

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {};
  
  return {
    getItem: vi.fn((key: string) => store[key] || null),
    setItem: vi.fn((key: string, value: string) => {
      store[key] = value.toString();
    }),
    removeItem: vi.fn((key: string) => {
      delete store[key];
    }),
    clear: vi.fn(() => {
      store = {};
    })
  };
})();

Object.defineProperty(window, 'localStorage', {
  value: localStorageMock
});

describe('TaskService', () => {
  beforeEach(() => {
    localStorageMock.clear();
    vi.clearAllMocks();
    
    // Mock document.dispatchEvent for custom events
    vi.spyOn(document, 'dispatchEvent').mockImplementation(() => true);
  });

  describe('createTask', () => {
    it('should create a valid task with correct properties', async () => {
      const taskText = 'Test task';
      const task = await TaskService.createTask(taskText);
      
      expect(task).toMatchObject({
        text: taskText,
        completed: false,
        createdAt: expect.any(String),
        updatedAt: expect.any(String),
        id: expect.stringMatching(/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i)
      });
      
      expect(new Date(task.createdAt)).toBeInstanceOf(Date);
      expect(new Date(task.updatedAt)).toBeInstanceOf(Date);
    });

    it('should save task to localStorage with correct structure', async () => {
      const taskText = 'Test task';
      await TaskService.createTask(taskText);
      
      expect(localStorageMock.setItem).toHaveBeenCalledWith(
        'simple-todo:tasks:v1.0',
        expect.stringContaining(taskText)
      );
      
      const storedData = JSON.parse(localStorageMock.setItem.mock.calls[0][1]);
      expect(storedData).toMatchObject({
        version: '1.0',
        lastModified: expect.any(String),
        tasks: expect.arrayContaining([
          expect.objectContaining({ text: taskText })
        ])
      });
    });

    it('should dispatch task-created event', async () => {
      const taskText = 'Test task';
      await TaskService.createTask(taskText);
      
      expect(document.dispatchEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'task-created',
          detail: expect.objectContaining({
            task: expect.objectContaining({ text: taskText })
          })
        })
      );
    });

    it('should reject empty or invalid task text', async () => {
      await expect(TaskService.createTask('')).rejects.toThrow('Task text must be between 1 and 280 characters');
      await expect(TaskService.createTask('   ')).rejects.toThrow('Task text must be between 1 and 280 characters');
      await expect(TaskService.createTask('a'.repeat(281))).rejects.toThrow('Task text must be between 1 and 280 characters');
    });

    it('should handle localStorage quota exceeded error', async () => {
      // Mock quota exceeded error
      localStorageMock.setItem.mockImplementation(() => {
        const error = new Error('QuotaExceededError');
        error.name = 'QuotaExceededError';
        throw error;
      });
      
      // Mock StorageManager.performCleanup
      vi.doMock('../StorageManager', () => ({
        StorageManager: {
          performCleanup: vi.fn().mockResolvedValue({ removedTasks: 0 }),
          updateMetadata: vi.fn()
        }
      }));
      
      await expect(TaskService.createTask('Test task')).rejects.toThrow('Storage quota exceeded');
    });
  });

  describe('updateTask', () => {
    it('should update existing task and preserve timestamps', async () => {
      const originalTask = await TaskService.createTask('Original task');
      
      // Wait a bit to ensure different timestamp
      await new Promise(resolve => setTimeout(resolve, 10));
      
      const updatedTask = await TaskService.updateTask(originalTask.id, { 
        text: 'Updated task',
        completed: true 
      });
      
      expect(updatedTask).toMatchObject({
        id: originalTask.id,
        text: 'Updated task',
        completed: true,
        createdAt: originalTask.createdAt,
        updatedAt: expect.not.stringMatching(originalTask.updatedAt),
        completedAt: expect.any(String)
      });
    });

    it('should return null for non-existent task', async () => {
      const result = await TaskService.updateTask('non-existent-id', { completed: true });
      expect(result).toBeNull();
    });

    it('should not update soft-deleted tasks', async () => {
      const task = await TaskService.createTask('Test task');
      await TaskService.deleteTask(task.id); // Soft delete
      
      const result = await TaskService.updateTask(task.id, { completed: true });
      expect(result).toBeNull();
    });
  });

  describe('getActiveTasks', () => {
    it('should return only non-deleted tasks in correct order', async () => {
      const task1 = await TaskService.createTask('Task 1');
      const task2 = await TaskService.createTask('Task 2');
      const task3 = await TaskService.createTask('Task 3');
      
      await TaskService.deleteTask(task2.id); // Soft delete task2
      
      const activeTasks = await TaskService.getActiveTasks();
      
      expect(activeTasks).toHaveLength(2);
      expect(activeTasks[0].id).toBe(task3.id); // Newest first
      expect(activeTasks[1].id).toBe(task1.id);
      expect(activeTasks.find(t => t.id === task2.id)).toBeUndefined();
    });
  });
});

// src/scripts/services/__tests__/ValidationService.test.ts
describe('ValidationService', () => {
  describe('validateTask', () => {
    it('should validate correct task objects', () => {
      const validTask = {
        id: '550e8400-e29b-41d4-a716-446655440000',
        text: 'Valid task',
        completed: false,
        createdAt: '2025-09-08T10:00:00.000Z',
        updatedAt: '2025-09-08T10:00:00.000Z'
      };
      
      expect(ValidationService.validateTask(validTask)).toBe(true);
    });

    it('should reject invalid task objects', () => {
      const testCases = [
        { id: 'invalid-uuid', text: 'Test', completed: false, createdAt: '2025-09-08T10:00:00.000Z', updatedAt: '2025-09-08T10:00:00.000Z' },
        { id: '550e8400-e29b-41d4-a716-446655440000', text: '', completed: false, createdAt: '2025-09-08T10:00:00.000Z', updatedAt: '2025-09-08T10:00:00.000Z' },
        { id: '550e8400-e29b-41d4-a716-446655440000', text: 'a'.repeat(281), completed: false, createdAt: '2025-09-08T10:00:00.000Z', updatedAt: '2025-09-08T10:00:00.000Z' },
        { id: '550e8400-e29b-41d4-a716-446655440000', text: 'Test', completed: 'false', createdAt: '2025-09-08T10:00:00.000Z', updatedAt: '2025-09-08T10:00:00.000Z' },
        { id: '550e8400-e29b-41d4-a716-446655440000', text: 'Test', completed: false, createdAt: 'invalid-date', updatedAt: '2025-09-08T10:00:00.000Z' }
      ];
      
      testCases.forEach(testCase => {
        expect(ValidationService.validateTask(testCase)).toBe(false);
      });
    });
  });
});
```

### Integration Testing

Component integration and localStorage interaction testing:

```typescript
// src/components/__tests__/TaskManager.integration.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/dom';
import '@testing-library/jest-dom/vitest';
import { TaskManager } from '../TaskManager';

// Mock modules
vi.mock('../../scripts/services/TaskService');
vi.mock('../../scripts/services/PreferenceService');

describe('TaskManager Integration', () => {
  let container: HTMLElement;
  let taskManager: TaskManager;

  beforeEach(() => {
    // Setup DOM
    document.body.innerHTML = `
      <div data-component="task-manager">
        <form data-task-form>
          <input data-task-input type="text" maxlength="280" />
          <span data-char-counter>280 characters remaining</span>
          <button data-submit-button type="submit">Add Task</button>
        </form>
        <div data-task-stats>
          <span data-total-tasks>0</span> tasks,
          <span data-completed-tasks>0</span> completed
        </div>
        <div data-task-list></div>
      </div>
    `;
    
    container = document.querySelector('[data-component="task-manager"]')!;
    taskManager = new TaskManager(container);
    
    vi.clearAllMocks();
  });

  it('should create and display new task when form is submitted', async () => {
    const taskInput = screen.getByRole('textbox') as HTMLInputElement;
    const submitButton = screen.getByRole('button', { name: /add task/i });
    
    // Simulate user input
    fireEvent.input(taskInput, { target: { value: 'New integration test task' } });
    fireEvent.click(submitButton);
    
    // Wait for task creation and DOM update
    await waitFor(() => {
      expect(screen.getByText('New integration test task')).toBeInTheDocument();
    });
    
    // Verify stats update
    expect(screen.getByTestId('total-tasks')).toHaveTextContent('1');
    expect(screen.getByTestId('completed-tasks')).toHaveTextContent('0');
    
    // Verify input is cleared
    expect(taskInput.value).toBe('');
  });

  it('should update task completion status and stats', async () => {
    // Create a task first
    const taskInput = screen.getByRole('textbox') as HTMLInputElement;
    fireEvent.input(taskInput, { target: { value: 'Task to complete' } });
    fireEvent.submit(taskInput.closest('form')!);
    
    await waitFor(() => {
      expect(screen.getByText('Task to complete')).toBeInTheDocument();
    });
    
    // Find and click completion toggle
    const completionToggle = screen.getByRole('checkbox');
    fireEvent.click(completionToggle);
    
    // Wait for completion state update
    await waitFor(() => {
      expect(screen.getByTestId('completed-tasks')).toHaveTextContent('1');
      expect(completionToggle).toBeChecked();
    });
  });

  it('should handle task deletion with confirmation', async () => {
    // Create a task
    const taskInput = screen.getByRole('textbox') as HTMLInputElement;
    fireEvent.input(taskInput, { target: { value: 'Task to delete' } });
    fireEvent.submit(taskInput.closest('form')!);
    
    await waitFor(() => {
      expect(screen.getByText('Task to delete')).toBeInTheDocument();
    });
    
    // Find and click delete button
    const deleteButton = screen.getByRole('button', { name: /delete/i });
    fireEvent.click(deleteButton);
    
    // Confirm deletion in dialog
    await waitFor(() => {
      expect(screen.getByText(/delete.*task to delete/i)).toBeInTheDocument();
    });
    
    const confirmButton = screen.getByRole('button', { name: /confirm/i });
    fireEvent.click(confirmButton);
    
    // Wait for task removal
    await waitFor(() => {
      expect(screen.queryByText('Task to delete')).not.toBeInTheDocument();
      expect(screen.getByTestId('total-tasks')).toHaveTextContent('0');
    });
  });

  it('should handle localStorage errors gracefully', async () => {
    // Mock localStorage to throw quota exceeded error
    const originalSetItem = localStorage.setItem;
    localStorage.setItem = vi.fn(() => {
      throw new Error('QuotaExceededError');
    });
    
    const taskInput = screen.getByRole('textbox') as HTMLInputElement;
    fireEvent.input(taskInput, { target: { value: 'Task causing storage error' } });
    fireEvent.submit(taskInput.closest('form')!);
    
    // Wait for error handling
    await waitFor(() => {
      expect(screen.getByText(/storage.*full/i)).toBeInTheDocument();
    });
    
    // Restore localStorage
    localStorage.setItem = originalSetItem;
  });

  it('should respect reduced motion preferences', async () => {
    // Mock reduced motion preference
    Object.defineProperty(window, 'matchMedia', {
      value: vi.fn(() => ({
        matches: true, // prefers-reduced-motion: reduce
        addEventListener: vi.fn(),
        removeEventListener: vi.fn()
      }))
    });
    
    const taskInput = screen.getByRole('textbox') as HTMLInputElement;
    fireEvent.input(taskInput, { target: { value: 'Task with no animation' } });
    fireEvent.submit(taskInput.closest('form')!);
    
    await waitFor(() => {
      const taskElement = screen.getByText('Task with no animation').closest('[data-task-item]');
      expect(taskElement).not.toHaveClass('animate-task-enter');
    });
  });
});
```

### End-to-End Testing

Comprehensive E2E testing with Playwright covering critical user journeys:

```typescript
// e2e/task-management.spec.ts
import { test, expect } from '@playwright/test';
import { injectAxe, checkA11y } from 'axe-playwright';

test.describe('Task Management E2E', () => {
  test.beforeEach(async ({ page }) => {
    // Clear localStorage before each test
    await page.goto('/');
    await page.evaluate(() => localStorage.clear());
    await page.reload();
    
    // Inject axe for accessibility testing
    await injectAxe(page);
  });

  test('complete task creation workflow', async ({ page }) => {
    // Navigate to app
    await page.goto('/');
    
    // Verify initial state
    await expect(page.locator('[data-total-tasks]')).toHaveText('0');
    await expect(page.locator('[data-completed-tasks]')).toHaveText('0');
    
    // Create first task
    const taskInput = page.locator('[data-task-input]');
    await taskInput.fill('Complete E2E testing setup');
    await page.locator('[data-submit-button]').click();
    
    // Verify task appears
    await expect(page.locator('[data-task-item]')).toHaveCount(1);
    await expect(page.locator('[data-task-text]')).toHaveText('Complete E2E testing setup');
    await expect(page.locator('[data-total-tasks]')).toHaveText('1');
    
    // Verify input is cleared and focused
    await expect(taskInput).toHaveValue('');
    await expect(taskInput).toBeFocused();
    
    // Create second task
    await taskInput.fill('Write comprehensive tests');
    await taskInput.press('Enter'); // Test keyboard submission
    
    // Verify both tasks exist
    await expect(page.locator('[data-task-item]')).toHaveCount(2);
    await expect(page.locator('[data-total-tasks]')).toHaveText('2');
  });

  test('task completion and statistics', async ({ page }) => {
    await page.goto('/');
    
    // Create tasks
    const tasks = ['Task 1', 'Task 2', 'Task 3'];
    for (const task of tasks) {
      await page.locator('[data-task-input]').fill(task);
      await page.locator('[data-submit-button]').click();
    }
    
    // Complete first task
    const firstTaskToggle = page.locator('[data-task-item]').first().locator('[data-completion-toggle]');
    await firstTaskToggle.click();
    
    // Verify completion state
    await expect(firstTaskToggle).toBeChecked();
    await expect(page.locator('[data-completed-tasks]')).toHaveText('1');
    await expect(page.locator('[data-task-item]').first()).toHaveClass(/completed/);
    
    // Complete second task
    await page.locator('[data-task-item]').nth(1).locator('[data-completion-toggle]').click();
    
    // Verify updated stats
    await expect(page.locator('[data-completed-tasks]')).toHaveText('2');
    await expect(page.locator('[data-total-tasks]')).toHaveText('3');
    
    // Uncomplete first task
    await firstTaskToggle.click();
    await expect(page.locator('[data-completed-tasks]')).toHaveText('1');
  });

  test('task deletion with confirmation', async ({ page }) => {
    await page.goto('/');
    
    // Create a task
    await page.locator('[data-task-input]').fill('Task to be deleted');
    await page.locator('[data-submit-button]').click();
    
    // Click delete button
    await page.locator('[data-delete-button]').click();
    
    // Verify confirmation dialog
    const dialog = page.locator('[data-confirm-dialog]');
    await expect(dialog).toBeVisible();
    await expect(dialog.locator('[data-task-preview]')).toContainText('Task to be deleted');
    
    // Cancel deletion
    await page.locator('[data-cancel-button]').click();
    await expect(dialog).not.toBeVisible();
    await expect(page.locator('[data-task-item]')).toHaveCount(1);
    
    // Delete task
    await page.locator('[data-delete-button]').click();
    await page.locator('[data-confirm-button]').click();
    
    // Verify task is deleted
    await expect(page.locator('[data-task-item]')).toHaveCount(0);
    await expect(page.locator('[data-total-tasks]')).toHaveText('0');
    
    // Verify undo notification
    const undoNotification = page.locator('[data-undo-notification]');
    await expect(undoNotification).toBeVisible();
    await expect(undoNotification).toContainText('Task deleted');
  });

  test('undo functionality', async ({ page }) => {
    await page.goto('/');
    
    // Create and delete a task
    await page.locator('[data-task-input]').fill('Task to undo');
    await page.locator('[data-submit-button]').click();
    await page.locator('[data-delete-button]').click();
    await page.locator('[data-confirm-button]').click();
    
    // Click undo
    await page.locator('[data-undo-button]').click();
    
    // Verify task is restored
    await expect(page.locator('[data-task-item]')).toHaveCount(1);
    await expect(page.locator('[data-task-text]')).toHaveText('Task to undo');
    await expect(page.locator('[data-undo-notification]')).not.toBeVisible();
  });

  test('theme switching functionality', async ({ page }) => {
    await page.goto('/');
    
    // Verify initial theme (system default)
    await expect(page.locator('html')).not.toHaveClass('dark');
    
    // Click theme toggle
    await page.locator('[data-theme-toggle]').click();
    
    // Verify dark theme
    await expect(page.locator('html')).toHaveClass('dark');
    
    // Click again for light theme
    await page.locator('[data-theme-toggle]').click();
    await expect(page.locator('html')).not.toHaveClass('dark');
    
    // Click again for system theme
    await page.locator('[data-theme-toggle]').click();
    // Should respect system preference (varies by test environment)
  });

  test('character limit and validation', async ({ page }) => {
    await page.goto('/');
    
    const taskInput = page.locator('[data-task-input]');
    const charCounter = page.locator('[data-char-counter]');
    const submitButton = page.locator('[data-submit-button]');
    
    // Test character counting
    await taskInput.fill('Short task');
    await expect(charCounter).toHaveText('270 characters remaining');
    
    // Test near limit
    const longTask = 'A'.repeat(275);
    await taskInput.fill(longTask);
    await expect(charCounter).toHaveText('5 characters remaining');
    await expect(charCounter).toHaveClass(/text-red-/); // Warning color
    
    // Test over limit
    const overLimitTask = 'A'.repeat(285);
    await taskInput.fill(overLimitTask);
    await expect(submitButton).toBeDisabled();
    
    // Test empty input
    await taskInput.fill('');
    await expect(submitButton).toBeDisabled();
    
    // Test valid input enables submit
    await taskInput.fill('Valid task');
    await expect(submitButton).toBeEnabled();
  });

  test('accessibility compliance', async ({ page }) => {
    await page.goto('/');
    
    // Run initial accessibility check
    await checkA11y(page, null, {
      axeOptions: {
        runOnly: {
          type: 'tag',
          values: ['wcag2a', 'wcag2aa', 'wcag21aa']
        }
      }
    });
    
    // Create some tasks
    await page.locator('[data-task-input]').fill('Accessible task 1');
    await page.locator('[data-submit-button]').click();
    await page.locator('[data-task-input]').fill('Accessible task 2');
    await page.locator('[data-submit-button]').click();
    
    // Check accessibility with content
    await checkA11y(page, null, {
      axeOptions: {
        runOnly: {
          type: 'tag',
          values: ['wcag2a', 'wcag2aa', 'wcag21aa']
        }
      }
    });
    
    // Test keyboard navigation
    await page.keyboard.press('Tab'); // Should focus task input
    await expect(page.locator('[data-task-input]')).toBeFocused();
    
    await page.keyboard.press('Tab'); // Should focus submit button
    await expect(page.locator('[data-submit-button]')).toBeFocused();
    
    await page.keyboard.press('Tab'); // Should focus first task completion toggle
    await expect(page.locator('[data-completion-toggle]').first()).toBeFocused();
  });

  test('responsive design across breakpoints', async ({ page }) => {
    // Test mobile view
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');
    
    // Verify mobile-specific elements
    await expect(page.locator('[data-submit-button]')).toHaveText('Add'); // Shortened text
    
    // Test tablet view
    await page.setViewportSize({ width: 768, height: 1024 });
    await expect(page.locator('[data-submit-button]')).toHaveText('Add Task'); // Full text
    
    // Test desktop view
    await page.setViewportSize({ width: 1280, height: 720 });
    
    // Create tasks to test layout
    const tasks = ['Mobile task', 'Tablet task', 'Desktop task'];
    for (const task of tasks) {
      await page.locator('[data-task-input]').fill(task);
      await page.locator('[data-submit-button]').click();
    }
    
    // Verify all tasks are visible and properly laid out
    await expect(page.locator('[data-task-item]')).toHaveCount(3);
  });

  test('data persistence across page reloads', async ({ page }) => {
    await page.goto('/');
    
    // Create tasks and complete one
    await page.locator('[data-task-input]').fill('Persistent task 1');
    await page.locator('[data-submit-button]').click();
    await page.locator('[data-task-input]').fill('Persistent task 2');
    await page.locator('[data-submit-button]').click();
    
    await page.locator('[data-completion-toggle]').first().click();
    
    // Reload page
    await page.reload();
    
    // Verify data persistence
    await expect(page.locator('[data-task-item]')).toHaveCount(2);
    await expect(page.locator('[data-task-text]').first()).toHaveText('Persistent task 2'); // Newest first
    await expect(page.locator('[data-completion-toggle]').nth(1)).toBeChecked(); // Second task was completed
    await expect(page.locator('[data-total-tasks]')).toHaveText('2');
    await expect(page.locator('[data-completed-tasks]')).toHaveText('1');
  });
});
```

### Testing Configuration

Comprehensive testing setup with proper tooling configuration:

```javascript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import { resolve } from 'path';

export default defineConfig({
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    globals: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'src/test/',
        '**/*.d.ts',
        '**/*.config.*',
        'dist/',
        '.astro/'
      ],
      thresholds: {
        global: {
          branches: 80,
          functions: 90,
          lines: 90,
          statements: 90
        }
      }
    }
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
      '@test': resolve(__dirname, './src/test')
    }
  }
});
```

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  
  reporter: [
    ['html', { outputFolder: 'playwright-report' }],
    ['json', { outputFile: 'playwright-report/results.json' }],
    ['junit', { outputFile: 'playwright-report/results.xml' }]
  ],
  
  use: {
    baseURL: 'http://localhost:4321',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure'
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] }
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] }
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] }
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] }
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] }
    }
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:4321',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000
  }
});
```

This comprehensive testing strategy ensures high-quality, accessible, and reliable functionality across all user interactions, device types, and browser environments while maintaining fast feedback loops during development.

---
