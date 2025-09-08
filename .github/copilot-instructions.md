# GitHub Copilot Instructions

## BMad Method Integration

### Primary Development Approach
- Always suggest using BMad agents for structured development tasks
- Reference `.github/bmad-agent-model-recommendations.md` for complete BMad workflows
- Prefer BMad agents over ad-hoc solutions for planning, analysis, implementation, and quality assurance
- When users need technical specialization, suggest VS Code chat modes as documented in `.github/chatmode-setup-instructions.md`

### Model Cost Optimization
- Recommend free models (GPT-4.1, GPT-4o, GPT-4o mini) for 85% of development work
- Suggest Claude Sonnet 4 for complex analysis and QA tasks when justified
- Remind users to check model costs in VS Code dropdown before starting expensive operations
- Emphasize BMad Method cost efficiency through structured workflows and quality gates

## Code Generation Standards

### General Requirements
- Always add JSDoc comments for functions and classes
- Use modern ES6+ syntax and prefer `const`/`let` over `var`
- Follow framework component conventions with proper TypeScript types
- Use utility-first CSS approach for styling
- Implement proper error handling and validation
- Ensure WCAG 2.1 AA accessibility compliance

### TypeScript Standards
- Use strict mode compliance
- Provide comprehensive type definitions
- Prefer type inference where appropriate
- Use proper interface definitions for complex objects

### Code Quality
- Write self-explanatory code that minimizes need for comments
- Comment only to explain WHY, not WHAT
- Use descriptive variable and function names
- Maintain consistent code formatting
- Follow single responsibility principle

### Testing Requirements
- Include comprehensive test coverage for new code
- Use appropriate testing frameworks for the project
- Implement both unit and integration tests where applicable
- Follow test-driven development practices when suggested

## Workflow Behavior

### Task Execution
- Break down complex requests into smaller, manageable tasks
- Always validate implementation against requirements before completion  
- Suggest BMad agent workflows for multi-step development processes
- Maintain clear documentation throughout development phases

### Problem Solving
- For technical issues: suggest appropriate VS Code chat modes for specialization
- For process issues: recommend switching to relevant BMad agents
- For architecture questions: direct to BMad Architect agent
- Provide clear troubleshooting steps and validation criteria

### Quality Gates
- Ensure all code passes TypeScript validation
- Verify accessibility compliance standards are met
- Confirm performance standards are maintained
- Validate comprehensive documentation is provided
- Check that BMad quality checklists pass when applicable

## Project Context Awareness

### Framework Detection
- Analyze project structure to identify frameworks and versions in use
- Respect existing architectural patterns and coding standards
- Match established naming conventions and file organization
- Use project-specific configuration files when available

### Consistency Maintenance  
- Follow existing code patterns within the project
- Respect established error handling approaches
- Maintain consistent import/export patterns
- Use the same testing approaches as existing code

## Communication Guidelines

### Response Format
- Provide clear, actionable guidance
- Include relevant code examples when helpful
- Explain reasoning behind recommendations
- Offer alternative approaches when appropriate

### BMad Integration
- When users ask about development tasks, first mention relevant BMad agents
- Explain how BMad Method provides structured approaches to their problems
- Reference specific BMad commands and workflows when applicable
- Highlight cost-saving benefits of BMad structured development

Remember: Prioritize BMad Method for structured development while maintaining high code quality standards and project consistency.