# Contributing Guide

## Commit Flow

We use a standardized commit flow through the `cm.bat` script to ensure code quality and consistency.

### The `cm.bat` Process

1. **Code Quality Check** (`check.bat`)
   - Runs Luacheck on the codebase
   - Validates code against `.luacheckrc` configuration
   - Fails if any issues are found
   - Success message: "No issues found!"
   - Failure message: "Issues found. Please review the output above."

2. **Test Suite** (`test.bat`)
   - Runs the full test suite
   - Tests are executed through LÖVE's test environment
   - Fails if any tests fail
   - Exit code 1 on failure, 0 on success

3. **Git Operations**
   - Only proceeds if both checks and tests pass
   - Stages all changes (`git add .`)
   - Opens your default editor for commit message
   - Completes the commit if message is provided

### Usage

```bash
cm.bat
```

### Chat-Assisted Commits

When using the AI assistant:
1. When you type "let's commit", the assistant will:
   - Enforce the `cm.bat` workflow
   - Review recent changes
   - Suggest a properly formatted commit message
   - Guide you through any check or test failures
2. Always use `cm.bat` - never commit directly through git
3. The assistant will help format commit messages following our standards

### Best Practices

1. **Commit Messages**
   - Use clear, descriptive messages
   - Follow the format:
     ```
     type: concise description

     - Detailed point 1
     - Detailed point 2
     ```
   - Types: feat, fix, docs, style, refactor, test, chore

2. **Before Committing**
   - Review your changes
   - Run `check.bat` separately if you want to fix issues first
   - Ensure all new code has tests

3. **Handling Failures**
   - If checks fail: Review Luacheck output and fix issues
   - If tests fail: Check test output and fix failing tests
   - Re-run `cm.bat` after fixes

### Example Workflow

```bash
# Make your changes
# Run commit script
cm.bat

# If checks fail, fix issues and retry
# If tests fail, fix tests and retry
# When both pass, enter commit message
```

### Related Files

- `cm.bat`: Main commit script
- `check.bat`: Code quality checks
- `test.bat`: Test runner
- `.luacheckrc`: Luacheck configuration
