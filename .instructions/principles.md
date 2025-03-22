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
