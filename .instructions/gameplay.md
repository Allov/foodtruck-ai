# Food Truck Journey - Current Gameplay Implementation

## Core Experience
Food Truck Journey is a roguelike deck-building game where players travel across provinces in their food truck. The game combines resource management with deck building mechanics.

## Current Systems

### 1. Game Start
- Chef selection system
- Basic starting deck assignment
- Initial province loading

### 2. Province Navigation
- Node-based map navigation
- Location selection system
- Basic progress tracking
- Camera controls and map scrolling

### 3. Implemented Encounters

#### Battle Encounters
- Basic battle phase structure:
  - Preparation phase
  - Judging phase
  - Results phase
- Score calculation system
- Basic feedback system
- Rating system

#### Market Encounters
- Basic card purchasing
- Simple inventory management
- Resource tracking (money)

### 4. Core Systems

#### Deck Management
- Basic card collection
- Deck viewing (TAB key)
- Simple card interactions

#### Technical Features
- Scene management system
- Debug console (development mode)
- CRT shader effect (toggleable)
- Settings system
- Basic save/load functionality

## Controls

### Current Implementation
- Arrow Keys/WASD: Navigation
- Mouse: Selection
- ESC: Pause menu
- TAB: View deck

### Debug Features
- Console commands
- State inspection
- Performance monitoring
- Error logging

## Game States
- Main Menu
- Game Running
- Pause
- Game Over

## Technical Requirements
- LÖVE 11.4
- 60 FPS target
- 1280x720 resolution
