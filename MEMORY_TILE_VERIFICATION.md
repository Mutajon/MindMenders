# Memory Tile Mechanics - Quick Verification Guide

## How to Test the Implementation

### Setup
The game is running at: http://localhost:8080

### Test Scenarios

#### 1. Memory Tile Shield Visualization
**What to check:**
- Load a level with Memory tiles
- Look for Memory tiles on the grid (light yellow hexagons)
- If a Memory tile is controlled by a faction, you should see a hexagonal shield around it
- Hive-controlled memories: RED shield
- Mender-controlled memories: BLUE shield
- Neutral memories: NO shield

**Expected behavior:** Shields should appear as semi-transparent hexagonal bubbles around controlled Memory tiles

---

#### 2. Memory Capture via Movement
**How to test:**
```
1. Find an unshielded Memory tile (Neutral or enemy with shield=0)
2. Play a Move card
3. Select a unit
4. Move the unit onto the Memory tile
5. Observe the outcome
```

**Expected behavior:**
- Memory tile changes alliance to your faction (Menders)
- A BLUE shield appears around the memory
- Console logs: "Memory captured by Menders! Shield added."

---

#### 3. Shield Damage from Attacks
**How to test:**
```
1. Find an enemy-controlled Memory with a shield
2. Play an Attack card
3. Select a unit with line-of-sight to the Memory
4. Attack the Memory tile
5. Observe the shield
```

**Expected behavior:**
- Shield visual should disappear
- Console logs: "Memory shield damaged! Shields remaining: 0"
- Memory remains controlled by enemy (not captured yet)
- Shield does NOT regenerate until their turn

---

#### 4. Shield Regeneration on Turn Start
**How to test:**
```
1. Capture a Memory tile (it will have 1 shield)
2. Have an enemy attack it (shield goes to 0)
3. End your turn
4. Wait for AI turn to complete
5. Start a new turn (your turn begins)
6. Check the Memory tile
```

**Expected behavior:**
- Shield should reappear on the Memory tile
- Console logs: "Regenerated shields on X Memory tiles for Menders"

---

#### 5. Control Connection Validation
**How to test:**
```
1. Create a "chain" of Dendrite tiles connecting to a Memory
   Structure: [Memory] -> [Dendrite A] -> [Dendrite B]
2. All should be your faction's color (blue glow)
3. Capture the middle tile (Dendrite A) with an enemy
4. End your turn
5. Check Dendrite B
```

**Expected behavior:**
- Dendrite B should turn Neutral (gray, no glow)
- Console logs: "Tile (x, y) disconnected from Menders memories - neutralizing"
- Console logs: "X tiles neutralized due to disconnection"

---

## Console Commands

Open browser console (F12) to see debug output:

### Key Debug Messages to Watch For:
```
✓ "Memory captured by Menders! Shield added."
✓ "Memory shield damaged! Remaining: 0"
✓ "Regenerated shields on X Memory tiles for Menders"
✓ "Tile (x, y) disconnected from Menders memories - neutralizing"
✓ "Shield regenerated for Memory at (x, y) controlled by [faction]"
```

---

## Visual Indicators

### Memory Tile States:
| State | Visual |
|-------|--------|
| Neutral | Light yellow hex, NO shield |
| Menders Controlled | Light yellow hex + BLUE shield + Blue glow |
| Hive Controlled | Light yellow hex + RED shield + Red glow |
| Shielded | Semi-transparent hexagonal bubble |
| Unshielded | No bubble visible |

### Connection Status (Dendrites):
| State | Visual |
|-------|--------|
| Connected | Faction colored glow (blue/red) |
| Neutral | Gray/no glow |
| Disconnected (auto-neutralized) | Glow disappears at turn end |

---

## Known Implementation Details

1. **Shield Count**: Memory tiles have max 1 shield
2. **Damage Amount**: Each attack deals 1 damage to shields
3. **Regeneration Timing**: At START of each faction's turn
4. **Connection Check**: At END of player turn (before AI turn)
5. **Faction Support**: System works for both Hive and Menders

---

## Troubleshooting

### Shield not appearing?
- Check that Memory tile is controlled (not Neutral)
- Check that shieldCount > 0 (hover to see data, or check console)

### Shield not regenerating?
- Make sure a full turn cycle completed
- Check that Memory is still controlled by your faction
- Look for regeneration message in console

### Tiles not disconnecting?
- Validation only runs at turn end
- Check that the path is truly broken
- Neutral tiles don't count as connected

---

## Implementation Files Reference
- Shield visual: `/lib/components/memory_shield_component.dart`
- Shield management: `/lib/components/isometric_tile.dart`
- Game logic: `/lib/game.dart`
- Connection validation: `/lib/utils/control_validator.dart`
- Tile definitions: `/lib/data/tile_database.dart`
