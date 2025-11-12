---@meta purpIe-config-NPCController
return {
	-- Enable NPC spawn chance manipulation
	NPCSpawnController = false,

	-- Always encounter story rooms
	AlwaysEncounterStoryRooms = {
		F = { Enabled = false },
		G = { Enabled = false },
		N = { Enabled = false },
		O = { Enabled = false },
		P = { Enabled = false },
	},	-- NPC Assist Spawn Values (out of 100)
	NPCSpawnValues = {
		Artemis = 10,
		Heracles = 10,
		Athena = 10,
		Icarus = 10,
		HeraclesBiomes = {
			Ephyra = true,
			Rift = true,
			Olympus = true,
		},
		IcarusBiomes = {
			Rift = true,
			Olympus = true,
		},
		NPCSpacing = 6,  -- Number of rooms between field NPC encounters
		MinDepthArtemis = 4,  -- Minimum biome depth for Artemis to spawn
		MinDepthAthena = 4,   -- Minimum biome depth for Athena to spawn
		MinDepthHeracles = 0, -- Minimum biome depth for Heracles to spawn
		MinDepthIcarus = 3,   -- Minimum biome depth for Icarus to spawn
	},

}
