-- 定义按键的虚拟键码
local KEYS = {
    a = 0x41,
    d = 0x44,
    space = 0x20  -- 空格键
}

-- 定义状态值，用于设置偏移量
local OFFSET = {
    a = -90,       -- A 键对应的偏移量
    d = 90,        -- D 键对应的偏移量
    default = 180, -- 默认偏移量
}

-- 当前偏移量，初始为默认值
local current_yaw = OFFSET["default"]

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
menu.ragebot_anti_aim_pitch = 2  -- 默认设置为2

-- 用于记录 A 和 D 键松开的时间
local key_release_time = {
    a = nil,
    d = nil
}

-- 用于记录 A 和 D 同时按下的时间
local ad_press_time = nil

-- 定义切换为默认角度的延迟时间（秒）
local DEFAULT_DELAY = 0.5

-- 击杀播报内容
local kill_say = {
    "memesense.gg | 您已被尊贵的 memesense 用户击杀",
    "我曾经带领车队一天死了 100 个号",
    "交流群830445769 | 加入我们",
    "我开挂了, 我承认错误",
    "请别和我一样使用外挂",
    "与其和我斗气, 不如闭目养神, 或者静心品茗",
    "VAC 不会放过任何一个作弊者, 本账号注定会被封禁",
    "如果无法忍受官匹外挂太多, 各大对战平台则是您的不二之选",
    "请不要骂人, 文明互联网, 骂人不解决问题",
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

local death_say = {
    "您把我哄睡着了",
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
    -- 如果本地玩家不存在，则禁用反自瞄功能并退出
    if not entitylist.get_local_player_pawn() then
        menu.ragebot_anti_aim = false
        return
    end

    -- 空格按住时开启AA并设置为2
    menu.ragebot_anti_aim = is_key_pressed(KEYS["space"])
    if menu.ragebot_anti_aim then
        menu.ragebot_anti_aim_pitch = 2
    end

    -- 检测 A 和 D 键是否被按下，并设置对应的偏移量
    local is_a_pressed = is_key_pressed(KEYS["a"])
    local is_d_pressed = is_key_pressed(KEYS["d"])
    local current_time = os.clock()

    if is_a_pressed and is_d_pressed then
        -- A和D同时按下时的处理
        if not ad_press_time then
            ad_press_time = current_time
        end
        if current_time - ad_press_time >= DEFAULT_DELAY then
            current_yaw = OFFSET["default"]
        end
        key_release_time["a"] = nil
        key_release_time["d"] = nil
    elseif is_a_pressed then
        -- A键单独按下
        current_yaw = OFFSET["a"]
        key_release_time["a"] = nil
        ad_press_time = nil
    elseif is_d_pressed then
        -- D键单独按下
        current_yaw = OFFSET["d"]
        key_release_time["d"] = nil
        ad_press_time = nil
    else
        -- 按键松开后的延迟处理
        if not is_a_pressed and not key_release_time["a"] then
            key_release_time["a"] = current_time
        end
        if not is_d_pressed and not key_release_time["d"] then
            key_release_time["d"] = current_time
        end

        if (key_release_time["a"] and current_time - key_release_time["a"] >= DEFAULT_DELAY) and
           (key_release_time["d"] and current_time - key_release_time["d"] >= DEFAULT_DELAY) then
            current_yaw = OFFSET["default"]
        end
        ad_press_time = nil
    end

    -- 设置反自瞄基础偏移量
    menu.ragebot_anti_aim_base_yaw_offset = current_yaw
end)

-- 脚本卸载时重置设置
register_callback("unload", function()
    menu.ragebot_anti_aim_base_yaw_offset = OFFSET["default"]
    menu.ragebot_anti_aim_pitch = 2
    menu.ragebot_anti_aim = false
end)
    