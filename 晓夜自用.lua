-- 定义需要发送的消息
local welcome_messages = {
    "你好我的中国朋友",
    "我来自日本",
    "I come from JP",
    "My name is Sakurajima Hatsuyuki"
}

-- 消息发送控制变量
local message_sent = false  -- 是否已发送过欢迎消息
local message_index = 1     -- 当前要发送的消息索引
local next_send_time = 0    -- 下一条消息的发送时间

-- 定义按键的虚拟键码
local KEYS = {
    space = 0x20  -- 空格键
}

-- 定义默认偏移角度
local DEFAULT_YAW = 180

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
    "memesense.gg | 您已被尊贵的 memesense 用户击杀",
    "我曾经带领车队一天死了 100 个号",
    "组队群1046853514 | 加入我们",
    "我开挂了, 我承认错误",
    "请别和我一样使用外挂",
    -- 省略部分击杀消息...
}

local kill = 0

-- 击杀播报回调
register_callback("player_death", function(event)
    if event:get_pawn("attacker") == entitylist.get_local_player_pawn() then
        engine.execute_client_cmd("say " .. kill_say[kill % #kill_say + 1])
        kill = kill + 1
    end
end)

-- 主循环回调
register_callback("paint", function()
    local local_player = entitylist.get_local_player_pawn()
    local current_time = os.clock()  -- 使用os.clock()获取时间
    
    -- 如果本地玩家不存在，则重置状态
    if not local_player then
        menu.ragebot_anti_aim = false
        kill = 0
        message_sent = false
        message_index = 1
    else
        -- 处理欢迎消息发送
        if not message_sent then
            -- 首次检测到玩家，设置15秒后发送第一条消息
            if message_index == 1 then
                next_send_time = current_time + 15
                message_index = message_index + 1
            -- 检查是否到了发送时间
            elseif current_time >= next_send_time then
                -- 发送当前消息（使用message_index - 1作为索引）
                engine.execute_client_cmd("say " .. welcome_messages[message_index - 1])
                
                -- 检查是否还有下一条消息（修复判断条件）
                if (message_index - 1) < #welcome_messages then
                    -- 设置下一条消息的发送时间（3秒后）
                    next_send_time = current_time + 3
                    message_index = message_index + 1
                else
                    -- 所有消息发送完毕
                    message_sent = true
                end
            end
        end
        
        -- 空格按住时开启AA，固定为180度
        local is_space_pressed = is_key_pressed(KEYS["space"])
        menu.ragebot_anti_aim = is_space_pressed
        
        if is_space_pressed then
            menu.ragebot_anti_aim_base_yaw_offset = DEFAULT_YAW
            menu.ragebot_anti_aim_pitch = 2
        end
    end
end)

-- 脚本卸载时重置设置
register_callback("unload", function()
    menu.ragebot_anti_aim_base_yaw_offset = DEFAULT_YAW
    menu.ragebot_anti_aim_pitch = 2
    menu.ragebot_anti_aim = false
end)
