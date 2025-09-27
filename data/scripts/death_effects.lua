-- 通用死亡效果脚本
-- 功能：处理实体的各种死亡效果，包含连击音效系统
-- 触发条件：带有死亡标记的实体死亡时调用

dofile_once("data/scripts/lib/utilities.lua")

dofile_once("data/scripts/timer.lua")
dofile_once("data/scripts/counter.lua")

local KILL_STREAK_MAX = 5

-- 智能播放击杀效果和音效
-- 功能：根据环境障碍物智能选择最佳的击杀粒子效果播放位置
-- 优先级：正上方 > 斜向上(左上/右上) > 左右方向 > 斜向下(左下/右下) > 正下方
-- 检测方式：使用RaytraceSurfaces仅检测固体表面，忽略气体和液体
-- 参数：
--   streak_count - 当前连击数(1-5)
--   death_entity_id - 死亡实体的ID
--   player_entity - 玩家实体ID
-- 返回：无，播放粒子效果和音效
local function PlayKillEffectsAndSound(streak_count, death_entity_id, player_entity)
    -- 获取死亡实体位置
    local death_pos_x, death_pos_y = EntityGetTransform(death_entity_id)
    -- 获取玩家位置
    local player_pos_x, player_pos_y = EntityGetTransform(player_entity)
    
    -- 定义检测距离
    local DETECTION_DISTANCE = 30  -- 固定像素检测距离
    
    -- 按优先级排序的检测方向：正上方 > 斜向上 > 左右 > 斜向下 > 正下方
    -- 这个优先级确保击杀效果向上播放
    local prioritized_directions = {
        -- 第一优先级：正上方(最自然的效果方向)
        {name = "up", dx = 0, dy = -1, priority = 100},
        
        -- 第二优先级：斜向上(左上、右上)
        {name = "up_left", dx = -0.707, dy = -0.707, priority = 90},   -- 左上对角线
        {name = "up_right", dx = 0.707, dy = -0.707, priority = 90},   -- 右上对角线
        
        -- 第三优先级：左右水平方向
        {name = "left", dx = -1, dy = 0, priority = 70},               -- 左方
        {name = "right", dx = 1, dy = 0, priority = 70},               -- 右方
        
        -- 第四优先级：斜向下(左下、右下)
        {name = "down_left", dx = -0.707, dy = 0.707, priority = 50},  -- 左下对角线
        {name = "down_right", dx = 0.707, dy = 0.707, priority = 50},  -- 右下对角线
        
        -- 第五优先级：正下方(最不自然，最后选择)
        {name = "down", dx = 0, dy = 1, priority = 30}
    }
    
    -- 检测所有方向的阻挡情况
    local blocked_status = {}
    
    -- 按照优先级顺序检测每个方向（从最优到最差）
    -- 这样确保优先使用最自然的方向展示击杀效果
    for _, dir in ipairs(prioritized_directions) do
        -- 计算检测目标位置（固定像素距离）
        local target_x = death_pos_x + dir.dx * DETECTION_DISTANCE
        local target_y = death_pos_y + dir.dy * DETECTION_DISTANCE
        
        -- 特殊处理：向上检测时，从死亡位置往上8像素开始检测，避免边缘阻挡
        local start_x, start_y = death_pos_x, death_pos_y
        if dir.name == "up" then
            start_y = death_pos_y - 12  -- 往上12像素开始检测
        end
        
        -- 使用RaytraceSurfaces检测，仅被固体/液体表面挡住，气体、火可穿过
        -- 这个API确保不会被烟雾、蒸汽等气体阻挡
        local hit_solid = RaytraceSurfaces(start_x, start_y, target_x, target_y)
        
        -- 检测结果
        blocked_status[dir.name] = {
            distance = DETECTION_DISTANCE,
            blocked = hit_solid,
            target_x = target_x,
            target_y = target_y,
            priority = dir.priority  -- 保存优先级分数
        }
    end
    
    -- 智能选择最佳播放位置
    -- 评分规则：只考虑优先级和阻挡状态
    -- 1. 优先级分数：正上方 > 斜向上 > 左右 > 斜向下 > 正下方
    -- 2. 阻挡状态：只选择未被阻挡的位置
    local best_score = -1
    local best_pos = nil
    local best_dir = nil
    
    -- 按照优先级顺序评估每个位置（确保优先选择最佳方向）
    for _, dir in ipairs(prioritized_directions) do
        local dir_status = blocked_status[dir.name]
        
        -- 只考虑未被阻挡的位置
        if not dir_status.blocked then
            -- 选择优先级最高的位置
            if dir_status.priority > best_score then
                best_score = dir_status.priority
                best_pos = {x = dir_status.target_x, y = dir_status.target_y}
                best_dir = dir.name
                
                -- 找到最优位置后立即停止搜索（性能优化）
                -- 因为我们按优先级顺序搜索，第一个找到的就是最好的
                break
            end
        end
    end
    
    -- 构建最佳位置信息
    local best_position = nil
    if best_pos then
        best_position = {
            x = best_pos.x,
            y = best_pos.y,
            direction = best_dir,
            distance = DETECTION_DISTANCE,  -- 固定距离像素
            layer = 1  -- 单层检测，层级始终为1
        }
    end
    
    -- 确定最终播放位置
    local effect_pos_x, effect_pos_y
    
    if best_position then
        -- 找到可用位置
        local offset_x = (best_position.x - death_pos_x) * 1.3
        local offset_y = (best_position.y - death_pos_y) * 1.3
        effect_pos_x = death_pos_x + offset_x
        effect_pos_y = death_pos_y + offset_y
    else

        -- 实在不行就默认向上播放
        effect_pos_x = death_pos_x
        effect_pos_y = death_pos_y - DETECTION_DISTANCE
    end
    
    -- 在死亡位置创建虚实体计时器
    local dummy_entity = global_create_timer_dummy(nil, effect_pos_x, effect_pos_y, 999)

    -- 给虚实体添加计时器组件
    add_timer_variable_storage(dummy_entity)
    
    -- 添加entity_streak组件，记录当前连击数
    EntityAddComponent2(dummy_entity, "VariableStorageComponent", {
        name = "entity_streak",
        value_int = streak_count
    })
    
    -- 调试信息（仅在开发时启用，减少内存占用）
    -- local debug_info = "智能检测完成(RaytraceSurfaces): "
    -- if best_position then
    --     debug_info = debug_info .. "最佳方向=" .. best_position.direction .. 
    --                 " 距离=" .. best_position.distance .. 
    --                 " 最终位置=(" .. string.format("%.1f", effect_pos_x) .. "," .. string.format("%.1f", effect_pos_y) .. ")"
    -- else
    --     debug_info = debug_info .. "所有方向受阻，使用备用方案"
    -- end
    -- GamePrint(debug_info)
    
    -- 详细检测信息（调试用）
    -- local detail_info = "详细检测: "
    -- for _, dir in ipairs(prioritized_directions) do
    --     local dir_data = blocked_status[dir.name]
    --     if dir_data then
    --         detail_info = detail_info .. dir.name .. "(" .. (dir_data.blocked and "阻" or "通") .. ") "
    --     end
    -- end
    -- GamePrint(detail_info)
