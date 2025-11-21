---@meta _
---@diagnostic disable: lowercase-global

local mods = rom.mods


    -- Wrap ChooseEncounter to boost Artemis encounter selection
modutil.mod.Path.Wrap("ChooseEncounter", function(base, currentRun, room, args)

    -- If the feature is toggled off at runtime or we don't have a current run, just call base
    if not config.NPCSpawnController or not currentRun then
        return base(currentRun, room, args)
    end

    -- Helper function to calculate required boost (x1) and dilution (x2)
    local function calculateBoost(target_y, Ninitial, na)
        local P_initial = na / Ninitial
        local x1_boost = 0   
        local x2_dilution = 0 
        local formula_applied = "NONE"

        -- Ensure target_y is a valid probability and Ninitial is reasonable
        if target_y <= 0 or target_y >= 1 or Ninitial < 1 then
            return 1, 1, "INVALID_INPUT" -- Default to minimum forced cost
        end

        if target_y > P_initial then
            -- Strategy: BOOST_DOMINANT -> Minimize total cost C by setting x2 = 1.
            formula_applied = "BOOST_DOMINANT"
            x2_dilution = 1
            
            -- Formula: x1 = ceil( (y * (N_initial + 1) - n_a) / (1 - y) )
            local numerator = (target_y * (Ninitial + 1)) - na
            local denominator = (1 - target_y)
            x1_boost = math.ceil(numerator / denominator)

        elseif target_y < P_initial then
            -- Strategy: DILUTION_DOMINANT -> Minimize total cost C by setting x1 = 1.
            formula_applied = "DILUTION_DOMINANT"
            x1_boost = 1
            
            -- Formula: x2 = ceil( (n_a + (1-y)) / y - N_initial )
            local numerator = na + (1 - target_y)
            local x2_float = (numerator / target_y) - Ninitial
            x2_dilution = math.ceil(x2_float)
            
        else -- target_y == P_initial
            -- MIN_FORCED_COST for y = P_initial
            formula_applied = "MIN_FORCED_COST"
            x1_boost = 1
            x2_dilution = 1
        end
        
        -- Ensure x1 and x2 are at least 1, as required by the constraint
        x1_boost = math.max(1, x1_boost) 
        x2_dilution = math.max(1, x2_dilution)
        
        return x1_boost, x2_dilution, formula_applied
    end


    -- Helper function to apply the pre-calculated boost (x1) and dilution (x2)
    local function applyBoost(encounterList, boostItem, generated_encName, total_count)
        local x1_boost = boostItem.x1
        local x2_dilution = boostItem.x2
        print("Applying boost for encounter:", boostItem.encName)
        -- local npcName = boostItem.encName:sub(boostItem.encName:find("NPC_")+4, boostItem.encName:find("_01")-1)
        local npcName = boostItem.encName:sub(1, boostItem.encName:find("Combat") - 1)
        print("NPC Name identified as:", npcName)

        local na = 1
        local Ninitial = total_count

        print("--- Applying " .. npcName .. " Boost ---")
        print("Required Boost (x1): " .. tostring(x1_boost) .. ", Required Dilution (x2): " .. tostring(x2_dilution))
        
        -- Apply the Boost (x1)
        print("Applying Boost: adding " .. tostring(x1_boost) .. " additional " .. npcName .. " encounter(s).")
        for i = 1, x1_boost do
            table.insert(encounterList, boostItem.encName)
        end

        -- Apply the Dilution (x2) - Simple insertion since "Generated" is one unique type
        if x2_dilution > 0 and generated_encName ~= nil then
            print("Applying Dilution: adding " .. tostring(x2_dilution) .. " items of type: " .. generated_encName)
            for i = 1, x2_dilution do
                table.insert(encounterList, generated_encName)
            end
        end
        
        -- Final calculation log
        local na_final = na + x1_boost
        local N_final = Ninitial + x1_boost + x2_dilution
        local y_actual = na_final / N_final
        print("Final Pool Size: " .. tostring(N_final) .. ", Actual Final P(a): " .. tostring(y_actual) .. ", Target Y: " .. tostring(boostItem.targetY))
    end

    args = args or {}
	local legalEncounters = args.LegalEncounters or room.LegalEncounters

    if legalEncounters then

        -- Define the set of valid biome suffixes
        
        local function isCombatEncounter(encounterName)
            local valid_biome_suffixes = {
            ["F"] = true, ["G"] = true, ["H"] = true, ["I"] = true,
            ["N"] = true, ["O"] = true, ["P"] = true, ["Q"] = true}
            local suffix = encounterName:sub(-1)
            return valid_biome_suffixes[suffix]
        end

        local function isExcluded(encounterName)
            -- ONLY EXCLUDE encounters containing "Combat" and ending with '2' (e.g., ArtemisCombatN2)
            return encounterName:find("Combat") ~= nil and encounterName:sub(-1) == "2"
        end

        -- STEP 1: PRE-CALCULATION PHASE
        local unique_list, seen, eligible_npcs = {}, {}, {}
        local generated_encName = nil -- The single unique name for dilution
        
        currentRun.SpawnRecord = currentRun.SpawnRecord or {}
        for _, enc in ipairs(legalEncounters) do
            if not seen[enc] then
                seen[enc] = true
                if not isExcluded(enc) then
                    -- Determine whether this encounter should be present at all.
                    -- If a specific NPC is explicitly disabled (chance == 0), already spawned, or disallowed in this biome,
                    -- skip adding it to the unique list so the game's base logic cannot select it.
                    local shouldInclude = true
                    -- Find the "Generated" encounter (Dilution Target) regardless; keep first seen
                    if not generated_encName and enc:find("Generated") then
                        generated_encName = enc
                    end

                    if isCombatEncounter(enc) then
                        local biomeDepth = (currentRun and currentRun.BiomeDepthCache) or 0

                        if enc:find("Artemis") then
                            -- Disable entirely if user set chance to 0, it already spawned, or below min depth
                            if (config.NPCSpawnValues.Artemis or 0) == 0 or currentRun.SpawnRecord.NPC_Artemis_Field_01 or biomeDepth <= config.NPCSpawnValues.MinDepthArtemis then
                                shouldInclude = false
                            else
                                eligible_npcs.Artemis = enc
                            end

                        elseif enc:find("Heracles") then
                            local allow = true
                            if room.RoomSetName == "N" and not config.NPCSpawnValues.HeraclesBiomes.Ephyra then allow = false end
                            if room.RoomSetName == "O" and not config.NPCSpawnValues.HeraclesBiomes.Rift then allow = false end
                            if room.RoomSetName == "P" and not config.NPCSpawnValues.HeraclesBiomes.Olympus then allow = false end
                            if (config.NPCSpawnValues.Heracles or 0) == 0 or currentRun.SpawnRecord.NPC_Heracles_01 or not allow or biomeDepth <= config.NPCSpawnValues.MinDepthHeracles then
                                shouldInclude = false
                            else
                                eligible_npcs.Heracles = enc
                            end

                        elseif enc:find("Athena") then
                            if (config.NPCSpawnValues.Athena or 0) == 0 or currentRun.SpawnRecord.NPC_Athena_01 or biomeDepth <= config.NPCSpawnValues.MinDepthAthena then
                                shouldInclude = false
                            else
                                eligible_npcs.Athena = enc
                            end

                        elseif enc:find("Icarus") then
                            local allow = true
                            if room.RoomSetName == "O" and not config.NPCSpawnValues.IcarusBiomes.Rift then allow = false end
                            if room.RoomSetName == "P" and not config.NPCSpawnValues.IcarusBiomes.Olympus then allow = false end
                            if (config.NPCSpawnValues.Icarus or 0) == 0 or currentRun.SpawnRecord.NPC_Icarus_01 or not allow or biomeDepth <= config.NPCSpawnValues.MinDepthIcarus then
                                shouldInclude = false
                            else
                                eligible_npcs.Icarus = enc
                            end
                        end
                    end

                    if shouldInclude then
                        table.insert(unique_list, enc)
                    end
                end
            end
        end

        -- STEP 2: DECISION AND CALCULATION PHASE
        local unique_count = #unique_list
        local na = 1 -- Initial count for any target NPC is always 1 in the unique list
        local boost_data = {}
        local npc_to_boost = nil

        local function store_boost_data(npcName, configValue)
            local y_target = (configValue or 0) / 100
            if unique_count > 1 and y_target > 0 and y_target < 1 then
                local x1, x2, formula = calculateBoost(y_target, unique_count, na)
                boost_data[npcName] = {encName = eligible_npcs[npcName], x1 = x1, x2 = x2, targetY = y_target, formula = formula}
                return true
            end
            return false
        end


        if eligible_npcs.Artemis and store_boost_data("Artemis", config.NPCSpawnValues.Artemis) then
            npc_to_boost = "Artemis"
        elseif eligible_npcs.Heracles and store_boost_data("Heracles", config.NPCSpawnValues.Heracles) then
            npc_to_boost = "Heracles"
        elseif eligible_npcs.Athena and store_boost_data("Athena", config.NPCSpawnValues.Athena) then
            npc_to_boost = "Athena"
        elseif eligible_npcs.Icarus and store_boost_data("Icarus", config.NPCSpawnValues.Icarus) then
            npc_to_boost = "Icarus"
            
        end

        -- STEP 3: EARLY EXIT IF NO NPC TO BOOST
        if not npc_to_boost then
            print("No eligible NPC to boost. Skipping modification and calling base function.")
            return base(currentRun, room, args)
        end

        -- STEP 4: APPLICATION PHASE (This part only runs if a boost is happening)
        local newLegal = {}
        local boosted_any = false
        print("Starting final encounter list build. NPC to boost: " .. tostring(npc_to_boost))
        
        for _, encounterName in ipairs(unique_list) do
            table.insert(newLegal, encounterName)
            for npcName, boostItem in pairs(boost_data) do
                if encounterName == boostItem.encName and npcName == npc_to_boost and not boosted_any then
                    print("Boosting encounter:", encounterName, "for NPC:", npcName)
                    applyBoost(newLegal, boostItem, generated_encName, unique_count)
                    boosted_any = true
                end
            end
        end

		if boosted_any then
            print ("NPC Encounter Boost Applied. New Legal Encounters length:", #newLegal)
			args.LegalEncounters = newLegal
			room.LegalEncounters = newLegal
		end
	end
	return base(currentRun, room, args)

end)

modutil.mod.Path.Wrap("StartNewRun", function(base, prevRun, args)
    local currentRun = base(prevRun, args)

    -- If the feature is toggled off at runtime, just return
    if not config.NPCSpawnController then
        return currentRun
    end

    -- Initialize spawn flags
    -- currentRun.UseRecord = currentRun.UseRecord or {}
    currentRun.SpawnRecord = currentRun.SpawnRecord or {}

    currentRun.SpawnRecord.NPC_Artemis_Field_01 = false
    currentRun.SpawnRecord.NPC_Heracles_01 = false
    currentRun.SpawnRecord.NPC_Athena_01 = false
    currentRun.SpawnRecord.NPC_Icarus_01 = false

    -- Override the NPC spacing requirement
    NamedRequirementsData.NoRecentFieldNPCEncounter[1].SumPrevRooms = config.NPCSpawnValues.NPCSpacing

    -- Override the min depth requirements for Artemis, Athena, and Icarus
    EncounterData.BaseArtemisCombat.GameStateRequirements[3].Value = config.NPCSpawnValues.MinDepthArtemis
    EncounterData.BaseAthenaCombat.GameStateRequirements[3].Value = config.NPCSpawnValues.MinDepthAthena
    EncounterData.BaseIcarusCombat.GameStateRequirements[2].Value = config.NPCSpawnValues.MinDepthIcarus

    -- Force story rooms at specific depths if enabled
    if config.AlwaysEncounterStoryRooms.F.Enabled then
        RoomSetData.F.F_Story01.ForceAtBiomeDepthMin = 4
        RoomSetData.F.F_Story01.ForceAtBiomeDepthMax = 8
    end
    if config.AlwaysEncounterStoryRooms.G.Enabled then
        RoomSetData.G.G_Story01.ForceAtBiomeDepthMin = 3
        RoomSetData.G.G_Story01.ForceAtBiomeDepthMax = 6
    end
    if config.AlwaysEncounterStoryRooms.N.Enabled then
        RoomSetData.N.N_Story01.ForceAtBiomeDepthMin = 0
        RoomSetData.N.N_Story01.ForceAtBiomeDepthMax = 1
    end
    if config.AlwaysEncounterStoryRooms.O.Enabled then
        RoomSetData.O.O_Story01.ForceAtBiomeDepthMin = 3
        RoomSetData.O.O_Story01.ForceAtBiomeDepthMax = 5
    end
    if config.AlwaysEncounterStoryRooms.P.Enabled then
        RoomSetData.P.P_Story01.ForceAtBiomeDepthMin = 2
        RoomSetData.P.P_Story01.ForceAtBiomeDepthMax = 7
    end

    return currentRun
end)

modutil.mod.Path.Wrap("BeginArtemisEncounter", function(base, currentRun, room, args)
    -- runtime gate: no-op when feature disabled or when no current run
    if not config.NPCSpawnController or not currentRun then
        return base(currentRun, room, args)
    end

    currentRun.SpawnRecord = currentRun.SpawnRecord or {}
    currentRun.SpawnRecord.NPC_Artemis_Field_01 = true
    return base(currentRun, room, args)
end)

modutil.mod.Path.Wrap("BeginHeraclesEncounter", function(base, currentRun, room, args)
    -- runtime gate: no-op when feature disabled or when no current run
    if not config.NPCSpawnController or not currentRun then
        return base(currentRun, room, args)
    end

    currentRun.SpawnRecord = currentRun.SpawnRecord or {}
    currentRun.SpawnRecord.NPC_Heracles_01 = true
    return base(currentRun, room, args)
end)

modutil.mod.Path.Wrap("BeginAthenaEncounter", function(base, currentRun, room, args)
    -- runtime gate: no-op when feature disabled or when no current run
    if not config.NPCSpawnController or not currentRun then
        return base(currentRun, room, args)
    end

    currentRun.SpawnRecord = currentRun.SpawnRecord or {}
    currentRun.SpawnRecord.NPC_Athena_01 = true
    return base(currentRun, room, args)
end)

modutil.mod.Path.Wrap("BeginIcarusEncounter", function(base, currentRun, room, args)
    -- runtime gate: no-op when feature disabled or when no current run
    if not config.NPCSpawnController or not currentRun then
        return base(currentRun, room, args)
    end

    currentRun.SpawnRecord = currentRun.SpawnRecord or {}
    currentRun.SpawnRecord.NPC_Icarus_01 = true
    return base(currentRun, room, args)
end)

-- UI Drawing function
function DrawNPCChanceUI()
	-- local openNPC = rom.ImGui.CollapsingHeader("NPC Assist Spawn Chances")
    local open = rom.ImGui.CollapsingHeader("NPC Spawn Boost Settings")
	if open then

        local spacingValue, spacingChanged = rom.ImGui.SliderInt("NPC Spacing (def 6)", config.NPCSpawnValues.NPCSpacing, 1, 20)
        if spacingChanged then
            config.NPCSpawnValues.NPCSpacing = spacingValue
            -- Update the requirement dynamically
            NamedRequirementsData.NoRecentFieldNPCEncounter[1].SumPrevRooms = spacingValue
        end


        rom.ImGui.Spacing()

        local open_artemis = rom.ImGui.CollapsingHeader("Artemis Encounter Settings")
        if open_artemis then
            local artemisDepthValue, artemisDepthChanged = rom.ImGui.SliderInt("Min Biome Depth (def 4)##Artemis", config.NPCSpawnValues.MinDepthArtemis, 0, 10)
            if artemisDepthChanged then
                config.NPCSpawnValues.MinDepthArtemis = artemisDepthValue
                EncounterData.BaseArtemisCombat.GameStateRequirements[3].Value = artemisDepthValue
            end
            local artemisValue, artemisChanged = rom.ImGui.SliderInt("Desired Chance (%)##Artemis", config.NPCSpawnValues.Artemis, 0, 99)
            if artemisChanged then
                config.NPCSpawnValues.Artemis = artemisValue
            end
        end


        rom.ImGui.Spacing()
        local open_heracles = rom.ImGui.CollapsingHeader("Heracles Spawn Settings")
        if open_heracles then
            local heraclesDepthValue, heraclesDepthChanged = rom.ImGui.SliderInt("Min Biome Depth (def 0)##Heracles", config.NPCSpawnValues.MinDepthHeracles, 0, 10)
            if heraclesDepthChanged then
                config.NPCSpawnValues.MinDepthHeracles = heraclesDepthValue
            end
            local ephyraValue, ephyraChanged = rom.ImGui.Checkbox("Allow Heracles in Ephyra", config.NPCSpawnValues.HeraclesBiomes.Ephyra)
            if ephyraChanged then
                config.NPCSpawnValues.HeraclesBiomes.Ephyra = ephyraValue
            end

            local riftValue, riftChanged = rom.ImGui.Checkbox("Allow Heracles in Rift", config.NPCSpawnValues.HeraclesBiomes.Rift)
            if riftChanged then
                config.NPCSpawnValues.HeraclesBiomes.Rift = riftValue
            end

            local olympusValue, olympusChanged = rom.ImGui.Checkbox("Allow Heracles in Olympus", config.NPCSpawnValues.HeraclesBiomes.Olympus)
            if olympusChanged then
                config.NPCSpawnValues.HeraclesBiomes.Olympus = olympusValue
            end
            
            local heraclesValue, heraclesChanged = rom.ImGui.SliderInt("Desired Chance (%)##Heracles", config.NPCSpawnValues.Heracles, 0, 99)
            if heraclesChanged then
                config.NPCSpawnValues.Heracles = heraclesValue
            end
        end

        rom.ImGui.Spacing()
        
        local open_athena = rom.ImGui.CollapsingHeader("Athena Encounter Settings")
        if open_athena then
            local athenaDepthValue, athenaDepthChanged = rom.ImGui.SliderInt("Min Biome Depth (def 4)##Athena", config.NPCSpawnValues.MinDepthAthena, 0, 10)
            if athenaDepthChanged then
                config.NPCSpawnValues.MinDepthAthena = athenaDepthValue
                EncounterData.BaseAthenaCombat.GameStateRequirements[3].Value = athenaDepthValue
            end
            local athenaValue, athenaChanged = rom.ImGui.SliderInt("Desired Chance (%)##Athena", config.NPCSpawnValues.Athena, 0, 99)
            if athenaChanged then
                config.NPCSpawnValues.Athena = athenaValue
            end
        end
        
        rom.ImGui.Spacing()
        local open_icarus = rom.ImGui.CollapsingHeader("Icarus Spawn Settings")
        if open_icarus then
            local icarusDepthValue, icarusDepthChanged = rom.ImGui.SliderInt("Min Biome Depth (def 3)##Icarus", config.NPCSpawnValues.MinDepthIcarus, 0, 10)
            if icarusDepthChanged then
                config.NPCSpawnValues.MinDepthIcarus = icarusDepthValue
                EncounterData.BaseIcarusCombat.GameStateRequirements[2].Value = icarusDepthValue
            end
            local icarusRiftValue, icarusRiftChanged = rom.ImGui.Checkbox("Allow Icarus in Rift", config.NPCSpawnValues.IcarusBiomes.Rift)
            if icarusRiftChanged then
                config.NPCSpawnValues.IcarusBiomes.Rift = icarusRiftValue
            end

            local icarusOlympusValue, icarusOlympusChanged = rom.ImGui.Checkbox("Allow Icarus in Olympus", config.NPCSpawnValues.IcarusBiomes.Olympus)
            if icarusOlympusChanged then
                config.NPCSpawnValues.IcarusBiomes.Olympus = icarusOlympusValue
            end

            local icarusValue, icarusChanged = rom.ImGui.SliderInt("Desired Chance (%)##Icarus", config.NPCSpawnValues.Icarus, 0, 99)
            if icarusChanged then
                config.NPCSpawnValues.Icarus = icarusValue
            end
        end

        rom.ImGui.Spacing()

        local npc_rooms_header = rom.ImGui.CollapsingHeader("Always Encounter NPC Story Rooms")
        if npc_rooms_header then
            local fValue, fChanged = rom.ImGui.Checkbox("Arachne", config.AlwaysEncounterStoryRooms.F.Enabled)
            if fChanged then
                config.AlwaysEncounterStoryRooms.F.Enabled = fValue
            end

            local gValue, gChanged = rom.ImGui.Checkbox("Narcissus", config.AlwaysEncounterStoryRooms.G.Enabled)
            if gChanged then
                config.AlwaysEncounterStoryRooms.G.Enabled = gValue
            end

            local nValue, nChanged = rom.ImGui.Checkbox("Medea", config.AlwaysEncounterStoryRooms.N.Enabled)
            if nChanged then
                config.AlwaysEncounterStoryRooms.N.Enabled = nValue
            end

            local oValue, oChanged = rom.ImGui.Checkbox("Circe", config.AlwaysEncounterStoryRooms.O.Enabled)
            if oChanged then
                config.AlwaysEncounterStoryRooms.O.Enabled = oValue
            end

            local pValue, pChanged = rom.ImGui.Checkbox("Dionysus", config.AlwaysEncounterStoryRooms.P.Enabled)
            if pChanged then
                config.AlwaysEncounterStoryRooms.P.Enabled = pValue
            end
        end

        -- rom.ImGui.EndChild()
    end
end
