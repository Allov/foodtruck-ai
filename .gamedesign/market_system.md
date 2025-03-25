# Market System

## Overview
Resource acquisition system where players can purchase new cards for their deck.

## Current Implementation

### Market Types
1. Farmers Market
   - Fresh ingredients focus
   - 4-6 item slots
   - Standard pricing
   - Common ingredients

2. Specialty Shop
   - Rare ingredients focus
   - 3-5 item slots
   - Premium pricing
   - Special items

### Economy
1. Card Pricing
   - Basic: 3 coins
   - Standard: 5 coins
   - Quality: 8 coins
   - Premium: 12 coins
   - Exotic: 15 coins

2. Market Controls
   - Left/Right: Select card
   - Enter/Space: Purchase
   - TAB: View current deck
   - ESC: Leave market (skip)

## Implementation Notes
- Variable inventory sizes per market type
- Always includes "Skip Market" option
- Prices match card rarity/value
- Deck viewer available during shopping
- Cash persists between encounters

## Deferred Features
Note: These features are documented but deferred due to time constraints:
- Bargaining system
- Quantity discounts
- Daily specials
- Additional market types


