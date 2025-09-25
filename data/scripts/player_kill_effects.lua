-- 玩家击杀敌人效果组件
-- 功能：给附近的敌人添加死亡效果组件

dofile_once("data/scripts/lib/utilities.lua")

dofile_once("data/scripts/timer.lua")
dofile_once("data/scripts/counter.lua")

-- 加载测试模块
dofile_once( "data/scripts/test.lua" )

-- 获取玩家实体ID
local entity_id = GetUpdatedEntityID()
local x, y = EntityGetTransform( entity_id )

-- 主要逻辑：给敌人添加死亡效果组件

-- -- 打印计时器信息做调试
-- local timer_comp = find_timer_variable_storage(entity_id)
-- if timer_comp then
-- 	local timer_name = ComponentGetValue2(timer_comp, "name")
-- 	GamePrint("计时器名称: " .. (timer_name or "nil"))

--     local timer_value_string = ComponentGetValue2(timer_comp, "value_string")
-- 	local timer_value_float = ComponentGetValue2(timer_comp, "value_float")
--     GamePrint("当前计时器值: " .. (timer_value_float or "nil"))
--     GamePrint("当前计时器字符串: " .. (timer_value_string or "nil"))
-- 	GamePrint("==============================================")
-- end


-- -- 打印连击计数器信息做调试
-- local kill_streak_comp = find_kill_streak_variable_storage(entity_id)
-- if kill_streak_comp then
-- 	local kill_streak_name = ComponentGetValue2(kill_streak_comp, "name")
-- 	GamePrint("连击计数器名称: " .. (kill_streak_name or "nil"))

--     local kill_streak_value_string = ComponentGetValue2(kill_streak_comp, "value_string")
--     local kill_streak_value_int = ComponentGetValue2(kill_streak_comp, "value_int")
-- 	local kill_streak_value_float = ComponentGetValue2(kill_streak_comp, "value_float")
-- 	GamePrint("当前连击计数器值 (int): " .. (kill_streak_value_int or "nil"))
--     GamePrint("当前连击计数器值 (float): " .. (kill_streak_value_float or "nil"))
--     GamePrint("当前连击计数器字符串: " .. (kill_streak_value_string or "nil"))
--     GamePrint("==============================================")
-- end

-- 扫描160像素范围内所有可瞄准的敌人
local targets = EntityGetInRadiusWithTag( x, y, 180, "homing_target" )

-- GamePrint("玩家击杀敌人效果组件已加载")

if ( #targets > 0 ) then
	for i,target_id in ipairs( targets ) do
		
		-- 检查是否已经有死亡效果组件
		local has_death_component = false
		local lua_components = EntityGetComponent( target_id, "LuaComponent" )
		
		if ( lua_components ~= nil ) then
			for k,component_id in ipairs( lua_components ) do
				local script_file = ComponentGetValue( component_id, "script_death" )
				local execute_frame = ComponentGetValue( component_id, "execute_every_n_frame" )
				-- 检查是否有一模一样的死亡效果组件
				if ( script_file == "data/scripts/death_effects.lua" and execute_frame == "-1" ) then
					has_death_component = true
					break
				end
			end
		end
		
		-- 如果没有死亡效果组件，则添加
		if ( has_death_component == false ) then
			EntityAddComponent( target_id, "LuaComponent", 
			{ 
				script_death = "data/scripts/death_effects.lua",
				execute_every_n_frame = "-1", -- 不执行，只在死亡时触发
			} )
		end
	end
end


-- 处理玩家实体上的计时器
-- 如果有连击，更新计时器

-- 检查玩家实体上的计数器
local kill_streak_comp = find_kill_streak_variable_storage(entity_id)
if kill_streak_comp then
	local kill_streak = get_kill_streak(entity_id)
	if kill_streak > 0 then
		global_update_timer(entity_id)

		-- 如果计时器过期（超过300帧），重置系统
		if not global_is_in_streak_window(entity_id, 300) then
			-- GamePrint("计时器过期，重置连击系统")

			-- 重置计时器
			global_reset_timer(entity_id)
			
			-- 重置连击值
			set_kill_streak(entity_id, 0)
		end

		-- 获取当前时间
		-- local current_frame = global_get_frame_count(entity_id)
		-- GamePrint("player_kill_effects 当前时间: " .. tostring(current_frame))
	end
else
	-- GamePrint("player_kill_effects 没有找到玩家实体上的计数器")
end
