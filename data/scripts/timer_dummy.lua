-- timer_dummy.lua
-- 虚实体计时器脚本
dofile_once("data/scripts/timer.lua")
dofile_once("data/scripts/counter.lua")

local entity_id = GetUpdatedEntityID()
local x, y = EntityGetTransform(entity_id)

-- GamePrint("timer_dummy.lua 实体ID: " .. entity_id .. " 位置: (" .. x .. ", " .. y .. ")")
-- 一次性获取所有组件，避免重复访问XML
local dummy_duration = 0
local stage = 0
local total_stages = 0
local is_released = "false"  -- 使用string类型存储释放状态
local entity_streak = 0  -- 记录实体创建时的连击数

-- 获取所有VariableStorageComponent组件
local var_comps = EntityGetComponent(entity_id, "VariableStorageComponent")
if var_comps ~= nil then
	for _, comp in ipairs(var_comps) do
		local comp_name = ComponentGetValue2(comp, "name")
		if comp_name == "timer_duration" then
			dummy_duration = ComponentGetValue2(comp, "value_int") or 0
		elseif comp_name == "current_stage" then
			stage = ComponentGetValue2(comp, "value_int") or 0
			is_released = ComponentGetValue2(comp, "value_string") or "false"
		elseif comp_name == "total_stages" then
			total_stages = ComponentGetValue2(comp, "value_int") or 0
		elseif comp_name == "entity_streak" then
			entity_streak = ComponentGetValue2(comp, "value_int") or 0
		end
		-- 如果值都已获取，提前退出循环
		if dummy_duration ~= 0 and stage ~= 0 and total_stages ~= 0 and entity_streak ~= 0 then
			break
		end
	end
end

-- 阶段配置表 - 记录各种阶段的持续时间以及阶段的动作
local STAGE_CONFIG = {
    -- 阶段0: 初始状态，不显示任何效果
    [0] = {
        duration = 0,  -- 持续时间（帧数）
        effect_path = nil,  -- 粒子效果路径
        description = "初始状态，不显示任何效果",
		action = function() 
			GamePrint("timer_dummy.lua 阶段0 不符合预期 不播放任何效果")
		end  -- 动作类型
    },
    
    -- 阶段1: 显示前静止粒子效果
    [1] = {
        duration = 180,  -- 持续时间
        effect_path = "data/entities/kill_effect_a1.xml",  -- 粒子效果路径
        description = "显示前静止粒子效果",
		action = function() 
			-- GamePrint("===========================================")
			-- GamePrint("timer_dummy.lua 阶段1 显示前静止粒子效果")
			-- GamePrint("===========================================")
			
			-- 获取玩家实体
			local player_entity = get_player_entity_id()
			if player_entity then
				-- 获取玩家位置
				local player_x, player_y = EntityGetTransform(player_entity)
				
				-- 根据连击数加载对应的粒子效果
				local effect_file = "data/entities/kill_effect_a1.xml"
				if entity_streak >= 1 and entity_streak <= 5 then
					effect_file = "data/entities/kill_effect_a" .. entity_streak .. ".xml"
				end

				-- effect_file = "data/entities/kill_effect_c1.xml"
				-- if entity_streak >= 1 and entity_streak <= 5 then
				-- 	effect_file = "data/entities/kill_effect_c" .. entity_streak .. ".xml"
				-- end
				
				-- 加载粒子效果
				EntityLoad(effect_file, x, y)
				
				-- 播放对应连击数的音效
				if entity_streak > 0 then
					GamePlaySound("mods/EpicKillEffects/data/audio/kills.bank", "kills/kill" .. entity_streak .. "/create", player_x, player_y)
					-- GamePrint("timer_dummy.lua 播放连击音效: kill" .. entity_streak)
				end
			else
				GamePrint("timer_dummy.lua 错误：找不到玩家实体")
			end
		end  -- 动作类型
    },
    
    -- 阶段2: 显示消散粒子效果
    [2] = {
        duration = 100,  -- 持续时间
        effect_path = "data/entities/kill_effect_b1.xml",  -- 粒子效果路径
        description = "显示消散粒子效果",
		action = function() 
			-- GamePrint("===========================================")
			-- GamePrint("timer_dummy.lua 阶段2 显示消散粒子效果")
			-- GamePrint("===========================================")
			
			-- 根据实体创建时的连击数加载对应的粒子效果
			local effect_file = "data/entities/kill_effect_b1.xml"
			if entity_streak >= 1 and entity_streak <= 5 then
				effect_file = "data/entities/kill_effect_b" .. entity_streak .. ".xml"
			end
			
			-- 加载粒子效果
			EntityLoad(effect_file, x, y)
		end  -- 动作类型
    },
    
    -- 阶段3: 完成状态，删除实体
    [3] = {
        duration = 1,  -- 持续时间（帧数）
        description = "完成状态，删除实体",
		action = function() 
			-- GamePrint("===========================================")
			-- GamePrint("timer_dummy.lua 阶段3 完成状态，删除实体")
			-- GamePrint("===========================================")
			EntityKill(entity_id)
		end
    }
}

