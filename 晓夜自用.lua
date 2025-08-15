-- 定义旋转速度
local ROTATION_SPEED = 720  -- 旋转速度，单位：度/秒

-- 定义需要发送的消息
local welcome_messages = {
    "你好我的中国朋友",
    "我来自日本",
    "I come from Japan",
    "My name is Sakurajima Hatsuyuki",
}

local delay_time = 20

-- 消息发送控制变量
local message_sent = false  -- 是否已发送过欢迎消息
local message_index = 1     -- 当前要发送的消息索引
local next_send_time = 0    -- 下一条消息的发送时间

-- 定义按键的虚拟键码
local KEYS = {
    space = 0x20,
    page_up = 0x21,
    page_down = 0x22,
    z = 0x5A,
    c = 0x43,
    v = 0x56,  -- V键的虚拟键码
}

local DEFAULT_YAW = 180
local rotation_speed = 0

-- 旋转状态控制变量
local rotate_left = false  -- Z键控制的左旋状态
local rotate_right = false -- C键控制的右旋状态

-- 击杀播报开关状态（默认关闭）
local kill_message_enabled = false
local v_last_state = false  -- 用于V键状态检测

-- 旋转角度控制变量
local current_yaw = DEFAULT_YAW
local last_update_time = os.clock()

-- 广告开关状态，默认关闭
local page_up_enabled = false
local page_down_enabled = false

-- 用于防止重复触发的状态记录
local page_up_last_state = false
local page_down_last_state = false
local z_last_state = false
local c_last_state = false

-- 初始化字体
local font = render.setup_font("C:\\Windows\\Fonts\\msyh.ttc", 30, 500)

-- 定义 GetAsyncKeyState 函数，用于检测按键状态
ffi.cdef [[
    unsigned short GetAsyncKeyState(int vKey);
]]

-- 检测按键是否被按下
local function is_key_pressed(virtualKey)
    return bit.band(ffi.C.GetAsyncKeyState(virtualKey), 32768) == 32768
end

-- 初始化反自瞄相关设置
menu.ragebot_anti_aim = false
menu.ragebot_anti_aim_pitch = 2
menu.ragebot_anti_aim_base_yaw_offset = DEFAULT_YAW

-- 击杀播报内容
local kill_say = {
    "nixware.cc | 您已被尊贵的 nixware 用户击杀",
    "我曾经带领车队一天死了 100 个号",
    "QQ群: 1046853514 | 加入我们",
    "我开挂了, 我承认错误",
    "请别和我一样使用外挂",
    -- 其他击杀播报内容...
}

local kill = 0

engine.execute_client_cmd("unbind z")
engine.execute_client_cmd("unbind c")
engine.execute_client_cmd("unbind v")  -- 解除V键默认绑定

