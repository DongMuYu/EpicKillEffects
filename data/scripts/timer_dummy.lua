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

-- 局部函数：获取对应的粒子效果文件路径
local function get_effect_file(effect_type, streak)
    if streak >= 1 and streak <= 5 then
        return "data/entities/kill_effect_" .. effect_type .. streak .. ".xml"
    else
        return "data/entities/kill_effect_" .. effect_type .. "1.xml"
    end
end

-- 局部函数：加载粒子效果并添加为子实体
local function load_effect_entity(effect_type, streak, pos_x, pos_y, is_first)
    local effect_file = get_effect_file(effect_type, streak)
    local effect_entity = EntityLoad(effect_file, pos_x, pos_y)
    
    -- -- 如果是第一次播放，设置粒子生命周期为3秒（约180帧）
    -- if is_first then
    --     local particle_comps = EntityGetComponent(effect_entity, "ParticleEmitterComponent") or {}
    --     for _, comp in ipairs(particle_comps) do
    --         ComponentSetValue2(comp, "lifetime_min", 3.0)
    --         ComponentSetValue2(comp, "lifetime_max", 3.0)
    --     end
    -- end
    
    EntityAddChild(entity_id, effect_entity)
    return effect_entity
end

-- 局部函数：播放音效
local function play_kill_sound(streak, pos_x, pos_y)
    if streak > 0 then
        GamePlaySound("mods/EpicKillEffects/data/audio/kills.bank", "kills/kill" .. streak .. "/create", pos_x, pos_y)
    end
end

-- 局部函数：检测周围存在的实体
-- 此函数用于检测当前实体周围一定范围内是否存在其他符合条件的计时器虚实体
-- 主要用于判断是否有其他比自己先出现的计时虚实体在附近，如果是则将其设置为消散阶段
local function detect_nearby_entities()
    -- EntityGetInRadiusWithTag函数获取以当前实体位置(x,y)为中心，半径为60的圆形区域内，
    -- 所有带有"timer_dummy"标签的实体，返回一个实体ID列表
    -- 如果没有找到任何实体，则返回空表（使用or {}确保总是返回表类型）
    local nearby_timer_dummies = EntityGetInRadiusWithTag(x, y, 60, "timer_dummy") or {}
    local valid_nearby = 0  -- 记录符合条件的附近实体数量
    
    -- 获取当前实体的阶段
    local current_stage = stage
    
    -- 计算消散阶段
    local dissipate_stage = total_stages - 1
    
    -- 遍历所有找到的附近计时器虚实体
    for _, nearby_id in ipairs(nearby_timer_dummies) do
        -- 排除当前实体本身，只检查其他实体
        if nearby_id ~= entity_id then
            local nearby_stage = 0     -- 初始化附近实体的当前阶段变量
            -- 获取附近实体的所有VariableStorageComponent组件
            -- 这些组件用于存储实体的各种变量数据
            local nearby_comps = EntityGetComponent(nearby_id, "VariableStorageComponent") or {}
            
            -- 遍历附近实体的所有组件，查找存储当前阶段的组件
            for _, comp in ipairs(nearby_comps) do
                -- 获取组件的名称
                local name = ComponentGetValue2(comp, "name")
                -- 如果组件名称是"current_stage"，则获取其存储的值
                -- 这个值表示该实体当前所处的阶段
                if name == "current_stage" then
                    nearby_stage = ComponentGetValue2(comp, "value_int") or 0
                    break  -- 找到阶段信息后立即退出循环
                end
            end
            
            -- 检查附近实体阶段数是否大于等于当前实体阶段数
            -- 同时排除倒数两个阶段（消散阶段和完成阶段），避免重复显示消失动画
            if nearby_stage >= current_stage and nearby_stage < total_stages - 1 then
                valid_nearby = valid_nearby + 1
                
                -- 如果附近实体阶段数大于等于当前实体阶段数，则将其设置为消散阶段（倒数第二个阶段）
                for _, comp in ipairs(nearby_comps) do
                    local name = ComponentGetValue2(comp, "name")
                    if name == "current_stage" then
                        ComponentSetValue2(comp, "value_int", dissipate_stage)  -- 设置为消散阶段
                        -- GamePrint("timer_dummy.lua 实体ID: " .. tostring(nearby_id) .. " 从阶段" .. nearby_stage .. "被强制设置为消散阶段" .. dissipate_stage)
                        break
                    end
                end
            end
        end
    end
    
    -- 如果检测到实体，打印实体数量
    -- if valid_nearby > 0 then
        -- GamePrint("timer_dummy.lua 实体ID: " .. tostring(entity_id) .. " 检测到 " .. valid_nearby .. " 个比自己先出现的计时器虚实体")
    -- end
end

-- 局部函数：播放a系列粒子效果
local function play_a_effect(is_first)
    -- 获取玩家实体
    local player_entity = get_player_entity_id()
	local effect_entity = nil
    if player_entity and is_first then
        -- 获取玩家位置
        local player_x, player_y = EntityGetTransform(player_entity)
        
        -- 加载粒子效果
        effect_entity = load_effect_entity("a", entity_streak, x, y, true)
        
        -- 只在第一次播放音效
        play_kill_sound(entity_streak, player_x, player_y)

		-- -- 只在第一次创建可视化检查范围
		-- -- 在检测范围边界上放置粒子来可视化检测范围
		-- local visualizer = EntityLoad("data/entities/detection_range_visualizer.xml", x, y)
		
		-- -- 将可视化实体添加为当前实体的子实体
		-- if visualizer then
		-- 	EntityAddChild(entity_id, visualizer)
		-- end
    elseif not is_first then
        -- 加载粒子效果
        effect_entity = load_effect_entity("a", entity_streak, x, y, false)
    end

	return effect_entity
end

-- 局部函数：播放b系列粒子效果并处理c5特效
local function play_b_effect_with_c5()
    -- 加载b系列粒子效果
    load_effect_entity("b", entity_streak, x, y)
    
    -- 当击杀数为5时，额外播放c系列的5
    if entity_streak == 5 then
		load_effect_entity("c", entity_streak, x, y)
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
    
}

-- 动态添加阶段1-60
STAGE_CONFIG[1] = {
    duration = 1.5,  -- 持续时间（帧数）
    description = "释放静态效果",
	action = function() 
		local effect_entity = play_a_effect(true)
		-- if effect_entity then
		-- 	GamePrint("timer_dummy.lua 阶段" .. 1 .. " 播放a系列粒子效果")
		-- end
	end
}

for i = 2, 120 do
    STAGE_CONFIG[i] = {
    duration = 1.5,  -- 持续时间（帧数）
    description = "释放静态效果",
	action = function() 
		local effect_entity = play_a_effect(false)
		-- if effect_entity then
		-- 	GamePrint("timer_dummy.lua 阶段" .. i .. " 播放a系列粒子效果")
		-- end

		detect_nearby_entities()  -- 每一阶段都检测周围实体
	end
}
end

-- 添加其他阶段
STAGE_CONFIG[121] = {	
    duration = 100,  -- 持续时间（帧数）
    description = "释放消散效果",
	action = function() play_b_effect_with_c5() end
}

STAGE_CONFIG[122] = {
    duration = 1,  -- 持续时间（帧数）
    description = "完成状态，删除实体",
	action = function() 
		EntityKill(entity_id)
	end
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
