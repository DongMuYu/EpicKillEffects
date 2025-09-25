
-- 获取玩家实体ID
function get_player_entity_id()
    local player_entities = EntityGetWithTag("player_unit")
    if player_entities and #player_entities > 0 then
        local player_entity = player_entities[1]  -- 获取第一个玩家实体
        if EntityGetIsAlive(player_entity) then
            return player_entity
        end
    end
    GamePrint("get_player_entity_id 错误：找不到玩家实体")
    return nil
end


-- 查找实体身上是否带有“连击计数器 VariableStorageComponent”
function find_kill_streak_variable_storage(entity_id)
    if not entity_id or not EntityGetIsAlive(entity_id) then
        GamePrint("find_kill_streak_variable_storage 错误：实体无效或不存在")
        return nil
    else
        -- GamePrint("find_kill_streak_variable_storage 实体有效，ID: " .. tostring(entity_id))
    end

    -- 拿到所有 VariableStorageComponent
    local comps = EntityGetComponent(entity_id, "VariableStorageComponent") or {}
    for _, comp in ipairs(comps) do
        -- 比对 name 字段
        local name = ComponentGetValue2(comp, "name")
        if name == "kill_streak" then
            -- GamePrint("找到连击计数器组件，ID: " .. tostring(comp))
            return comp
        end
    end

    -- GamePrint("find_kill_streak_variable_storage 未找到连击计数器组件")
    return nil
end

-- 查看实体身上连击的计数
function get_kill_streak(entity_id)
    local comp = find_kill_streak_variable_storage(entity_id)
    if comp then
        return ComponentGetValue2(comp, "value_int")
    end

    GamePrint("未找到连击计数器组件，返回0")
    return 0
end

-- 修改指定实体上“连击计数器 VariableStorageComponent”的 value_string 字段
function set_kill_streak_variable_storage_modified(entity_id)
    if not entity_id or not EntityGetIsAlive(entity_id) then
        GamePrint("错误：实体无效或不存在")
        return false
    end

    -- 手动遍历所有 VariableStorageComponent
    local comps = EntityGetComponent(entity_id, "VariableStorageComponent") or {}
    for _, comp in ipairs(comps) do
        if ComponentGetValue2(comp, "name") == "kill_streak" then
            ComponentSetValue2(comp, "value_string", "连击计数器组件被修改")
            GamePrint("已成功修改连击计数器组件的 value_string")
            return true
        end
    end

    GamePrint("未找到连击计数器组件，修改失败")
    return false
end

-- 设置连击值
function set_kill_streak(entity_id, value)
    local comp = find_kill_streak_variable_storage(entity_id)
    if comp then
        ComponentSetValue2(comp, "value_int", value)
        -- GamePrint("已成功设置连击值为 " .. value)
        return true
    end
    GamePrint("未找到连击计数器组件，设置失败")
    return false
end

-- 给实体添加连击计数器VariableStorageComponent的函数
function add_kill_streak_variable_storage(entity_id)
    if not entity_id then
        GamePrint("add_kill_streak_variable_storage 错误：找不到实体")
        return
    end
    -- GamePrint("add_kill_streak_variable_storage 尝试添加连击计数器组件到实体: " .. tostring(entity_id))

    -- 检查是否已存在连击计数器组件
    local existing_comp = find_kill_streak_variable_storage(entity_id)
    -- GamePrint("add_kill_streak_variable_storage 检查实体是否已存在连击计数器组件: " .. tostring(existing_comp))
    if existing_comp then
        -- GamePrint("连击计数器组件已存在，跳过添加")
        return
    end
    
    -- 添加新的VariableStorageComponent
    local comp = EntityAddComponent2(entity_id, "VariableStorageComponent",
    {
        name = "kill_streak",
        value_string = "false",
		value_int = 0,
		value_float = 0.00
    })
    
    if comp then
        -- GamePrint("成功添加连击计数器组件到实体: " .. tostring(entity_id))
        return
    else
        GamePrint("添加连击计数器组件失败")
        return
    end
end