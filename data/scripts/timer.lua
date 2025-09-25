-- =============================================================================
-- 计时器模块 - 组件版本
-- =============================================================================
-- 功能：使用组件系统提供计时功能
-- 包含：基础计时器操作、虚实体计时器创建、组件管理工具函数
-- =============================================================================

-- =============================================================================
-- 基础计时器操作函数
-- =============================================================================

-- 每帧更新计时器帧数
-- @param entity_id 目标实体ID
function global_update_timer(entity_id)
    if not entity_id then
        GamePrint("计时器更新错误：找不到实体")
        return
    end
    
    local timer_comp = find_timer_variable_storage(entity_id)
    if timer_comp then
        local current_frame = global_get_frame_count(entity_id)
        current_frame = current_frame + 1
        ComponentSetValue2(timer_comp, "value_float", current_frame)
        return
    end
    
    GamePrint("计时器更新错误：找不到实体的计时器组件")
    return
end

-- 获取实体当前计时器帧数
-- @param entity_id 目标实体ID
-- @return 当前帧数（找不到返回0）
function global_get_frame_count(entity_id)
    if not entity_id then
        GamePrint("计时器获取错误：找不到实体")
        return 0
    end
    
    local timer_comp = find_timer_variable_storage(entity_id)
    if timer_comp then
        return ComponentGetValue2(timer_comp, "value_float") or 0
    end
    
    GamePrint("计时器获取错误：找不到实体的计时器组件")
    return 0
end

-- 重置实体计时器为0
-- @param entity_id 目标实体ID
-- @return 成功返回true，失败返回false
function global_reset_timer(entity_id)
    if not entity_id then
        GamePrint("计时器重置错误：找不到实体")
        return false
    end
    
    local timer_comp = find_timer_variable_storage(entity_id)
    if timer_comp then
        ComponentSetValue2(timer_comp, "value_float", 0)
        return true
    end
    
    GamePrint("计时器重置错误：找不到实体的计时器组件")
    return false
end

-- 检查当前时间是否在指定时间窗口内
-- @param entity_id 目标实体ID
-- @param window_duration 时间窗口长度（帧数）
-- @return 在时间窗口内返回true，否则返回false
function global_is_in_streak_window(entity_id, window_duration)
    if not entity_id then
        GamePrint("计时器检查错误：找不到实体")
        return false
    end
    
    local current_time = global_get_frame_count(entity_id)
    -- GamePrint("timer.lua 实体ID: " .. tostring(entity_id) .. " 当前帧: " .. tostring(current_time))

    if current_time <= window_duration then
        return true
    else
        -- GamePrint("timer.lua 实体ID: " .. tostring(entity_id) .. " 当前帧: " .. tostring(current_time))
        return false
    end
end

-- =============================================================================
-- 虚实体计时器创建函数
-- =============================================================================

