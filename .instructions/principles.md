# Game Development Principles

## Core Values
- Code clarity and maintainability
- Modular design
- Performance optimization
- Clean git commit history

## Project Structure
- All game assets in `/assets`
- Game logic in `/src`
- Configuration in root directory
- Documentation in `.instructions`
- Ideas and brainstorming in `.ideas`

## Coding Standards
- Use clear variable names
- Comment complex logic
- Follow Lua best practices
- Keep functions small and focused
- Document public APIs

## Version Control
- Meaningful commit messages
- Feature branches for new additions
- Regular commits
- Tag important releases

## Development Priorities
1. Complete core systems before adding new features
2. Focus on user experience and feedback
3. Maintain documentation alongside code changes
4. Regular testing and quality assurance
5. Performance optimization as needed

## Testing Principles

### Automated Testing
- All critical systems must have unit tests
- Use `test.bat` for running the full test suite
- Tests must be atomic and independent
- Mock external dependencies when necessary

### Testing Tools
- `check.bat`: Code quality and syntax validation
- `test.bat`: Full test suite execution
- `stt.bat`: Test before launch
- Debug console for runtime testing

### Test Categories
1. Unit Tests
   - Card interactions
   - Scoring calculations
   - State management
   - Resource management

2. Integration Tests
   - Scene transitions
   - Encounter flow
   - Save/load operations
   - Resource cleanup

3. System Tests
   - Full gameplay loops
   - Performance benchmarks
   - Memory management
   - State persistence

### Testing Workflow
1. Write tests before implementing features
2. Run local tests before commits
3. Use debug tools for verification
4. Document test cases and expected results

### Debug Features
- Console commands for testing
- State inspection tools
- Performance monitoring
- Error logging and reporting

## Game-Specific Principles

### Scene Management
- Each scene is self-contained
- Scenes handle their own loading/cleanup
- Smooth transitions between scenes
- Clear scene lifecycle (init, enter, exit, destroy)

### Scene Structure
- MainMenu
- Game
- Pause
- Settings
- Credits

### Navigation Rules
- Clear navigation paths between scenes
- Consistent transition animations
- Proper state cleanup
- Resource management between transitions

## Logging Principles

### Print Usage
- `print()` statements should be used for temporary debugging only
- Temporary prints should be removed before committing
- System critical prints are not considered logs and should be maintained
- Critical system feedback should use direct `print()` for reliability

### Logger Usage
- Always prefer debugConsole logging methods over print():
  - `debugConsole:debug()` - For debug information
  - `debugConsole:info()` - For general information
  - `debugConsole:warn()` - For warnings
  - `debugConsole:error()` - For errors
  - `debugConsole:success()` - For success messages

### Implementation Guidelines
- Replace any non-temporary print with appropriate logger calls
- Critical system prints should be clearly commented as such
- Debug console must be initialized before any logging
- All logs are automatically saved to log files for debugging

### Log Message Format

#### Basic Format
- Component names should be in square brackets: `[ComponentName]`
- Use four spaces between multiple values
- Examples:
  ```lua
  debugConsole:info("[Settings] Initializing settings...")
  debugConsole:debug("[DeckFactory] Created starter deck with    22 cards")
  debugConsole:warn("[CardVisuals] Invalid state:    " .. state)
  ```

#### Component Context
- Always prefix component-specific logs with the component name in brackets
- Use consistent naming: `[ComponentName]` for classes/modules
- Examples:
  ```lua
  debugConsole:debug("[CardVisuals] State changed from    default    to    selected")
  debugConsole:info("[DeckFactory] Generating new deck")
  debugConsole:error("[Settings] Failed to save settings")
  ```

The debug console will automatically handle:
- Timestamps
- Log levels
- Message formatting
- Duplicate message grouping


