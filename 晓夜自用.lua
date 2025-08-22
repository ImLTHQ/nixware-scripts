-- 定义旋转速度
local ROTATION_SPEED = 1440  -- 旋转速度，单位：度/秒

-- 定义需要发送的消息（自我介绍）
local welcome_messages = {
    "你好我的中国朋友",
    "我来自日本",
    "I come from Japan",
    "My name is Sakurajima Hatsuyuki",
    "私の名前は桜島初雪です",
    "Я пришел из Японии",
    "Меня зовут Сакурайма Хатсуюки",
}

-- 消息发送控制变量
local message_index = 1     -- 当前要发送的消息索引
local next_send_time = 0    -- 下一条消息的发送时间
local sending_messages = false  -- 是否正在发送消息序列（自我介绍）

-- 定义按键的虚拟键码（使用字符串键名避免关键字冲突）
local KEYS = {
    space = 0x20,
    page_up = 0x21,
    page_down = 0x22,
    home = 0x24,              -- Home键的虚拟键码
    ["end"] = 0x23,           -- 用字符串形式定义end键，避免关键字冲突
    z = 0x5A,
    c = 0x43
}

local DEFAULT_YAW = 180
local rotation_speed = 0

-- 旋转状态控制变量
local rotate_left = false  -- Z键控制的左旋状态
local rotate_right = false -- C键控制的右旋状态

-- 击杀播报开关状态（默认关闭）
local kill_message_enabled = false
local home_last_state = false  -- 用于Home键状态检测

-- 旋转角度控制变量
local current_yaw = DEFAULT_YAW
local last_update_time = os.clock()

-- 广告相关设置
local page_up_enabled = false  -- 群广告开关
local page_down_enabled = false -- 卡网广告开关
local AD_INTERVAL = 3  -- 广告发送间隔(秒)，避免过于频繁
local next_page_up_time = 0  -- 下一次群广告发送时间
local next_page_down_time = 0  -- 下一次卡网广告发送时间
local page_up_message_index = 1  -- 群广告当前消息索引
local page_down_message_index = 1  -- 卡网广告当前消息索引

-- 群广告消息列表
local page_up_messages = {
    "QQ群: 1046853514 | 加入我们",
}

-- 卡网广告消息列表
local page_down_messages = {
    "网址: cxs.hvh.asia | 续费外挂",
    "网址: 长相思.我爱你 | 购买白/黑号",
}

-- 用于防止重复触发的状态记录
local page_up_last_state = false
local page_down_last_state = false
local z_last_state = false
local c_last_state = false
local end_last_state = false  -- 用于End键状态检测

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
menu.ragebot_anti_aim_base_yaw_modifier = 0
menu.ragebot_anti_aim_base_yaw_modifier_offset = 0

-- 击杀播报内容
local kill_say = {
    "nixware.cc | 您已被尊贵的 nixware 用户击杀",
    "我曾经带领车队一天死了 100 个号",
    "我开挂了, 我承认错误",
    "请别和我一样使用外挂",
    "与其和我斗气, 不如闭目养神, 或者静心品茗",
    "VAC 不会放过任何一个作弊者, 本账号注定会被封禁",
    "如果无法忍受官匹外挂太多, 各大对战平台则是您的不二之选",
    "请不要骂人, 文明互联网, 骂人不能解决问题",
    "开挂可耻, 开挂有罪, 希望您能原谅没有忍受外挂诱惑的我！",
    "您是否在电脑前坐太久了呢, 站立一分钟并深呼吸, 放松一下身心。",
    "如果您没心情继续游戏, 可以挂机, 并浏览一会网页",
    "一场游戏的输赢无关紧要, 没有必要为外挂而心情烦躁。",
    "作为挂逼, 我十分羡慕你们家庭美满",
    "而我这样的孤儿只能开着挂听着歌, 忍受其他玩家的谩骂",
    "放松心情, 心态平和, 没必要为了一个孤儿挂逼生气",
    "游戏只是娱乐，输赢不重要，重要的是心态。",
    "希望您能在游戏中找到更多的乐趣，而不是愤怒。",
    "游戏是为了放松心情，而不是让自己更烦躁。",
    "愿您每天都能保持微笑，享受生活的美好。",
    "希望您能在游戏中找到更多的朋友，而不是敌人。",
    "愿您的每一天都充满阳光与希望。",
    "游戏只是虚拟的世界，现实中更需要我们努力。",
    "愿您在游戏中找到属于自己的快乐。",
    "您知道吗？开挂的人其实内心都很孤独",
    "感谢您为我的游戏体验做出的牺牲",
    "这局结束后，建议您喝杯热茶放松一下",
    "您知道为什么我开挂吗？因为我太菜了",
    "其实我很佩服正常玩的玩家，至少你们有骨气",
    "游戏而已，何必认真？当然，开挂的我没资格说这话",
    "您知道最讽刺的是什么吗？开挂的我在教您人生道理",
    "您的牺牲不会白费，至少让我开心了一下",
    "您知道吗？每次击杀您这样的玩家，我都感到一丝愧疚",
    "但很快这丝愧疚就被外挂带来的快感淹没了",
    "愿天堂没有外挂，阿门",
    "您知道为什么我选择开挂吗？因为我在现实中太失败了",
    "游戏是我唯一的慰藉，即使是通过作弊的方式",
    "您是个好玩家，可惜遇到了坏玩家",
    "感谢您成为我游戏生涯中的一个小插曲",
}

