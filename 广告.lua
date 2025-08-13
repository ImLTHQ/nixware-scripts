-- 定义虚拟键码（改为上下箭头）
local KEY_UP = 0x26   -- 上箭头键
local KEY_DOWN = 0x28 -- 下箭头键

-- 开关状态，默认关闭
local up_enabled = false
local down_enabled = false

-- 用于防止重复触发的状态记录
local up_key_last_state = false
local down_key_last_state = false

-- 初始化字体
local font = render.setup_font("C:\\Windows\\Fonts\\msyh.ttc", 20, 500)

-- 声明按键检测函数
ffi.cdef [[
    unsigned short GetAsyncKeyState(int vKey);
]]

local function is_key_pressed(virtualKey)
    return bit.band(ffi.C.GetAsyncKeyState(virtualKey), 32768) == 32768
end

register_callback("paint", function()
    local screen_size = render.screen_size()
    
    -- 检测上箭头键状态切换
    local is_up_pressed = is_key_pressed(KEY_UP)
    if is_up_pressed and not up_key_last_state then
        up_enabled = not up_enabled
        
        -- 当上箭头功能开启时，自动关闭下箭头功能（防止冲突）
        if up_enabled then
            down_enabled = false
        end
    end
    up_key_last_state = is_up_pressed

    -- 检测下箭头键状态切换
    local is_down_pressed = is_key_pressed(KEY_DOWN)
    if is_down_pressed and not down_key_last_state then
        down_enabled = not down_enabled
        
        -- 当下箭头功能开启时，自动关闭上箭头功能（防止冲突）
        if down_enabled then
            up_enabled = false
        end
    end
    down_key_last_state = is_down_pressed

    -- 渲染上箭头键状态
    local up_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 80)
    local up_color = up_enabled and color_t(0, 1, 0, 1) or color_t(1, 0, 0, 1)
    -- 绘制带阴影的状态指示文字
    render.text("[↑] 群广告", font, up_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    render.text("[↑] 群广告", font, up_text_position, up_color, 18)

    -- 渲染下箭头键状态
    local down_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 110)
    local down_color = down_enabled and color_t(0, 1, 0, 1) or color_t(1, 0, 0, 1)
    -- 绘制带阴影的状态指示文字
    render.text("[↓] 卡网广告", font, down_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    render.text("[↓] 卡网广告", font, down_text_position, down_color, 18)

    -- 当上箭头开关开启时发送群广告
    if up_enabled then
        engine.execute_client_cmd("say 开挂组队群: 1046853514 | 加入我们")
    end

    -- 当下箭头开关开启时发送网址
    if down_enabled then
        engine.execute_client_cmd("say 网址: cxs.hvh.asia | 续费外挂")
    end
end)
