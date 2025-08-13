-- 定义虚拟键码
local KEY_C = 0x43  -- C键
local KEY_V = 0x56  -- V键

-- 开关状态，默认关闭
local c_enabled = false  -- C键控制的群广告开关
local v_enabled = false  -- V键控制的网址开关

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
    
    -- 检测C键状态切换（群广告）
    local is_c_pressed = is_key_pressed(KEY_C)
    if is_c_pressed and not c_key_last_state then
        c_enabled = not c_enabled
    end
    c_key_last_state = is_c_pressed

    -- 检测V键状态切换（网址）
    local is_v_pressed = is_key_pressed(KEY_V)
    if is_v_pressed and not v_key_last_state then
        v_enabled = not v_enabled
    end
    v_key_last_state = is_v_pressed

    -- 渲染C键控制的状态（群广告）
    local c_status_text = c_enabled and "[C] 发送群 开启" or "[C] 群广告 关闭"
    local c_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 80)
    
    -- 绘制C键文字阴影
    render.text(c_status_text, font, c_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    -- 绘制C键文字本体（绿色开启，红色关闭）
    local c_color = c_enabled and color_t(0, 1, 0, 1) or color_t(1, 0, 0, 1)
    render.text(c_status_text, font, c_text_position, c_color, 18)

    -- 渲染V键控制的状态（网址）
    local v_status_text = v_enabled and "[V] 发送网址 开启" or "[V] 发送网址 关闭"
    local v_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 110)
    
    -- 绘制V键文字阴影
    render.text(v_status_text, font, v_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    -- 绘制V键文字本体（绿色开启，红色关闭）
    local v_color = v_enabled and color_t(0, 1, 0, 1) or color_t(1, 0, 0, 1)
    render.text(v_status_text, font, v_text_position, v_color, 18)

    -- 当C键开关开启时发送群广告
    if c_enabled then
        engine.execute_client_cmd("say 开挂组队群: 1046853514 | 加入我们")
    end

    -- 当V键开关开启时发送网址
    if v_enabled then
        engine.execute_client_cmd("say 网址: cxs.hvh.asia | 续费外挂")
    end
end)
