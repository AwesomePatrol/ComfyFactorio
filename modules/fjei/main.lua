--[[
FJEI - Factorio "Just enough items"
An item recipe browser - MewMew
]]

local Gui = require "modules.fjei.gui"
local Functions = require "modules.fjei.functions"

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.fjei.player_data[player.index] then global.fjei.player_data[player.index] = {} end
	Functions.set_crafting_machines(player.force.name)
	Functions.set_base_item_list(player.force.name)
	Gui.draw_top_toggle_button(player)
end

local function on_player_left_game(event)
	local player = game.players[event.player_index]
	global.fjei.player_data[player.index].history = nil
	global.fjei.player_data[player.index].filtered_list = nil
	global.fjei.player_data[player.index] = nil
end

local function on_research_finished(event)
	local force_name = event.research.force.name
	Functions.set_crafting_machines(force_name)
	Functions.set_base_item_list(force_name)
	for _, player in pairs(game.connected_players) do
		global.fjei.player_data[player.index].filtered_list = nil
		Gui.refresh_main_window(player)
	end
end

local sprite_parent_whitelist = {
	["fjei_main_window_item_list_table"] = true,
	["fjei_main_window_history_table"] = true,
	["fjei_recipe_window"] = true,
}

local function on_gui_click(event)
	local element = event.element
	if not element then return end
	if not element.valid then return end
	local player = game.players[event.player_index]	
	if Gui.gui_click_actions(element, player, event.button) then return end
	
	if element.type ~= "sprite" then return end
	local parent = element.parent
	if not parent then return end
	if sprite_parent_whitelist[parent.name] then Gui.open_recipe(element.name, player, event.button) return end
	local parent = parent.parent
	if not parent then return end
	if sprite_parent_whitelist[parent.parent.name] then Gui.open_recipe(element.name, player, event.button) return end
	local parent = parent.parent
	if not parent then return end
	if sprite_parent_whitelist[parent.parent.name] then Gui.open_recipe(element.name, player, event.button) return end
end

local function on_gui_text_changed(event)
	local element = event.element
	if not element then return end
	if not element.valid then return end
	if element.name ~= "fjei_main_window_search_textfield" then return end
	local player = game.players[event.player_index]
	if element.text == "" then
		global.fjei.player_data[player.index].active_filter = false
	else
		global.fjei.player_data[player.index].active_filter = element.text
	end
	Functions.set_filtered_list(player)
	Gui.refresh_main_window(player)
end

local function on_init()
	global.fjei = {}
	global.fjei.player_data = {}
end

local event = require "utils.event"
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_gui_text_changed, on_gui_text_changed)
event.on_init(on_init)