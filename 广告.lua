-- 定义虚拟键码
local KEY_C = 0x43  -- C键
local KEY_V = 0x56  -- V键

-- 开关状态，默认关闭
local c_enabled = false
local v_enabled = false

-- 用于防止重复触发的状态记录
local c_key_last_state = false
local v_key_last_state = false

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
    
    -- 检测C键状态切换
    local is_c_pressed = is_key_pressed(KEY_C)
    if is_c_pressed and not c_key_last_state then
        c_enabled = not c_enabled
        
        -- 当C开启时，自动关闭V
        if c_enabled then
            v_enabled = false
        end
    end
    c_key_last_state = is_c_pressed

    -- 检测V键状态切换
    local is_v_pressed = is_key_pressed(KEY_V)
    if is_v_pressed and not v_key_last_state then
        v_enabled = not v_enabled
        
        -- 当V开启时，自动关闭C
        if v_enabled then
            c_enabled = false
        end
    end
    v_key_last_state = is_v_pressed

    -- 渲染C键状态（仅颜色变化）
    local c_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 80)
    local c_color = c_enabled and color_t(0, 1, 0, 1) or color_t(1, 0, 0, 1)
    -- 绘制带阴影的状态指示文字
    render.text("[C] 群广告", font, c_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    render.text("[C] 群广告", font, c_text_position, c_color, 18)

    -- 渲染V键状态（仅颜色变化）
    local v_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 110)
    local v_color = v_enabled and color_t(0, 1, 0, 1) or color_t(1, 0, 0, 1)
    -- 绘制带阴影的状态指示文字
    render.text("[V] 卡网广告", font, v_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    render.text("[V] 卡网广告", font, v_text_position, v_color, 18)

    -- 当C键开关开启时发送群广告
    if c_enabled then
        engine.execute_client_cmd("say 开挂组队群: 1046853514 | 加入我们")
    end

    -- 当V键开关开启时发送网址
    if v_enabled then
        engine.execute_client_cmd("say 网址: cxs.hvh.asia | 续费外挂")
    end
end)
