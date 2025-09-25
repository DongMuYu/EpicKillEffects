-- 查找玩家身上是否带有“测试 VariableStorageComponent”
-- 不依赖 EntityGetFirstComponent，仅依赖 EntityGetComponent
-- @param entity_id 玩家实体 ID
-- @return 组件 ID（number）或 nil（未找到）
function find_test_variable_storage(entity_id)
    if not entity_id or not EntityGetIsAlive(entity_id) then
        GamePrint("错误：实体无效或不存在")
        return nil
    end

    -- 拿到所有 VariableStorageComponent
    local comps = EntityGetComponent(entity_id, "VariableStorageComponent") or {}
    for _, comp in ipairs(comps) do
        -- 比对 name 字段
        local name = ComponentGetValue2(comp, "name")
        if name == "epic_kill_effects_test" then
            -- GamePrint("找到测试组件，ID: " .. tostring(comp))
            return comp
        end
    end

    GamePrint("未找到测试组件")
    return nil
end

-- 修改指定实体上“测试 VariableStorageComponent”的 value_string 字段
-- @param entity_id 玩家实体 ID
-- @return 成功返回 true，失败返回 false
function set_test_variable_storage_modified(entity_id)
    if not entity_id or not EntityGetIsAlive(entity_id) then
        GamePrint("错误：实体无效或不存在")
        return false
    end

    -- 手动遍历所有 VariableStorageComponent
    local comps = EntityGetComponent(entity_id, "VariableStorageComponent") or {}
    for _, comp in ipairs(comps) do
        if ComponentGetValue2(comp, "name") == "epic_kill_effects_test" then
            ComponentSetValue2(comp, "value_string", "测试组件被修改")
            GamePrint("已成功修改测试组件的 value_string")
            return true
        end
    end

    GamePrint("未找到测试组件，修改失败")
    return false
end

-- 给玩家添加测试VariableStorageComponent的函数
function add_test_variable_storage(entity_id)
    local player_entity = entity_id
    if not player_entity then
        GamePrint("错误：找不到玩家实体")
        return false
    end
    
    -- 检查是否已存在测试组件
    local existing_comp = find_test_variable_storage(entity_id)
    if existing_comp then
        -- GamePrint("测试组件已存在，跳过添加")
        return true
    end
    
    -- 添加新的VariableStorageComponent
    local comp = EntityAddComponent2(player_entity, "VariableStorageComponent",
    {
        name = "epic_kill_effects_test",
		value_string = "这是一个测试"
    })
    
    if comp then
        GamePrint("成功添加测试组件到玩家实体: " .. tostring(player_entity))
        return true
    else
        GamePrint("添加测试组件失败")
        return false
    end
end