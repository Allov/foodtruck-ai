# Rating System

## Overview
Score-based rating system that evaluates player performance in battle encounters.

## Current Implementation

### Battle Ratings
Rating is determined by final score as percentage of target score:
- S: 200%+ of target score
- A: 150%+ of target score
- B: 120%+ of target score
- C: 100%+ of target score
- D: 70%+ of target score
- F: Below 70% of target score

### Impact
1. Rewards
   - Base money reward
   - Rating-based bonus:
     * S: +10 coins
     * A: +7 coins
     * B: +5 coins
     * C: +3 coins
     * D: +1 coin
     * F: No reward

2. Progression
   - F rating results in game over
   - Rating history tracked in chef stats
   - Best rating recorded as max rating

## Planned Features

### Reputation System
- Local reputation per province
- Global chef reputation
- Critic relationships
- Special achievement tracking

## Implementation Notes
- Rating calculated at battle end
- Based on total score vs target score
- Affects reward calculation
- Tracked in chef statistics
