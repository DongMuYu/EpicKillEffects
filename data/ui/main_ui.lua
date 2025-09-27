dofile_once("data/scripts/timer.lua")
dofile_once("data/scripts/counter.lua")
dofile_once("data/scripts/death_effects.lua")

local gui = GuiCreate()
local created_entities = {}

local function func()
    -- 获取玩家位置
    local player_entity = get_player_entity_id()
    if player_entity then
        return EntityGetTransform(player_entity)
    end
end


-- GUI更新函数
function Gui_Update()
    -- 获取屏幕尺寸
    local screen_w, screen_h = GuiGetScreenDimensions(gui)

    -- 确保GUI上下文存在（防止意外销毁）
    if not gui then gui = GuiCreate() end

    -- 开始新的一帧GUI渲染
    GuiStartFrame(gui)

    -- 创建测试按钮
    local clicked, right_clicked = GuiButton( gui, 736735, screen_w/2-50, screen_h/2-25, "创建实体" )
    if clicked then

            -- 在玩家位置创建一个新的实体
            local player_x, player_y = func()
            -- 备用测试 "data/entities/animals/boss_dragon.xml"
            local new_entity = EntityLoad("data/entities/kill_effect_a1.xml", player_x, player_y)
            if not new_entity then
                GamePrint("创建实体失败")
                return
            else
                -- 将新创建的实体添加到列表中
                table.insert(created_entities, new_entity)
                -- 打印实体的信息
                GamePrint("创建的实体ID: " .. tostring(new_entity) .. "，总计: " .. tostring(#created_entities))
            end
            
            GamePrint("左键点击：在玩家位置创建实体")
    end

    if right_clicked then
        -- 删除所有创建的实体
        if #created_entities > 0 then
            for i, entity in ipairs(created_entities) do
                if entity then
                    -- 将即将删除的实体的风力值拉满
                    local particle_emitter = EntityGetFirstComponent(entity, "ParticleEmitterComponent")
                    if particle_emitter then
                        ComponentSetValue2(particle_emitter, "emitted_material_name", "spark_a5")
                        ComponentSetValue2(particle_emitter, "airflow_force", 100.0)
                        -- ComponentSetValue2(particle_emitter, "airflow_time", 5.0)
                        ComponentSetValue2(particle_emitter, "airflow_scale", 10.0)
                    end
                    
                    -- EntityKill(entity)
                end
            end
            created_entities = {}
            GamePrint("右键点击：删除所有实体并停止粒子发射")
        else
            GamePrint("没有可删除的实体")
        end
    end
end

