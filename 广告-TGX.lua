-- 定义V键虚拟键码
local KEY_V = 0x56
-- 开关状态，默认关闭
local say_enabled = false
-- 用于防止重复触发的状态记录
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
    -- 检测V键状态切换
    local is_v_pressed = is_key_pressed(KEY_V)
    if is_v_pressed and not v_key_last_state then
        say_enabled = not say_enabled
    end
    v_key_last_state = is_v_pressed

    -- 渲染开关状态
    local screen_size = render.screen_size()
    local status_text = say_enabled and "[V] 发送广告 开启" or "[V] 发送广告 关闭"
    local text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 80)
    
    -- 绘制文字阴影
    render.text(status_text, font, text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    -- 绘制文字本体
    render.text(status_text, font, text_position, color_t(1, 1, 1, 1), 18)

    -- 当开关开启时执行命令
    if say_enabled then
        engine.execute_client_cmd("say 组队群1046853514 | 加入我们")
    end
end)