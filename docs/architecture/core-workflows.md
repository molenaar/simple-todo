# Core Workflows

The following sequence diagrams illustrate critical user journeys from the PRD, showing component interactions and data flow. These workflows demonstrate how the architecture supports key functional requirements while maintaining performance and user experience goals.

### Workflow 1: Task Creation with Validation

This workflow demonstrates FR1 (task creation with immediate feedback) and shows how validation, persistence, and UI updates work together.

```mermaid
sequenceDiagram
    participant User
    participant TaskInput as TaskInput Component
    participant TaskManager as TaskManager
    participant TaskService as TaskService
    participant TaskList as TaskList
    participant AnimationEngine as AnimationEngine

    User->>TaskInput: Types task text
    TaskInput->>TaskInput: Validate length (≤280 chars)
    TaskInput->>User: Show character count
    
    User->>TaskInput: Presses ENTER
    TaskInput->>TaskInput: Validate non-empty
    TaskInput->>TaskManager: onTaskCreate(text)
    
    TaskManager->>TaskService: createTask(text)
    TaskService->>TaskService: Generate UUID, timestamps
    TaskService->>TaskService: Save to localStorage
    TaskService-->>TaskManager: Return new Task
    
    TaskManager->>TaskList: Update task collection
    TaskList->>TaskList: Re-render with new task (newest first)
    TaskManager->>AnimationEngine: animateTaskAddition(element)
    AnimationEngine-->>User: Smooth appearance animation
    
    TaskManager->>TaskInput: reset()
    TaskInput->>TaskInput: Clear input, maintain focus
    TaskInput-->>User: Ready for next task
```

### Workflow 2: Task Completion with Celebration

This workflow demonstrates FR3 (single-click completion) and FR4 (satisfying animations) while respecting accessibility preferences.

```mermaid
sequenceDiagram
    participant User
    participant TaskItem as TaskItem Component
    participant TaskManager as TaskManager
    participant TaskService as TaskService
    participant PreferenceService as PreferenceService
    participant AnimationEngine as AnimationEngine

    User->>TaskItem: Clicks completion toggle
    TaskItem->>TaskManager: onTaskToggle(taskId)
    
    TaskManager->>TaskService: updateTask(id, {completed: true})
    TaskService->>TaskService: Update task, save to localStorage
    TaskService-->>TaskManager: Return updated task
    
    TaskManager->>PreferenceService: getPreferences()
    PreferenceService-->>TaskManager: Return user preferences
    
    alt Motion not reduced
        TaskManager->>AnimationEngine: celebrateTaskCompletion(element)
        AnimationEngine->>AnimationEngine: Trigger confetti animation
        AnimationEngine-->>User: Celebration feedback
    else Motion reduced
        TaskManager->>TaskItem: Update visual state only
        TaskItem-->>User: Simple visual feedback
    end
    
    TaskManager->>TaskItem: Update task state
    TaskItem->>TaskItem: Apply completed styling (strikethrough)
    TaskItem-->>User: Visual completion confirmation
```

### Workflow 3: Theme Switching with System Detection

This workflow demonstrates FR8 (theme toggle with system preference detection) and shows how preferences persist across sessions.

```mermaid
sequenceDiagram
    participant User
    participant ThemeManager as ThemeManager
    participant PreferenceService as PreferenceService
    participant Browser
    participant AnimationEngine as AnimationEngine
    participant Components as All UI Components

    User->>ThemeManager: Clicks theme toggle
    ThemeManager->>PreferenceService: getPreferences()
    PreferenceService-->>ThemeManager: Current theme preference
    
    ThemeManager->>ThemeManager: Cycle theme (light→dark→system→light)
    
    alt New theme is 'system'
        ThemeManager->>Browser: Check prefers-color-scheme
        Browser-->>ThemeManager: Return system preference
        ThemeManager->>ThemeManager: Set resolved theme
    else New theme is 'light' or 'dark'
        ThemeManager->>ThemeManager: Use selected theme directly
    end
    
    ThemeManager->>PreferenceService: updatePreferences({theme: newTheme})
    PreferenceService->>PreferenceService: Save to localStorage
    PreferenceService-->>ThemeManager: Confirmation
    
    ThemeManager->>AnimationEngine: animateThemeTransition()
    AnimationEngine->>Components: Update CSS custom properties
    Components->>Components: Smooth color transitions
    AnimationEngine-->>User: Smooth theme change
    
    ThemeManager-->>User: Visual theme update complete
```

### Workflow 4: Daily Quote Display with Caching

This workflow demonstrates FR7 (daily motivational quotes with refresh) and shows efficient caching to avoid repetitive selections.

