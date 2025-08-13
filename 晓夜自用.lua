-- 定义需要发送的消息
local welcome_messages = {
    "你好我的中国朋友",
    "我来自日本",
    "I come from Japan",
    "My name is Sakurajima Hatsuyuki",
    "机长申请起飞",
}

local delay_time = 20

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
    "nixware.cc | 您已被尊贵的 nixware 用户击杀",
    "我曾经带领车队一天死了 100 个号",
    "组队群1046853514 | 加入我们",
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
    "放松心情, 态平和, 没必要为了一个孤儿挂逼生气",
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
            -- 首次检测到玩家，设置延迟发送第一条消息
            if message_index == 1 then
                next_send_time = current_time + delay_time
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