-- 获取阶段配置的辅助函数
local function get_stage_config(stage_num)
    return STAGE_CONFIG[stage_num] or STAGE_CONFIG[0]
end

-- 标记实体释放状态的函数
local function set_release_state(released)
	local comps = EntityGetComponent(entity_id, "VariableStorageComponent") or {}
	for _, comp in ipairs(comps) do
        local name = ComponentGetValue2(comp, "name")
		if name == "current_stage" then
			ComponentSetValue2(comp, "value_string", released and "true" or "false")
			-- GamePrint("timer_dummy.lua 标记实体为" .. (released and "已" or "未") .. "释放状态")
			return true
		end
    end

	GamePrint("timer_dummy.lua 错误：未找到current_stage组件")
	return false
end

-- 处理虚实体上的计时器
global_update_timer(entity_id)

-- 调试：获取当前帧计数
-- local frame_count = global_get_frame_count(entity_id)
-- GamePrint("timer_dummy.lua 实体ID: " .. tostring(entity_id) .. " 当前帧计数: " .. tostring(frame_count))

-- 处理实体持续时间：
-- 1. 当 dummy_duration >= 0 时，每帧减少持续时间
-- 2. 更新实体存储的持续时间
-- 3. 设置为 负数 时，实体不会因时间到达而删除
if dummy_duration >= 0 then

	if dummy_duration == 0 then
		GamePrint("timer_dummy.lua 实体ID: " .. tostring(entity_id) .. " 持续时间已到 实体将被删除")
		EntityKill(entity_id)
		return
	end

    -- 减少实体持续时间
    dummy_duration = dummy_duration - 1
	-- GamePrint("timer_dummy.lua 实体ID: " .. tostring(entity_id) .. " 持续时间: " .. tostring(dummy_duration) .. " 当前阶段: " .. tostring(stage) .. " 总阶段数: " .. tostring(total_stages))

    -- 更新实体存储的持续时间
    local var_storage_comps = EntityGetComponent(entity_id, "VariableStorageComponent")
    if var_storage_comps then
        for _, comp in ipairs(var_storage_comps) do
            local comp_name = ComponentGetValue2(comp, "name")
            if comp_name == "timer_duration" then
                ComponentSetValue2(comp, "value_int", dummy_duration)
                break
            end
        end
    end
end

-- 获取当前阶段的配置
local stage_config = get_stage_config(stage)

-- 如果计时器过期，重置系统
-- 提前检查duration有效性，避免无效计算
-- GamePrint("timer_dummy.lua 实体ID: " .. tostring(entity_id) .. " 持续时间: " .. tostring(dummy_duration) .. " 当前阶段: " .. tostring(stage) .. " 总阶段数: " .. tostring(total_stages))
if dummy_duration > 0 and not global_is_in_streak_window(entity_id, stage_config.duration) then
	-- GamePrint("计时器过期，重置连击系统")
	-- GamePrint("timer_dummy.lua 实体ID: " .. tostring(entity_id) .. " 实体存在持续时间: " .. tostring(dummy_duration) .. " 当前阶段: " .. tostring(stage) .. " 总阶段数: " .. tostring(total_stages))

	-- 重置计时器
	global_reset_timer(entity_id)
	
	-- 标记实体为未释放状态
	set_release_state(false)
	
	stage = stage + 1

	-- 更新当前阶段
	local comps = EntityGetComponent(entity_id, "VariableStorageComponent")
	if comps ~= nil then
		for _, comp in ipairs(comps) do
			local comp_name = ComponentGetValue2(comp, "name")
			if comp_name == "current_stage" then
				ComponentSetValue2(comp, "value_int", stage)
			end
		end
	end

	-- 检查阶段是否超出总阶段数
	if stage > total_stages then
		GamePrint("timer_dummy.lua 阶段" .. tostring(stage) .. " 超出总阶段数" .. tostring(total_stages) .. " 重置为0")
		stage = 0

		-- 直接清除实体
		EntityKill(entity_id)
		GamePrint("超过了总阶段数： 触发保险清除实体")

		return
	end
end

-- 根据阶段播放对应的粒子效果
-- 检查是否已经释放，如果已释放则不播放效果
if is_released == "true" then
	return
end

if stage_config.action then
	stage_config.action()
	-- 标记实体为已释放状态
	set_release_state(true)
end
