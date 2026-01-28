# std.client.Approaching

A proximity detection utility that triggers callbacks when the local player enters or leaves a specified distance threshold from a part.

## Signature

```lua
Approaching(part: BasePart, threshold: number, callbackEnter: () -> (), callbackLeave: (() -> ())?) -> Maid
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `part` | `BasePart` | Yes | The part to measure distance from |
| `threshold` | `number` | Yes | The distance (in studs) at which to trigger callbacks |
| `callbackEnter` | `() -> ()` | Yes | Called when the player comes within the threshold |
| `callbackLeave` | `() -> ()` | No | Called when the player leaves the threshold (defaults to empty function) |

## Returns

Returns a `Maid` object that can be used to clean up the proximity detection when no longer needed.

## Behavior

- Checks player distance **5 times per second** (every 0.2 seconds)
- Uses **horizontal distance only** (ignores Y-axis) - calculated on the XZ plane
- Requires the player to have a valid `Character` with a `PrimaryPart`
- Uses `std.State` internally to track enter/leave transitions, ensuring callbacks are only fired on state changes (not every tick)

## Usage

```lua
local std = shared.std

-- Basic usage: detect when player approaches an NPC
local maid = std.client.Approaching(npcPart, 10, function()
    print("Player is near the NPC!")
end, function()
    print("Player left the NPC area")
end)

-- Clean up when done
maid:Destroy()
```

```lua
-- Without leave callback
local maid = std.client.Approaching(treasureChest, 5, function()
    showInteractPrompt()
end)
```

## Notes

- The horizontal-only distance calculation makes this ideal for ground-based proximity detection where vertical position shouldn't matter (e.g., multi-floor buildings)
- Remember to call `:Destroy()` on the returned Maid when the proximity detection is no longer needed to prevent memory leaks
- If the player's character or PrimaryPart is nil (e.g., during respawn), the distance check is skipped for that tick
