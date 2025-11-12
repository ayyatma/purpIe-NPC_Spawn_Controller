# NPC Spawn Controller

A comprehensive Hades 2 mod that gives you precise control over NPC encounter frequencies, spawn conditions, and story room availability.

Control Artemis chance in Ephyra. No more waiting forever to see her!
Want to never see Heracles again? You got it.
Want to never see a natural spawn Athena again? Done.

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

#### Story Room Control
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

## Contributing

Built using Hell2Modding framework. To modify:
1. Edit the Lua files in the mod directory
2. Algorithm modifications require understanding probability math
3. Test changes with ReLoad hot-reloading
4. Follow existing pattern for adding new NPCs

## Changelog
- v1.0.2: Fixed issue with icarus slider and readme file.
- v1.0.1: Fixing release name.
- v1.0.0: Initial release.