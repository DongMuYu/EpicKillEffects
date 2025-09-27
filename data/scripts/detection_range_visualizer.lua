-- 检测范围可视化脚本
-- 这个脚本用于在检测范围的边界上生成粒子，形成圆环效果

-- 存储实体ID
local entity_id = GetUpdatedEntityID()
-- 获取实体的位置
local x, y = EntityGetTransform(entity_id)

-- 打印实体ID和位置
-- GamePrint("detection_range_visualizer.lua 实体ID: " .. tostring(entity_id) .. " 位置: " .. tostring(x) .. ", " .. tostring(y))

-- 检查粒子是否已经创建过
local particles_created = 0
local var_comps = EntityGetComponent(entity_id, "VariableStorageComponent") or {}
for _, comp in ipairs(var_comps) do
    local name = ComponentGetValue2(comp, "name")
    if name == "particles_created" then
        particles_created = ComponentGetValue2(comp, "value_int")
        break
    end
end

-- 如果粒子已经创建过，则不再创建
if particles_created == 1 then
    return
end

-- 检测半径为60像素
local detection_radius = 60

-- 在圆周上等间距放置粒子
local particle_count = 64  -- 增加粒子数量使效果更连续

for i = 1, particle_count do
    -- 计算粒子在圆周上的位置
    local angle = (i / particle_count) * math.pi * 2
    local px = x + math.cos(angle) * detection_radius
    local py = y + math.sin(angle) * detection_radius
    
    -- 创建静态粒子
    GameCreateCosmeticParticle(
        "spark_a4",        -- 材质
        px, py,         -- 位置
        1,              -- 粒子数量
        0, 0,           -- 速度（设为0让粒子静止）
        0xFF36D517,     -- 颜色（绿色）
        4, 4,         -- 生命周期（帧数）
        true,           -- 强制创建
        true,           -- 在前景绘制
        false,          -- 不与网格碰撞
        false,          -- 不随机化速度
        0, 0            -- 无重力
    )
end

-- 标记粒子已创建
for _, comp in ipairs(var_comps) do
    local name = ComponentGetValue2(comp, "name")
    if name == "particles_created" then
        ComponentSetValue2(comp, "value_int", 1)
        break
    end
end