-- 创建虚实体计时器（使用XML实体文件版本）
-- 加载data/entities/timer_dummy.xml文件并配置参数
-- @param target_id 目标实体ID（必须提供有效ID或nil）
-- @param x 创建位置的X坐标（必须提供有效值）
-- @param y 创建位置的Y坐标（必须提供有效值）
-- @param duration 存在时间（秒，必须提供有效值），-1表示永久存在
-- @return 创建的虚实体ID，参数错误返回nil
function global_create_timer_dummy(target_id, x, y, duration)
    
    -- 严格参数检查 - 不允许使用默认值
    -- 检查duration参数
    if duration == nil then
        GamePrint("错误：必须提供duration参数（存在时间，秒）")
        return nil
    end
    
    -- 检查坐标参数（当target_id为nil时）
    if target_id == nil then
        if x == nil then
            GamePrint("错误：当target_id为nil时，必须提供x坐标")
            return nil
        end
        if y == nil then
            GamePrint("错误：当target_id为nil时，必须提供y坐标")
            return nil
        end
    end
    
    -- 确定创建位置
    local spawn_x, spawn_y
    
    -- 如果提供了目标实体ID，获取其位置
    if target_id ~= nil then
        if not EntityGetIsAlive(target_id) then
            GamePrint("错误：提供的target_id实体不存在或已死亡")
            return nil
        end
        
        local target_x, target_y = EntityGetTransform(target_id)
        if target_x == nil or target_y == nil then
            GamePrint("错误：无法获取target_id实体的位置")
            return nil
        end
        spawn_x, spawn_y = target_x, target_y
    else
        -- 使用提供的坐标
        spawn_x, spawn_y = x, y
    end
    
    -- 加载timer_dummy.xml虚实体
    local dummy_entity = EntityLoad("data/entities/timer_dummy.xml", spawn_x, spawn_y)

    -- 配置虚实体参数
    if dummy_entity then
        local var_comps = EntityGetComponent(dummy_entity, "VariableStorageComponent") or {}
        for _, comp in ipairs(var_comps) do
            local comp_name = ComponentGetValue2(comp, "name")
            if comp_name == "timer_duration" then
                ComponentSetValue2(comp, "value_int", duration)
            end
        end
    end
    
    if not dummy_entity then
        GamePrint("错误：虚实体加载失败")
        return nil
    end
    
    -- GamePrint("虚实体计时器创建成功：ID=" .. tostring(dummy_entity) .. "，位置=(" .. spawn_x .. ", " .. spawn_y .. ")，存在时间=" .. duration .. "秒")
    return dummy_entity
end

-- =============================================================================
-- 组件管理工具函数
-- =============================================================================

-- 查找实体身上是否带有"计时器" VariableStorageComponent
-- @param entity_id 目标实体ID
-- @return 找到返回组件ID，未找到返回nil
function find_timer_variable_storage(entity_id)
    if not entity_id or not EntityGetIsAlive(entity_id) then
        GamePrint("错误：实体无效或不存在")
        return nil
    end

    -- 拿到所有 VariableStorageComponentQ
    local comps = EntityGetComponent(entity_id, "VariableStorageComponent") or {}
    for _, comp in ipairs(comps) do
                -- 比对 name 字段
        local name = ComponentGetValue2(comp, "name")
        if name == "timer" then
            return comp
        end
    end

    -- GamePrint("find_timer_variable_storage 未找到计时器组件")
    return nil
end

-- 修改指定实体上"计时器" VariableStorageComponent的值
-- @param entity_id 目标实体ID
-- @param frame_count 要设置的帧数值
-- @return 成功返回true，失败返回false
function set_timer_variable_storage_modified(entity_id, frame_count)
    if not entity_id or not EntityGetIsAlive(entity_id) then
        GamePrint("错误：实体无效或不存在")
        return false
    end

    local comps = EntityGetComponent(entity_id, "VariableStorageComponent") or {}
    for _, comp in ipairs(comps) do
        if ComponentGetValue2(comp, "name") == "timer" then
            ComponentSetValue2(comp, "value_string", "true")
            ComponentSetValue2(comp, "value_float", frame_count)
            return true
        end
    end

    GamePrint("未找到计时器组件，修改失败")
    return false
end

-- 给实体添加计时器VariableStorageComponent
-- @param entity_id 目标实体ID
function add_timer_variable_storage(entity_id)
    if not entity_id then
        GamePrint("add_timer_variable_storage 错误：找不到实体")
        return
    end
    
    -- 检查是否已存在计时器组件
    local existing_comp = find_timer_variable_storage(entity_id)
    if existing_comp then
        return
    end
    
    -- 添加新的VariableStorageComponent
    local comp = EntityAddComponent2(entity_id, "VariableStorageComponent",
    {
        name = "timer",
        value_string = "false",
    })
    
    if comp then
        -- GamePrint("成功添加计时器组件到实体: " .. tostring(entity_id))
        return
    else
        GamePrint("添加计时器组件失败")
        return
    end
end