end

-- 局部函数：更新连击计数
local function update_kill_streak(player_entity)

    -- 查找玩家身上是否带有“连击计数器 VariableStorageComponent”
    local kill_streak_comp = find_kill_streak_variable_storage(player_entity)
    if not kill_streak_comp then
        GamePrint("错误：找不到玩家身上的连击计数器组件")
        return
    end

    -- 更新连击数
    local current_streak = get_kill_streak(player_entity) or 0
    current_streak = current_streak + 1
    set_kill_streak(player_entity, current_streak)
    -- GamePrint("当前连击数: " .. current_streak)

    return current_streak
end

-- 局部函数：处理连击效果和音效
local function handle_kill_streak_effects(player_entity, entity_id, current_streak)

    -- GamePrint("handle_kill_streak_effects 处理连击效果，当前连击数: " .. current_streak)
    -- 如果当前连击数为0 则不处理
    if current_streak == 0 then
        return
    end

    -- 连击数小于目标值时（正常连击）
    if current_streak < KILL_STREAK_MAX then
        -- GamePrint("条件(1) 当前连击数: " .. tostring(current_streak)) -- 调试使用

        -- 重置计时器
        global_reset_timer(player_entity)

        -- 使用智能播放函数播放效果和音效
        PlayKillEffectsAndSound(current_streak, entity_id, player_entity)

        -- 显示击杀效果
        -- GamePrint("当前连击数: " .. tostring(current_streak)) -- 调试使用
        return

    -- 连击数等于目标值时（最后一次击杀）
    elseif current_streak == KILL_STREAK_MAX then
        -- GamePrint("条件(2) 当前连击数: " .. tostring(current_streak)) -- 调试使用
        
        -- 使用智能播放函数播放最终击杀效果和音效
        PlayKillEffectsAndSound(current_streak, entity_id, player_entity)
        
        -- 显示五杀完成信息
        -- GamePrint("五杀完成！连击重置！")
        
        -- 重置计时器和连击值
        global_reset_timer(player_entity)
        set_kill_streak(player_entity, 0)
        
        return
        
    -- 连击数超出目标值时（保险处理）
    else
        -- 重置计时器和连击值
        global_reset_timer(player_entity)
        set_kill_streak(player_entity, 0)
        return
    end
end

function death( damage_type_bit_field, damage_message, entity_thats_responsible, drop_items )

    local player_entity = get_player_entity_id()
    if not player_entity then
        GamePrint("update_kill_streak 错误：找不到玩家实体")
        return
    end

	-- 获取死亡实体的ID和位置
	local entity_id = GetUpdatedEntityID()
    if not entity_id or not EntityGetIsAlive(entity_id) then
        GamePrint("错误：实体无效或不存在")
        return
    end
	-- GamePrint("实体 " .. entity_id .. " 死亡")
	
	-- 更新连击计数
    local current_streak = update_kill_streak(player_entity)
	
	-- 处理连击效果和音效
	handle_kill_streak_effects(player_entity, entity_id, current_streak)
end