```mermaid
sequenceDiagram
    participant User
    participant QuoteDisplay as QuoteDisplay Component
    participant QuoteService as QuoteService
    participant LocalStorage
    participant PreferenceService as PreferenceService

    User->>QuoteDisplay: Page loads / daily refresh
    QuoteDisplay->>PreferenceService: getPreferences()
    PreferenceService-->>QuoteDisplay: User preferences
    
    alt Quotes enabled
        QuoteDisplay->>QuoteService: getDailyQuote()
        QuoteService->>LocalStorage: Check cached quote for today
        
        alt Quote cached for today
            LocalStorage-->>QuoteService: Return cached quote
        else No cached quote
            QuoteService->>QuoteService: Calculate daily quote (date-based rotation)
            QuoteService->>LocalStorage: Cache quote for today
            LocalStorage-->>QuoteService: Confirmation
        end
        
        QuoteService-->>QuoteDisplay: Return daily quote
        QuoteDisplay->>QuoteDisplay: Render quote with responsive typography
        QuoteDisplay-->>User: Display motivational quote
        
        User->>QuoteDisplay: Clicks refresh quote
        QuoteDisplay->>QuoteService: getRandomQuote()
        QuoteService-->>QuoteDisplay: Return different random quote
        QuoteDisplay->>QuoteDisplay: Update display
        QuoteDisplay-->>User: Show new quote
        
    else Quotes disabled
        QuoteDisplay->>QuoteDisplay: Hide quote section
    end
```

### Workflow 5: Task Deletion with Undo Support

This workflow demonstrates FR5 (delete confirmation) and FR6 (undo functionality) showing how soft deletion enables recovery.

```mermaid
sequenceDiagram
    participant User
    participant TaskItem as TaskItem Component
    participant ConfirmDialog as Confirmation Dialog
    participant TaskManager as TaskManager
    participant TaskService as TaskService
    participant UndoNotification as Undo Notification

    User->>TaskItem: Clicks delete button
    TaskItem->>ConfirmDialog: Show confirmation dialog
    ConfirmDialog->>ConfirmDialog: Display task preview
    ConfirmDialog-->>User: "Delete '[task text]'?"
    
    User->>ConfirmDialog: Confirms deletion
    ConfirmDialog->>TaskManager: onTaskDelete(taskId)
    
    TaskManager->>TaskService: deleteTask(taskId) // Soft delete
    TaskService->>TaskService: Set deletedAt timestamp
    TaskService->>TaskService: Save to localStorage
    TaskService-->>TaskManager: Deletion confirmed
    
    TaskManager->>TaskItem: Remove from display
    TaskManager->>UndoNotification: Show undo option
    UndoNotification-->>User: "Task deleted. Undo?"
    
    alt User clicks Undo (within session)
        User->>UndoNotification: Clicks undo
        UndoNotification->>TaskManager: onTaskRestore(taskId)
        TaskManager->>TaskService: restoreTask(taskId)
        TaskService->>TaskService: Clear deletedAt timestamp
        TaskService-->>TaskManager: Task restored
        TaskManager->>TaskItem: Re-add to display
        TaskManager->>UndoNotification: Hide undo notification
    else User ignores / session ends
        UndoNotification->>UndoNotification: Auto-hide after timeout
        Note over TaskService: Soft deleted tasks remain in storage<br/>for potential future cleanup
    end
```

### Workflow 6: Error Handling and Recovery

This workflow demonstrates NFR5 (localStorage limitations handling) and shows graceful error recovery patterns.

```mermaid
sequenceDiagram
    participant User
    participant TaskInput as TaskInput Component
    participant TaskManager as TaskManager
    participant TaskService as TaskService
    participant LocalStorage
    participant ErrorHandler as Error Handler

    User->>TaskInput: Creates new task
    TaskInput->>TaskManager: onTaskCreate(text)
    TaskManager->>TaskService: createTask(text)
    
    TaskService->>LocalStorage: Attempt to save task
    
    alt Storage successful
        LocalStorage-->>TaskService: Success
        TaskService-->>TaskManager: Return new task
        TaskManager-->>User: Normal success flow
        
    else Storage quota exceeded
        LocalStorage-->>TaskService: QuotaExceededError
        TaskService->>TaskService: Attempt cleanup of deleted tasks
        TaskService->>LocalStorage: Retry save operation
        
        alt Retry successful
            LocalStorage-->>TaskService: Success after cleanup
            TaskService-->>TaskManager: Return task with warning
            TaskManager->>ErrorHandler: Show storage warning
            ErrorHandler-->>User: "Storage nearly full - consider cleanup"
            
        else Retry failed
            TaskService-->>TaskManager: Throw storage error
            TaskManager->>ErrorHandler: Handle critical error
            ErrorHandler->>ErrorHandler: Show user-friendly message
            ErrorHandler-->>User: "Unable to save task - storage full"
            ErrorHandler->>ErrorHandler: Suggest data export
        end
        
    else Other storage error
        LocalStorage-->>TaskService: Generic error
        TaskService-->>TaskManager: Propagate error
        TaskManager->>ErrorHandler: Handle error gracefully
        ErrorHandler-->>User: "Temporary issue - please try again"
    end
```

These workflows demonstrate how the architecture supports all PRD requirements while maintaining excellent user experience through proper error handling, accessibility considerations, and performance optimization.

---