-- 击杀播报回调，添加开关控制
register_callback("player_death", function(event)
    -- 只有在击杀播报开启时才发送消息
    if kill_message_enabled and event:get_pawn("attacker") == entitylist.get_local_player_pawn() then
        engine.execute_client_cmd("say " .. kill_say[kill % #kill_say + 1])
        kill = kill + 1
    end
end)

-- 更新旋转角度的函数
local function update_rotation()
    local current_time = os.clock()
    local delta_time = current_time - last_update_time
    last_update_time = current_time
    
    -- 根据速度和时间差计算角度变化
    current_yaw = current_yaw + rotation_speed * delta_time
    
    -- 确保角度在-180到180之间循环
    if current_yaw > 180 then
        current_yaw = -180  -- 超过180度时回到-180度
    elseif current_yaw < -180 then
        current_yaw = 180   -- 低于-180度时回到180度
    end
    
    return current_yaw
end

-- 主循环回调
register_callback("paint", function()
    local local_player = entitylist.get_local_player_pawn()
    local current_time = os.clock()  -- 使用os.clock()获取时间
    local screen_size = render.screen_size()
    
    -- 检测Z键状态切换（互斥开关）
    local is_z_pressed = is_key_pressed(KEYS.z)
    if is_z_pressed and not z_last_state then
        rotate_left = not rotate_left
        -- 如果开启左旋，则关闭右旋
        if rotate_left then
            rotate_right = false
        end
    end
    z_last_state = is_z_pressed
    
    -- 检测C键状态切换（互斥开关）
    local is_c_pressed = is_key_pressed(KEYS.c)
    if is_c_pressed and not c_last_state then
        rotate_right = not rotate_right
        -- 如果开启右旋，则关闭左旋
        if rotate_right then
            rotate_left = false
        end
    end
    c_last_state = is_c_pressed

    -- 检测V键状态切换（击杀播报开关）
    local is_v_pressed = is_key_pressed(KEYS.v)
    if is_v_pressed and not v_last_state then
        kill_message_enabled = not kill_message_enabled
        -- 开启击杀播报时关闭其他广告
        if kill_message_enabled then
            page_up_enabled = false
            page_down_enabled = false
        end
    end
    v_last_state = is_v_pressed

    -- 根据开关状态设置旋转速度（使用全局变量ROTATION_SPEED）
    if rotate_left then
        rotation_speed = ROTATION_SPEED  -- 左旋
    elseif rotate_right then
        rotation_speed = -ROTATION_SPEED   -- 右旋
    else
        rotation_speed = 0                -- 停止旋转
        current_yaw = DEFAULT_YAW         -- 恢复默认偏移
    end
    
    -- 检测Page Up键状态切换（群广告）
    local is_page_up_pressed = is_key_pressed(KEYS.page_up)
    if is_page_up_pressed and not page_up_last_state then
        page_up_enabled = not page_up_enabled
        -- 开启群广告时关闭其他广告
        if page_up_enabled then
            page_down_enabled = false
            kill_message_enabled = false
        end
    end
    page_up_last_state = is_page_up_pressed

    -- 检测Page Down键状态切换（卡网广告）
    local is_page_down_pressed = is_key_pressed(KEYS.page_down)
    if is_page_down_pressed and not page_down_last_state then
        page_down_enabled = not page_down_enabled
        -- 开启卡网广告时关闭其他广告
        if page_down_enabled then
            page_up_enabled = false
            kill_message_enabled = false
        end
    end
    page_down_last_state = is_page_down_pressed

    -- 渲染旋转控制提示文字及状态
    local is_rotating = rotate_left or rotate_right
    local rotation_color = is_rotating and color_t(0, 1, 0, 1) or color_t(1, 1, 1, 1)
    local rotation_text = "[Z/C] 旋转"
    local rotation_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 100)
    render.text(rotation_text, font, rotation_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    render.text(rotation_text, font, rotation_text_position, rotation_color, 18)

    -- 渲染V键击杀播报状态（位于旋转和群广告中间）
    local kill_message_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 120)
    local kill_message_color = kill_message_enabled and color_t(0, 1, 0, 1) or color_t(1, 1, 1, 1)
    render.text("[V] 击杀播报", font, kill_message_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    render.text("[V] 击杀播报", font, kill_message_text_position, kill_message_color, 18)

    -- 渲染Page Up键状态（群广告）
    local page_up_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 140)
    local page_up_color = page_up_enabled and color_t(0, 1, 0, 1) or color_t(1, 1, 1, 1)
    render.text("[PgUp] 群广告", font, page_up_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    render.text("[PgUp] 群广告", font, page_up_text_position, page_up_color, 18)

    -- 渲染Page Down键状态（卡网广告）
    local page_down_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 160)
    local page_down_color = page_down_enabled and color_t(0, 1, 0, 1) or color_t(1, 1, 1, 1)
    render.text("[PgDn] 卡网广告", font, page_down_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    render.text("[PgDn] 卡网广告", font, page_down_text_position, page_down_color, 18)

    -- 当Page Up开关开启时发送群广告
    if page_up_enabled then
        engine.execute_client_cmd("say QQ群: 1046853514 | 加入我们")
    end

    -- 当Page Down开关开启时发送网址
    if page_down_enabled then
        engine.execute_client_cmd("say 网址: cxs.hvh.asia | 续费外挂")
    end
    
    -- 如果本地玩家不存在，则重置状态
    if not local_player then
        menu.ragebot_anti_aim = false
        kill = 0
        message_sent = false
        message_index = 1
        rotate_left = false
        rotate_right = false
        page_up_enabled = false
        page_down_enabled = false
        kill_message_enabled = false  -- 本地玩家不存在时关闭击杀播报
    else
        -- 处理欢迎消息发送
        if not message_sent then
            if message_index == 1 then
                next_send_time = current_time + delay_time
                message_index = message_index + 1
            elseif current_time >= next_send_time then
                engine.execute_client_cmd("say " .. welcome_messages[message_index - 1])
                
                if (message_index - 1) < #welcome_messages then
                    next_send_time = current_time + 3
                    message_index = message_index + 1
                else
                    message_sent = true
                end
            end
        end
        
        -- 空格按住时开启AA
        local is_space_pressed = is_key_pressed(KEYS.space)
        menu.ragebot_anti_aim = is_space_pressed
        
        if is_space_pressed then
            menu.ragebot_anti_aim_base_yaw_offset = update_rotation()
            menu.ragebot_anti_aim_pitch = 2
        else
            current_yaw = DEFAULT_YAW
            menu.ragebot_anti_aim_base_yaw_offset = DEFAULT_YAW
        end
    end
end)

-- 脚本卸载时重置设置
register_callback("unload", function()
    menu.ragebot_anti_aim_base_yaw_offset = DEFAULT_YAW
    menu.ragebot_anti_aim_pitch = 2
    menu.ragebot_anti_aim = false
end)
