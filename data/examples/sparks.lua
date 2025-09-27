-- 加载游戏工具库，提供各种实用函数
dofile_once("data/scripts/lib/utilities.lua")

-- 获取当前实体的ID
local entity_id    = GetUpdatedEntityID()
-- 获取当前实体的位置坐标
local pos_x, pos_y = EntityGetTransform( entity_id )

-- 设置随机种子，使用当前帧数、实体位置和实体ID的组合，确保每次生成的火花效果不同
SetRandomSeed( GameGetFrameNum(), pos_x + pos_y + entity_id )

-- 随机生成8到12个火花
local how_many = Random(8,12)
-- 计算每个火花之间的角度间隔（2π除以火花数量）
local angle_inc = (( 2 * 3.14159 ) / how_many)
-- 初始角度设为0
local theta = 0
-- 随机生成火花的飞行距离，范围在350到550之间
local length = Random(350,550)

-- 循环生成指定数量的火花
for i=1,how_many do
	-- 为每个火花添加随机角度偏移，使效果更自然
	local theta_rand = theta + Random(-10,10) * 0.1
	-- 计算火花在X轴方向的速度（使用余弦函数）
	local vel_x = math.cos( theta_rand - 0.31415 ) * length
	-- 计算火花在Y轴方向的速度（使用正弦函数）
	local vel_y = math.sin( theta_rand - 0.31415 ) * length
	-- 更新角度，为下一个火花做准备
	theta = theta + angle_inc

	-- 发射火花粒子，使用预定义的火花粒子效果
	shoot_projectile( entity_id, "data/entities/particles/particle_sparks.xml", pos_x, pos_y, vel_x, vel_y )
end
