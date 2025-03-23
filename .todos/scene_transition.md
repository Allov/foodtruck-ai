# Scene Transitions Standardization

## Core Issues
1. Scattered navigation logic across scenes
2. Inconsistent ESC/TAB behavior
3. Redundant transition code
4. Mixed responsibilities

## Solution Approach

### 1. Centralize Navigation
- Move common navigation to GameManager
- Define clear scene categories (gameplay, menu, viewer)
- Standardize transition patterns

### 2. Scene Manager Enhancement
- Add basic scene history
- Implement common transition hooks
- Handle state cleanup

### 3. Scene Cleanup
- Remove redundant navigation code
- Delegate to GameManager
- Keep only scene-specific logic

## Key Files
- src/gameManager.lua
- src/sceneManager.lua
- src/scenes/*.lua

## Success Criteria
1. Navigation logic lives in GameManager
2. Scenes handle only unique behavior
3. Consistent user experience