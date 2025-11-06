# purpIe-NPCController

A comprehensive Hades 2 mod that gives you precise control over NPC encounter frequencies, spawn conditions, and story room availability. Perfect for players who want to customize their interaction with the game's supporting cast.

## Features

### NPC Encounter Control
- **Probability Manipulation**: Set desired spawn chances (0-99%) for key NPCs
- **Biome Restrictions**: Control which biomes each NPC can appear in
- **Depth Requirements**: Adjust minimum biome depth requirements for spawns
- **Encounter Spacing**: Modify how often field NPCs can appear

### Supported NPCs
- **Artemis**
- **Heracles**
- **Athena**
- **Icarus**

### Story Room Control
- **Forced Encounters**: Guarantee story rooms for specific NPCs
- **Biome-Specific**: Control story availability per biome
- **Supported NPCs**: Arachne, Narcissus, Medea, Circe, Dionysus


## Installation

- Install from Thunderstore mod using any mod manager (e.g., r2modman)

## Usage

### Basic Setup
1. Enable "NPC Spawn Controller" in the mod menu
2. Adjust settings in the "NPC Spawn Boost Settings" section
3. Configure story room forcing in "Always Encounter NPC Story Rooms"

### NPC Spawn Configuration

#### Global Settings
- **NPC Spacing**: Rooms between field NPC encounters (default: 6)

#### Individual NPC Settings
For each NPC (Artemis, Heracles, Athena, Icarus):

- **Desired Chance (%)**: Target spawn probability (0-99%)
- **Min Biome Depth**: Earliest biome depth for spawning
- **Biome Restrictions**: Checkboxes to allow/disable specific biomes

#### NPC-Specific Notes
- **Artemis**: Huntress with ranged assistance
- **Heracles**: Strength-focused melee combat
- **Athena**: Defensive strategy and protection
- **Icarus**: Aerial combat with wing mechanics

### Story Room Control
Enable checkboxes for NPCs whose story rooms you want to guarantee:
- **Arachne**
- **Narcissus**
- **Medea**
- **Circe**
- **Dionysus**

## Configuration Options

### Core Settings
- `NPCSpawnController`: Master toggle for the mod

### Spawn Values
- `Artemis`, `Heracles`, `Athena`, `Icarus`: Target spawn percentages (0-99)
- `NPCSpacing`: Rooms between NPC encounters (1-20)
- `MinDepth*`: Minimum biome depth for each NPC (0-10)

### Biome Restrictions
- `HeraclesBiomes`: Ephyra, Rift, Olympus toggles
- `IcarusBiomes`: Rift, Olympus toggles


## Technical Details

### Function Hooks
- `ChooseEncounter`: Modifies encounter selection to boost target NPCs
- Dynamic requirement updates for depth and spacing controls

### Data Structures
- Runtime spawn tracking to prevent duplicate encounters
- Dynamic encounter pool modification
- Biome-specific configuration storage

### Performance
- Minimal overhead with targeted encounter modification
- Only activates when mod is enabled
- Efficient probability calculations

## Strategy Examples

### High NPC Interaction
- Set all NPCs to 50% chance
- Reduce NPC spacing to 3
- Enable all story rooms
- Result: Frequent NPC encounters and guaranteed story progression

### Selective Companions
- Artemis: 75%, Athena: 25%, others: 0%
- Keep default spacing and depths
- Enable only desired story rooms
- Result: Focused interaction with specific NPCs

### Story Completion
- Set NPC chances to 0%
- Enable all story room forcing
- Result: Guaranteed story encounters without random combat

### Speed Run Prep
- All NPC chances: 0%
- Story rooms: Disabled
- Result: Pure combat-focused runs

## Compatibility

- Requires Hell2Modding framework
- Compatible with encounter-modifying mods
- May conflict with mods that alter NPC spawn mechanics
- Works with other purpIe mods

## Troubleshooting

### NPCs Not Spawning
- Verify "NPC Spawn Controller" is enabled
- Check biome depth requirements vs current depth
- Ensure target chance is above 0%
- Confirm biome restrictions allow current biome

### Story Rooms Not Appearing
- Enable the specific story room checkbox
- Note that some story rooms have native forcing (Hades)
- Check that you're in the correct biome

### Performance Issues
- High spawn chances may increase encounter pool size
- Consider reducing spacing or chances if experiencing slowdown
- Monitor console for algorithm debug output

### Settings Not Applying
- Changes apply immediately via ReLoad
- Some depth requirements update dynamically
- Restart may be needed for spacing changes

## Contributing

Built using Hell2Modding framework. To modify:
1. Edit the Lua files in the mod directory
2. Algorithm modifications require understanding probability math
3. Test changes with ReLoad hot-reloading
4. Follow existing pattern for adding new NPCs

## Credits

- Created for Hades 2 by Supergiant Games
- Uses Hell2Modding framework and dependencies

## Version History

- v1.0.0: Initial release with NPC spawn control and story room forcing</content>
