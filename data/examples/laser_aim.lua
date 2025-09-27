-- 引入Noita游戏引擎的实用工具库，包含各种辅助函数
dofile_once("data/scripts/lib/utilities.lua")
-- 引入与法杖/枪械相关的程序化生成工具库，用于处理武器相关的逻辑
dofile_once("data/scripts/gun/procedural/gun_action_utils.lua")

-- 获取当前正在更新的实体ID，这个函数通常用于获取当前脚本附加到的实体
local entity_id = GetUpdatedEntityID()
-- 获取当前实体的根实体ID，对于玩家控制的实体，这通常是玩家实体
local player_id = EntityGetRootEntity( entity_id )

-- 查找玩家当前持有的法杖ID，这个函数会返回玩家手中法杖的实体ID
local wand_id = find_the_wand_held( player_id )

-- 检查玩家是否持有法杖（wand_id不为nil且不是空实体）
if ( wand_id ~= nil ) and ( wand_id ~= NULL_ENTITY ) then
	-- 获取法杖的位置坐标(x,y)和朝向角度(dir)
	local x,y,dir = EntityGetTransform( wand_id )
	
	-- 获取当前实体的激光发射器组件，包括被禁用的组件
	-- LaserEmitterComponent是控制激光发射的组件
	local comp = EntityGetFirstComponentIncludingDisabled( entity_id, "LaserEmitterComponent" )
	
	-- 如果找到了激光发射器组件
	if ( comp ~= nil ) then
		-- 设置激光发射器为发射状态，is_emitting为true表示激光正在发射
		ComponentSetValue2( comp, "is_emitting", true )
	end
	
	-- 计算激光发射器的偏移位置
	-- ox = 法杖x坐标 + cos(0 - 法杖朝向角度) * 6
	-- oy = 法杖y坐标 - sin(0 - 法杖朝向角度) * 6
	-- 这个计算使激光发射器位于法杖前方一定距离处
	local ox = x + math.cos( 0 - dir ) * 6
	local oy = y - math.sin( 0 - dir ) * 6
	
	-- 设置当前实体的位置和朝向
	-- ox, oy + 0.5: 计算出的偏移位置，y轴额外增加0.5单位
	-- dir: 保持与法杖相同的朝向
	EntitySetTransform( entity_id, ox, oy + 0.5, dir )
else
	-- 如果玩家没有持有法杖，获取当前实体的激光发射器组件
	local comp = EntityGetFirstComponentIncludingDisabled( entity_id, "LaserEmitterComponent" )
	
	-- 如果找到了激光发射器组件
	if ( comp ~= nil ) then
		-- 设置激光发射器为关闭状态，is_emitting为false表示激光停止发射
		ComponentSetValue2( comp, "is_emitting", false )
	end
end