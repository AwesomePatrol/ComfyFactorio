-- Biter Battles v2 -- by MewMew

local Ai = require "maps.biter_battles_v2.ai"
local Functions = require "maps.biter_battles_v2.functions"
local Game_over = require "maps.biter_battles_v2.game_over"
local Gui = require "maps.biter_battles_v2.gui"
local Init = require "maps.biter_battles_v2.init"
local Mirror_terrain = require "maps.biter_battles_v2.mirror_terrain"
require 'modules.simple_tags'
local Map_info = require 'modules.map_info'
local Changelog = require 'comfy_panel.changelog'
local Team_manager = require "maps.biter_battles_v2.team_manager"
local Terrain = require "maps.biter_battles_v2.terrain"
local feeding = require "maps.biter_battles_v2.feeding"

require "maps.biter_battles_v2.sciencelogs_tab"
require 'maps.biter_battles_v2.commands'
require "modules.spawners_contain_biters"

local function on_player_joined_game(event)
	local surface = game.surfaces["biter_battles"]
	local player = game.players[event.player_index]
	if player.online_time == 0 or player.force.name == "player" then
		Functions.init_player(player)
	end
	Team_manager.draw_top_toggle_button(player)
end

local function on_gui_click(event)
	local player = game.players[event.player_index]
	local element = event.element
	if not element then return end
	if not element.valid then return end

	Team_manager.gui_click(event)
end

local function on_research_finished(event)
	Functions.combat_balance(event)
end

local function on_console_chat(event)
	Functions.share_chat(event)
end

local function on_built_entity(event)
	Functions.no_turret_creep(event)
	Functions.add_target_entity(event.created_entity)
end

local function on_robot_built_entity(event)
	Functions.no_turret_creep(event)
	Terrain.deny_construction_bots(event)
	Functions.add_target_entity(event.created_entity)
end

local function on_robot_built_tile(event)
	Terrain.deny_bot_landfill(event)
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	if Ai.subtract_threat(entity) then Gui.refresh_threat() end
	if Functions.biters_landfill(entity) then return end
	Game_over.silo_death(event)
end

local auto_feed_values = {
    [20] = {2, 3, 0, 0, 0, 0, 0},
    [21] = {0, 117, 0, 0, 0, 0, 0},
    [23] = {0, 84, 0, 0, 0, 0, 0},
    [25] = {0, 182, 0, 0, 0, 0, 0},
    [27] = {0, 112, 0, 0, 0, 0, 0},
    [30] = {0, 429, 0, 0, 0, 0, 0},
    [32] = {0, 158, 0, 0, 0, 0, 0},
    [34] = {0, 457, 0, 0, 0, 0, 0},
    [36] = {0, 311, 0, 0, 0, 0, 0},
    [37] = {0, 230, 0, 0, 0, 0, 0},
    [38] = {0, 76, 0, 0, 0, 0, 0},
    [39] = {0, 140, 0, 0, 0, 0, 0},
    [40] = {0, 65, 0, 0, 0, 0, 0}
}

local function auto_feed()
    -- get game time minute
    local minute = math.floor(game.tick / 3600)
    local food_names = {
        "automation-science-pack",
        "logistic-science-pack",
        "military-science-pack",
        "chemical-science-pack",
        "production-science-pack",
        "utility-science-pack",
        "space-science-pack"
    }

    for t, val in pairs(auto_feed_values) do
        if t == minute then
            for i, name in pairs(food_names) do
                if val[i] > 0 then
                    feeding.auto_feed_biters("south_biters", name, val[i], t)
                end
            end
            return
        end
    end
    if minute > 40 then
        feeding.auto_feed_biters("south_biters", "logistic-science-pack", 200, minute)
    end
end

local tick_minute_functions = {
	[300 * 1] = Ai.raise_evo,
	[300 * 2] = Ai.destroy_inactive_biters,
	[300 * 3 + 30 * 0] = Ai.pre_main_attack,		-- setup for main_attack
	[300 * 3 + 30 * 1] = Ai.perform_main_attack,	-- call perform_main_attack 7 times on different ticks
	[300 * 3 + 30 * 2] = Ai.perform_main_attack,	-- some of these might do nothing (if there are no wave left)
	[300 * 3 + 30 * 3] = Ai.perform_main_attack,
	[300 * 3 + 30 * 4] = Ai.perform_main_attack,
	[300 * 3 + 30 * 5] = Ai.perform_main_attack,
	[300 * 3 + 30 * 6] = Ai.perform_main_attack,
	[300 * 3 + 30 * 7] = Ai.perform_main_attack,
	[300 * 3 + 30 * 8] = Ai.post_main_attack,
	[300 * 4] = Ai.send_near_biters_to_silo,
	[300 * 5] = Ai.wake_up_sleepy_groups,
    [300 * 6] = auto_feed,
}

local function on_tick()
	Mirror_terrain.ticking_work()

	local tick = game.tick

	if tick % 60 == 0 then 
		global.bb_threat["north_biters"] = global.bb_threat["north_biters"] + global.bb_threat_income["north_biters"]
		global.bb_threat["south_biters"] = global.bb_threat["south_biters"] + global.bb_threat_income["south_biters"]

		-- Update biter HP modifier every second
		feeding.set_biter_modifiers(game.forces["north_biters"])
		feeding.set_biter_modifiers(game.forces["south_biters"])
	end

	if tick % 180 == 0 then Gui.refresh() end

	if tick % 300 == 0 then
		Gui.spy_fish()

		if global.bb_game_won_by_team then
			Game_over.reveal_map()
			Game_over.server_restart()
			return
		end
	end

	if tick % 30 == 0 then	
		local key = tick % 3600
		if tick_minute_functions[key] then tick_minute_functions[key]() end
	end
end

local function on_marked_for_deconstruction(event)
	if not event.entity.valid then return end
	if event.entity.name == "fish" then event.entity.cancel_deconstruction(game.players[event.player_index].force.name) end
end

local function on_player_built_tile(event)
	local player = game.players[event.player_index]
	Terrain.restrict_landfill(player.surface, player, event.tiles)
end

local function on_player_built_tile(event)
	local player = game.players[event.player_index]
	Terrain.restrict_landfill(player.surface, player, event.tiles)
end

local function on_player_mined_entity(event)
	Terrain.minable_wrecks(event)
end

local function on_chunk_generated(event)
	Terrain.generate(event)
	Mirror_terrain.add_chunk(event)
end

local function on_init()
	Init.tables()
	Init.initial_setup()
	Init.forces()	
	Init.source_surface()
	Init.load_spawn()

	local T = Map_info.Pop_info()
	T.localised_category = "biter_battles"
	T.main_caption_color = {r = 170, g = 170, b = 0}
	T.sub_caption_color = {r = 120, g = 120, b = 0}

	local C = Changelog.Pop_changelog()
	C.localised_category = "biter_battles"
	C.main_caption_color = {r = 170, g = 170, b = 0}
	C.sub_caption_color = {r = 120, g = 120, b = 0}
end

local Event = require 'utils.event'
Event.add(defines.events.on_research_finished, Ai.unlock_satellite)			--free silo space tech
Event.add(defines.events.on_entity_died, Ai.on_entity_died)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_console_chat, on_console_chat)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_player_built_tile, on_player_built_tile)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_robot_built_tile, on_robot_built_tile)
Event.add(defines.events.on_tick, on_tick)
Event.on_init(on_init)

require "maps.biter_battles_v2.spec_spy"
require "maps.biter_battles_v2.difficulty_vote"
