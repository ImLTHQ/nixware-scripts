-- 定义虚拟键码（改为Page Up和Page Down）
local KEY_PAGE_UP = 0x21    -- Page Up键
local KEY_PAGE_DOWN = 0x22  -- Page Down键

-- 开关状态，默认关闭
local page_up_enabled = false
local page_down_enabled = false

-- 用于防止重复触发的状态记录
local page_up_last_state = false
local page_down_last_state = false

-- 初始化字体（使用支持更多符号的黑体）
local font = render.setup_font("C:\\Windows\\Fonts\\simhei.ttf", 20, 500)

-- 声明按键检测函数
ffi.cdef [[
    unsigned short GetAsyncKeyState(int vKey);
]]

local function is_key_pressed(virtualKey)
    return bit.band(ffi.C.GetAsyncKeyState(virtualKey), 32768) == 32768
end

register_callback("paint", function()
    local screen_size = render.screen_size()
    
    -- 检测Page Up键状态切换
    local is_page_up_pressed = is_key_pressed(KEY_PAGE_UP)
    if is_page_up_pressed and not page_up_last_state then
        page_up_enabled = not page_up_enabled
        
        -- 当Page Up功能开启时，自动关闭Page Down功能（防止冲突）
        if page_up_enabled then
            page_down_enabled = false
        end
    end
    page_up_last_state = is_page_up_pressed

    -- 检测Page Down键状态切换
    local is_page_down_pressed = is_key_pressed(KEY_PAGE_DOWN)
    if is_page_down_pressed and not page_down_last_state then
        page_down_enabled = not page_down_enabled
        
        -- 当Page Down功能开启时，自动关闭Page Up功能（防止冲突）
        if page_down_enabled then
            page_up_enabled = false
        end
    end
    page_down_last_state = is_page_down_pressed

    -- 渲染Page Up键状态
    local page_up_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 80)
    local page_up_color = page_up_enabled and color_t(0, 1, 0, 1) or color_t(1, 0, 0, 1)
    -- 绘制带阴影的状态指示文字
    render.text("[PgUp] 群广告", font, page_up_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    render.text("[PgUp] 群广告", font, page_up_text_position, page_up_color, 18)

    -- 渲染Page Down键状态
    local page_down_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 110)
    local page_down_color = page_down_enabled and color_t(0, 1, 0, 1) or color_t(1, 0, 0, 1)
    -- 绘制带阴影的状态指示文字
    render.text("[PgDn] 卡网广告", font, page_down_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    render.text("[PgDn] 卡网广告", font, page_down_text_position, page_down_color, 18)

    -- 当Page Up开关开启时发送群广告
    if page_up_enabled then
        engine.execute_client_cmd("say 开挂组队群: 1046853514 | 加入我们")
    end

    -- 当Page Down开关开启时发送网址
    if page_down_enabled then
        engine.execute_client_cmd("say 网址: cxs.hvh.asia | 续费外挂")
    end
end)
