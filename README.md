# Food Truck Journey

A roguelike deck-building game where you travel across provinces in your food truck, facing cooking challenges and building your culinary reputation.

## Project Overview

### Core Systems
- Deck building with cooking theme
- Procedural province generation
- Dynamic encounter system
- Reputation and progression mechanics

### Game Modes
- Story Mode: Rise from food truck rookie to culinary legend
- Daily Challenges: Fixed-seed runs
- Custom Kitchen: Build your starting deck
- Endless Journey: Infinite mode

## Getting Started

### Prerequisites
1. Install LÖVE 11.4
2. Install Visual Studio Code with Lua extension
3. Clone this repository

### Development Setup
- Use `st.bat` for development with debugging
- Use `check.bat` to run code quality checks
- Use `cm.bat` for quick commits
- Use `stt.bat` to run tests before launch

### Running the Game
- Development: Run `st.bat` or use VSCode debugger
- Production: Run `lovec .`

## Project Structure

### Source Code Organization
- Scene Management
- Encounter System
- Battle Mechanics
- Debug Tools
- Shader Effects
- State Management

### Documentation Categories
- Instructions & Guidelines
- Design Documents
- Progress Tracking
- Technical Specifications

## Features

### Gameplay Elements
- Dynamic deck building
- Province exploration
- Multiple encounter types:
  - Cooking battles
  - Market visits
  - Random events
  - Story moments
- Reputation system
- Resource management

### Technical Features
- Scene management system
- Debug console with logging
- CRT shader effect
- State persistence
- Modular encounter system

## Development Guidelines

### Git Workflow
1. Create feature branches
2. Make atomic commits
3. Use descriptive commit messages
4. Review before merging

### Code Style
- Follow Lua best practices
- Document public interfaces
- Keep functions focused
- Test critical components

### Asset Guidelines
- Follow naming conventions
- Optimize before commit
- Update asset registry
- Version control binaries

## Current Status

### Completed Features
- Basic scene management
- Encounter framework
- Debug tools
- Core navigation
- Basic battle system
- Development tooling

### In Development
- Card combination system
- Advanced battle mechanics
- UI/UX improvements
- Feedback systems
- Sound implementation

### Planned Features
- Save/load system
- Achievement system
- Additional encounter types
- Extended story content
- Community features

## Contributing
1. Review development principles
2. Follow coding standards
3. Test thoroughly
4. Document changes

## Debug Features

### Debug Console Commands
Toggle console with backtick (`) key. Available commands:
- `help`: Show available commands
- `clear`: Clear console history
- `version`: Show game and LÖVE version
- `stats`: Display project statistics
- `debug`: Toggle debug information
- `scene <name>`: Switch to specified scene
- `scenes`: List all available scenes
- `spawn <type> <x> <y>`: Spawn enemy at position
- `win`: Win current battle
- `lose`: Lose current battle
- `mem`: Show memory usage
- `gc`: Force garbage collection
- `cash <amount>`: Add cash to player
- `state`: Show current game state

### Console Controls
- F11: Toggle fullscreen
- PgUp/PgDn: Scroll console history
- Enter: Execute command
- Mouse wheel: Scroll console

### Additional Debug Tools
- VSCode debugging support
- Performance monitoring
- State inspection tools
- Logging system

## License
MIT

