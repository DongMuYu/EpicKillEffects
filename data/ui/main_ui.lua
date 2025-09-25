local gui = GuiCreate()

-- GUI更新函数
function Gui_Update()
    -- 获取屏幕尺寸
    local screen_w, screen_h = GuiGetScreenDimensions(gui)

    -- 确保GUI上下文存在（防止意外销毁）
    if not gui then gui = GuiCreate() end

    -- 开始新的一帧GUI渲染
    GuiStartFrame(gui)

    

end

