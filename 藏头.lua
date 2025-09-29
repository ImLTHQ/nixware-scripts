local STATES = {
    z = 90,
    c = -90,

    default = 180
}

local ENABLE_INDICATOR = true
local ACTIVE_COLOR = color_t(0, 1, 1, 0.5)
local INACTIVE_COLOR = color_t(1, 1, 1, 0.5)
local INDICATOR_DISTANCE = 75

engine.execute_client_cmd("unbind z")
engine.execute_client_cmd("unbind c")

ffi.cdef [[
    unsigned short GetAsyncKeyState(int vKey);
]]

local function is_key_pressed(virtualKey)
    return bit.band(ffi.C.GetAsyncKeyState(virtualKey), 32768) == 32768
end

local keys = {
    c = 0x43,
    z = 0x5a,
}

local held_keys_cache = {}
local current_yaw = STATES["default"]

register_callback("paint", function()
    for k, v in pairs(STATES) do
        if k == "default" then
            goto continue
        end

        local is_key_held = is_key_pressed(keys[k] or error("Key doesn't exist: " .. k))

        if (not held_keys_cache[k]) and is_key_held then
            if current_yaw == v then
                current_yaw = STATES["default"]
            else
                current_yaw = v
            end
        end

        held_keys_cache[k] = is_key_held

        ::continue::
    end

    if ENABLE_INDICATOR then
        if not entitylist.get_local_player_pawn() then return end

        local screen_center = vec2_t(
            render.screen_size().x / 2,
            render.screen_size().y / 2
        )

        local manual =
            (current_yaw >= 45 and current_yaw <= 145) and 2 or
            (current_yaw <= -75 and current_yaw >= -145) and 1 or
            0

        render.filled_polygon(
            {
                vec2_t(screen_center.x - (INDICATOR_DISTANCE + 15), screen_center.y),
                vec2_t(screen_center.x - (INDICATOR_DISTANCE + 2), screen_center.y - 9),
                vec2_t(screen_center.x - (INDICATOR_DISTANCE + 2), screen_center.y + 9)
            },
            manual == 2 and ACTIVE_COLOR or INACTIVE_COLOR
        )

        render.filled_polygon(
            {
                vec2_t(screen_center.x + (INDICATOR_DISTANCE + 15), screen_center.y),
                vec2_t(screen_center.x + (INDICATOR_DISTANCE + 2), screen_center.y - 9),
                vec2_t(screen_center.x + (INDICATOR_DISTANCE + 2), screen_center.y + 9)
            },
            manual == 1 and ACTIVE_COLOR or INACTIVE_COLOR
        )
    end

    menu.ragebot_anti_aim_base_yaw_offset = current_yaw
end)

register_callback("unload", function()
    current_yaw = STATES["default"]
end)
