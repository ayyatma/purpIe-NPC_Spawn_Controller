---@meta _
---@diagnostic disable

local function addSeperatorSpacing()
	rom.ImGui.Spacing()
	rom.ImGui.Spacing()
	rom.ImGui.Separator()
	rom.ImGui.Spacing()
	rom.ImGui.Spacing()
end

local function ImGUICheckbox(label, configKey, func, spacing)
	local value, checked = rom.ImGui.Checkbox(label, config[configKey])

	if checked then
		config[configKey] = value
	end

	func()

	if spacing == true then
		addSeperatorSpacing()
	end
end

local function DrawNPCManager()
	if not config.NPCSpawnController then
		return
	end

	DrawNPCChanceUI()
end

local function drawMenu()
	ImGUICheckbox("Enable NPC Spawn Chances", "NPCSpawnController", DrawNPCManager, false)
end

rom.gui.add_imgui(function()
	if rom.ImGui.Begin("NPC Chance Control Mod") then
		drawMenu()
		rom.ImGui.End()
	end
end)

rom.gui.add_to_menu_bar(function()
	if rom.ImGui.BeginMenu("Configure") then
		drawMenu()
		rom.ImGui.EndMenu()
	end
end)