local kill = 0

-- 解绑相关按键
engine.execute_client_cmd("unbind z")
engine.execute_client_cmd("unbind c")
engine.execute_client_cmd("unbind home")  -- 解除Home键默认绑定
engine.execute_client_cmd("unbind end")   -- 解除End键默认绑定
engine.execute_client_cmd("unbind pgup")  -- 解除PageUp键默认绑定
engine.execute_client_cmd("unbind pgdn")  -- 解除PageDown键默认绑定

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

-- 开始发送欢迎消息序列（自我介绍）
local function start_sending_welcome_messages()
    -- 无论之前是否在发送，都重新开始
    sending_messages = true
    message_index = 1
    next_send_time = os.clock()  -- 立即发送第一条消息
    
    -- 启动自我介绍时，关闭其他互斥功能
    page_up_enabled = false    -- 关闭群广告
    page_down_enabled = false  -- 关闭卡网广告
    kill_message_enabled = false -- 关闭击杀播报
end

-- 处理消息发送逻辑
local function process_message_sending(current_time)
    if sending_messages and current_time >= next_send_time then
        -- 发送当前消息
        engine.execute_client_cmd("say " .. welcome_messages[message_index])
        
        -- 准备下一条消息
        message_index = message_index + 1
        
        -- 如果所有消息都已发送，则结束序列
        if message_index > #welcome_messages then
            sending_messages = false
        else
            -- 否则设置3秒后发送下一条
            next_send_time = current_time + 3
        end
    end
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

    -- 检测Home键状态切换（击杀播报开关）
    local is_home_pressed = is_key_pressed(KEYS.home)
    if is_home_pressed and not home_last_state then
        kill_message_enabled = not kill_message_enabled
        -- 开启击杀播报时关闭其他互斥功能
        if kill_message_enabled then
            page_up_enabled = false
            page_down_enabled = false
            sending_messages = false  -- 关闭自我介绍
        end
    end
    home_last_state = is_home_pressed

    -- 检测End键状态（控制自我介绍发送：按一下开始或重新开始，再按一下停止）
    local is_end_pressed = is_key_pressed(KEYS["end"])  -- 使用字符串索引访问end键
    if is_end_pressed and not end_last_state then
        if sending_messages then
            -- 如果正在发送，则停止
            sending_messages = false
        else
            -- 如果没有发送，则开始发送
            start_sending_welcome_messages()
        end
    end
    end_last_state = is_end_pressed

    -- 处理消息发送
    process_message_sending(current_time)

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
        -- 开启群广告时关闭其他互斥功能
        if page_up_enabled then
            page_down_enabled = false
            kill_message_enabled = false
            sending_messages = false  -- 关闭自我介绍
            next_page_up_time = current_time  -- 立即发送第一条
            page_up_message_index = 1  -- 重置消息索引
        end
    end
    page_up_last_state = is_page_up_pressed

    -- 检测Page Down键状态切换（卡网广告）
    local is_page_down_pressed = is_key_pressed(KEYS.page_down)
    if is_page_down_pressed and not page_down_last_state then
        page_down_enabled = not page_down_enabled
        -- 开启卡网广告时关闭其他互斥功能
        if page_down_enabled then
            page_up_enabled = false
            kill_message_enabled = false
            sending_messages = false  -- 关闭自我介绍
            next_page_down_time = current_time  -- 立即发送第一条
            page_down_message_index = 1  -- 重置消息索引
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

    -- 渲染Home键击杀播报状态
    local kill_message_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 120)
    local kill_message_color = kill_message_enabled and color_t(0, 1, 0, 1) or color_t(1, 1, 1, 1)
    render.text("[Home] 击杀播报", font, kill_message_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    render.text("[Home] 击杀播报", font, kill_message_text_position, kill_message_color, 18)

    -- 渲染End键自我介绍
    local end_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 140)
    local end_color = sending_messages and color_t(0, 1, 0, 1) or color_t(1, 1, 1, 1)
    render.text("[End] 自我介绍", font, end_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    render.text("[End] 自我介绍", font, end_text_position, end_color, 18)

    -- 渲染Page Up键状态（群广告）
    local page_up_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 160)
    local page_up_color = page_up_enabled and color_t(0, 1, 0, 1) or color_t(1, 1, 1, 1)
    render.text("[PgUp] 群广告", font, page_up_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    render.text("[PgUp] 群广告", font, page_up_text_position, page_up_color, 18)

    -- 渲染Page Down键状态（卡网广告）
    local page_down_text_position = vec2_t(screen_size.x / 2 + 5, screen_size.y / 2 + 180)
    local page_down_color = page_down_enabled and color_t(0, 1, 0, 1) or color_t(1, 1, 1, 1)
    render.text("[PgDn] 卡网广告", font, page_down_text_position + vec2_t(1, 1), color_t(0, 0, 0, 1), 18)
    render.text("[PgDn] 卡网广告", font, page_down_text_position, page_down_color, 18)

    -- 当Page Up开关开启时发送群广告（带频率控制，多条消息轮流发送）
    if page_up_enabled and current_time >= next_page_up_time then
        -- 发送当前索引的消息
        engine.execute_client_cmd("say " .. page_up_messages[page_up_message_index])
        
        -- 更新下一条消息的索引，循环显示
        page_up_message_index = page_up_message_index + 1
        if page_up_message_index > #page_up_messages then
            page_up_message_index = 1
        end
        
        -- 设置下一次发送时间
        next_page_up_time = current_time + AD_INTERVAL
    end

    -- 当Page Down开关开启时发送卡网广告（带间隔控制，两条消息轮流发送）
    if page_down_enabled and current_time >= next_page_down_time then
        -- 发送当前索引的消息
        engine.execute_client_cmd("say " .. page_down_messages[page_down_message_index])
        
        -- 更新下一条消息的索引，循环显示
        page_down_message_index = page_down_message_index + 1
        if page_down_message_index > #page_down_messages then
            page_down_message_index = 1
        end
        
        -- 设置下一次发送时间
        next_page_down_time = current_time + AD_INTERVAL
    end
    
    -- 如果本地玩家不存在，则重置状态
    if not local_player then
        menu.ragebot_anti_aim = false
        kill = 0
        message_index = 1
        sending_messages = false
        rotate_left = false
        rotate_right = false
        page_up_enabled = false
        page_down_enabled = false
        kill_message_enabled = false  -- 本地玩家不存在时关闭击杀播报
    else
        -- 空格按住时开启AA
        local is_space_pressed = is_key_pressed(KEYS.space)
        menu.ragebot_anti_aim = is_space_pressed
        
        if is_space_pressed then
            menu.ragebot_anti_aim_base_yaw_offset = update_rotation()
            menu.ragebot_anti_aim_pitch = 2
            menu.ragebot_anti_aim_base_yaw_modifier = 0
            menu.ragebot_anti_aim_base_yaw_modifier_offset = 0
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
    menu.ragebot_anti_aim_base_yaw_modifier = 0
    menu.ragebot_anti_aim_base_yaw_modifier_offset = 0
    menu.ragebot_anti_aim = false
end)