ModRegisterAudioEventMappings("mods/EpicKillEffects/data/audio/GUIDs.txt")

dofile_once( "data/scripts/lib/utilities.lua" )
dofile_once("data/scripts/timer.lua")
dofile_once("data/scripts/counter.lua")

-- 加载GUI模块
dofile_once( "data/ui/main_ui.lua" )

GamePrint("init.lua 组件系统加载成功")

local player_entity = nil

-- all functions below are optional and can be left out

--[[

function OnModPreInit()
	print("Mod - OnModPreInit()") -- First this is called for all mods
end

function OnModInit()
	print("Mod - OnModInit()") -- After that this is called for all mods
end

function OnModPostInit()
	print("Mod - OnModPostInit()") -- Then this is called for all mods
end
]]--

function OnPlayerSpawned( entity ) -- This runs when player entity has been created
	-- GamePrint( "====================================================================" )
	GamePrint( "OnPlayerSpawned() - Player entity id: " .. tostring(entity) )
	player_entity = entity

	-- 初始化计数器组件（如果还没有的话）- 只执行一次
	-- 这确保了玩家实体都有一个计数器组件，用于记录连击数
	add_kill_streak_variable_storage(player_entity)

	-- 初始化计时器组件（如果还没有的话）- 只执行一次
	-- 这确保了玩家实体都有一个计时器组件，用于记录连击时间
	add_timer_variable_storage(player_entity)

	-- GamePrint( "====================================================================" )
end

function OnWorldInitialized() -- This is called once the game world is initialized. Doesn't ensure any world chunks actually exist. Use OnPlayerSpawned to ensure the chunks around player have been loaded or created.
	-- GamePrint( "EpicKillEffects mod: 世界初始化" )
end

--[[

function OnWorldPreUpdate() -- This is called every time the game is about to start updating the world
	GamePrint( "Pre-update hook " .. tostring(GameGetFrameNum()) )
end

]]--

function OnWorldPostUpdate() -- This is called every time the game has finished updating the world
	-- -- 获取玩家实体
	-- if not player_entity then
	-- 	return
	-- end

	-- Gui_Update()
end

