---
mode: agent
---
# Git Workflow Management for this Project

## Overview
This prompt helps manage Git workflows for this project, including commit best practices, GitHub integration, and monitoring strategies.

## Core Git Commands

### Basic Workflow
```bash
# Check current status and branch
git status
git branch -a

# Stage specific files (preferred over git add .)
git add <specific-files>

# Commit with conventional commit format
git commit -m "type: description

- Detailed change 1
- Detailed change 2
- Impact or context"

# Push to remote
git push

# Monitor github action with GitHub CLI
gh run list --limit 3

# Select a run from the list that is running and watch it with
gh run watch <run-id>
```

## File Management Strategy

### Always Include
- Source code changes
- Configuration updates
- Documentation updates
- Infrastructure as Code (IaC) files
- Package/dependency files

### Always Exclude (via .gitignore)
- Virtual environments (.venv/, venv/, env/)
- IDE-specific settings (.claude/, user-specific .vscode settings)
- Build artifacts (dist/, node_modules/)
- Environment files (.env.local)
- Temporary files
- Azure storage emulator files (__azurite_db_*.json)

### Commit Granularity
- **One logical change per commit**
- **Related files together** (e.g., code + tests + docs)
- **Separate concerns** (features vs bug fixes vs config)

## GitHub Integration with CLI

### Repository Monitoring
```bash
# View repository in browser
gh repo view --web

# Check workflow status
gh run list --limit 3

# View specific workflow run
gh run view <run-id>

# Watch specific workflow run until its finished
gh run watch <run-id>

# Monitor issues and PRs
gh issue list
gh pr list
```

### Branch Management
```bash
# Create feature branch
git checkout -b feature/description

# Push new branch
git push -u origin feature/description

# Create PR from CLI
gh pr create --title "Title" --body "Description"

# Merge when ready
gh pr merge --squash
```

## Project-Specific Patterns

### Component Updates
Not specified yet

### Infrastructure Changes
Not specified yet

### Configuration Updates
For settings, environment, or development configuration:
```bash
git add .vscode/settings.json
git add .gitignore
git add *.json  # configuration files
git commit -m "config: update development environment

- VS Code workspace settings
- Python environment configuration
- Build and debug improvements"
```

## Monitoring and Review Process

### Pre-Commit Checklist
- [ ] Code builds successfully
- [ ] Tests pass (if applicable)
- [ ] No sensitive data in commit
- [ ] .gitignore updated for new file types
- [ ] Commit message follows convention
- [ ] Related files grouped together

### Post-Push Monitoring
```bash
# Check GitHub Actions status
gh run list --limit 3

# Monitor deployment status (if automated)
gh run watch <run-id>

# Check for security alerts
gh api repos/:owner/:repo/vulnerability-alerts
```

### Regular Maintenance
```bash
# Clean up merged branches
git branch --merged | Select-String -NotMatch 'main' | ForEach-Object { $_.Line.Trim() } | ForEach-Object { git branch -d $_ }

# Update from remote
git fetch --prune
git pull

# Check repository health
gh repo view --json diskUsage,issues,pullRequests
```

## Emergency Procedures

### Undo Last Commit (Not Pushed)
```bash
git reset --soft HEAD~1  # Keep changes staged
git reset HEAD~1         # Keep changes unstaged
git reset --hard HEAD~1  # Discard changes (dangerous!)
```

### Undo Pushed Commit
```bash
git revert <commit-hash>
git push
```

### Remove Sensitive Data
```bash
# Remove file from Git history (use with caution)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch <file>' \
  --prune-empty --tag-name-filter cat -- --all

# Force push (dangerous - coordinate with team)
git push --force-with-lease
```

## Integration with GitHub Features

### Using GitHub Issues
```bash
# Reference issues in commits
git commit -m "fix: resolve API timeout issue

Fixes #123
- Increase timeout values
- Add retry logic
- Improve error handling"
```

### Automated Workflows
- GitHub Actions trigger on push to main
- Deployment workflows for Azure Functions
- Security scanning for dependencies
- Code quality checks

### Project Board Integration
- Link commits to project cards
- Use conventional commits for automation
- Track feature progress through branches

## Best Practices Summary

1. **Atomic Commits**: One logical change per commit
2. **Clear Messages**: Descriptive commit messages with context
3. **Regular Pushes**: Don't let local changes accumulate
4. **Branch Strategy**: Use feature branches for larger changes
5. **Review Process**: Use PRs for significant changes
6. **Monitor Status**: Check GitHub Actions and deployments
7. **Security First**: Never commit secrets or sensitive data
8. **Documentation**: Update docs with code changes

## Quick Reference Commands

```bash
# Complete workflow in one go
git status
git add <files>
git commit -m "type: description"
git push
gh repo view --web

# Emergency: Quick commit and push
git add . && git commit -m "wip: save progress" && git push

# Monitor deployment
gh run list && gh run view $(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')

# Health check
git status && gh repo view --json issues,pullRequests,diskUsage
```

This prompt provides a comprehensive workflow for managing the ICS-2000-NodeJS project with proper Git practices and GitHub integration.
