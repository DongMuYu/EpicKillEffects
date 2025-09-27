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

-- 初始化玩家速度变量，默认为0
local vx,vy = 0,0
-- 获取玩家的速度组件，这个组件存储了玩家的移动速度信息
local stuff = EntityGetFirstComponent( player_id, "VelocityComponent" )
-- 如果找到了速度组件
if ( stuff ~= nil ) then
	-- 从速度组件中提取玩家的x轴和y轴速度值
	-- mVelocity是速度组件中存储速度向量的属性
	vx,vy = ComponentGetValue2( stuff, "mVelocity" )
end

-- 获取当前实体的所有子实体
local c = EntityGetAllChildren( entity_id )
local laser
-- 如果存在子实体
if ( c ~= nil ) then
	-- 遍历所有子实体
	for i,v in ipairs( c ) do
		-- 检查子实体是否带有"personal_laser"标签
		-- 这个标签用于标识个人激光发射器
		if EntityHasTag( v, "personal_laser" ) then
			-- 如果找到了带有该标签的子实体，将其存储在laser变量中
			laser = v
			break -- 找到后立即退出循环，提高效率
		end
	end
end

-- 检查玩家是否持有法杖（wand_id不为nil且不是空实体）
if ( wand_id ~= nil ) and ( wand_id ~= NULL_ENTITY ) then
	-- 获取法杖的位置坐标(x,y)和朝向角度(dir)
	local x,y,dir = EntityGetTransform( wand_id )
	
	-- 如果找到了激光发射器子实体
	if ( laser ~= nil ) then
		-- 获取激光发射器的激光发射器组件，包括被禁用的组件
		-- LaserEmitterComponent是控制激光发射的组件
		local comp = EntityGetFirstComponentIncludingDisabled( laser, "LaserEmitterComponent" )
		
		-- 如果找到了激光发射器组件
		if ( comp ~= nil ) then
			-- 设置激光发射器为发射状态，is_emitting为true表示激光正在发射
			ComponentSetValue2( comp, "is_emitting", true )
		end
	end
	
	-- 计算激光发射器的偏移位置
	-- ox = 法杖x坐标 + cos(0 - 法杖朝向角度) * 6 + 玩家x轴速度 * 1.5
	-- oy = 法杖y坐标 - sin(0 - 法杖朝向角度) * 6 + 玩家y轴速度 * 1.5
	-- 这个计算使激光发射器位于法杖前方一定距离处，并根据玩家速度进行微调
	local ox = x + math.cos( 0 - dir ) * 6 + vx * 1.5
	local oy = y - math.sin( 0 - dir ) * 6 + vy * 1.5
	
	-- 设置当前实体的位置和朝向
	-- ox, oy + 0.5: 计算出的偏移位置，y轴额外增加0.5单位
	-- dir: 保持与法杖相同的朝向
	EntitySetTransform( entity_id, ox, oy + 0.5, dir )
else
	-- 如果玩家没有持有法杖，检查是否存在激光发射器子实体
	if ( laser ~= nil ) then
		-- 获取激光发射器的激光发射器组件，包括被禁用的组件
		local comp = EntityGetFirstComponentIncludingDisabled( laser, "LaserEmitterComponent" )
		
		-- 如果找到了激光发射器组件
		if ( comp ~= nil ) then
			-- 设置激光发射器为关闭状态，is_emitting为false表示激光停止发射
			ComponentSetValue2( comp, "is_emitting", false )
		end
	end
end