io.stderr:write("Media Daemon is booting up...\n")

local music_players = {"spotify", "music", "mpd", "rhythmbox", "ncspot", "audacious", "cider", "elisa", "strawberry", "vlc", "mpv"}
local browser_players = {"firefox", "chrome", "chromium", "brave", "edge", "opera", "vivaldi", "plasma-browser-integration", "librewolf", "waterfox", "thorium", "floorp", "epiphany"}

local function is_in_list(name, list)
    local n = name:lower()
    for _, v in ipairs(list) do
        if n:find(v) then return true end
    end
    return false
end

local function get_priority(name, status)
    local score = 0
    if status == "Playing" then score = score + 100 end
    if is_in_list(name, music_players) then score = score + 50
    elseif is_in_list(name, browser_players) then score = score + 20 end
    return score
end

local function extract_yt_thumb(url)
    if not url or url == "" then return "" end
    -- THE FIX: YouTube IDs are strictly 11 characters. This prevents invisible spaces from breaking the URL!
    local vid = url:match("[?&]v=([a-zA-Z0-9_-]{11})")
    if not vid then vid = url:match("youtu%.be/([a-zA-Z0-9_-]{11})") end
    
    -- In case a browser passes the raw ytimg URL but we want to guarantee high-quality
    if not vid then vid = url:match("vi/([a-zA-Z0-9_-]{11})/") end
    
    if vid then return "https://i.ytimg.com/vi/" .. vid .. "/hqdefault.jpg" end
    return ""
end

while true do
    local f = io.popen("timeout 0.5 playerctl -a metadata --format '{{playerName}}|||{{status}}' 2>/dev/null")
    local output = f:read("*a")
    f:close()

    if not output or output == "" then
        print("Stopped<|>No Media Playing<|>0<|>1<|><|>")
    else
        local best_player = nil
        local highest_score = -1

        for line in output:gmatch("[^\r\n]+") do
            local name, status = line:match("^(.-)|||(.-)$")
            if name and status then
                local score = get_priority(name, status)
                if score > highest_score then
                    highest_score = score
                    best_player = name
                end
            end
        end

        if not best_player then
            print("Stopped<|>No Media Playing<|>0<|>1<|><|>")
        else
            local fmt = '{{status}}===#==={{xesam:title}}===#==={{xesam:artist}}===#==={{xesam:album}}===#==={{position}}===#==={{mpris:length}}===#==={{mpris:artUrl}}===#==={{xesam:url}}'
            local meta_f = io.popen("timeout 0.5 playerctl -p '" .. best_player .. "' metadata --format '" .. fmt .. "' 2>/dev/null")
            local meta_out = (meta_f:read("*a") or ""):gsub("\n", " ")
            meta_f:close()

            local status, title, artist, album, pos, len, artUrl, url = meta_out:match("^(.-)===#===(.-)===#===(.-)===#===(.-)===#===(.-)===#===(.-)===#===(.-)===#===(.*)")
            
            if not status or status == "" then
                print("Stopped<|>No Media Playing<|>0<|>1<|><|>")
            else
                artist = (artist and artist ~= "") and artist or album
                artist = (artist and artist ~= "") and artist or best_player
                local meta = (title and title ~= "") and (title .. " - " .. artist) or artist
                
                pos = tonumber(pos) or 0
                len = tonumber(len) or 0
                
                -- Trim whitespace from the extracted URL just to be safe
                url = url and url:match("^%s*(.-)%s*$") or ""
                
                -- Ignore useless favicons sent by web browsers
                if artUrl and artUrl:find("favicon") then artUrl = "" end

                -- Check both the URL and the artUrl for a valid 11-digit YouTube ID
                local yt_thumb = extract_yt_thumb(url)
                if yt_thumb == "" and artUrl then yt_thumb = extract_yt_thumb(artUrl) end
                
                -- Prioritize the YouTube thumbnail if one was found
                if yt_thumb ~= "" then
                    artUrl = yt_thumb
                elseif not artUrl or artUrl == "" then
                    artUrl = ""
                end

                if artUrl and artUrl:sub(1, 1) == "/" then artUrl = "file://" .. artUrl end
                
                print(string.format("%s<|>%s<|>%s<|>%s<|>%s<|>%s", status, meta, pos, len, artUrl, best_player))
            end
        end
    end
    
    io.stdout:flush()
    os.execute("sleep 1")
end
