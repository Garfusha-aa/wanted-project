script_name("AutoUpdater")
script_author("you")

local UPDATE_URL = "https://github.com/Garfusha-aa/wanted-project/raw/refs/heads/main/wanted.lua"
local TEMP_FILE = getWorkingDirectory() .. "\\wanted_update.lua"
local LOCAL_FILE = thisScript().path

-- =========================
-- ×òåíèå ôàéëà
-- =========================
function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

-- =========================
-- Ïîëó÷åíèå âåðñèè
-- (ïîääåðæèâàåò ðàçíûå ôîðìàòû)
-- =========================
function get_version(content)
    if not content then return nil end
    
    return content:match('[Vv][Ee][Rr][Ss][Ii][Oo][Nn]%s*=%s*"(.-)"')
        or content:match('[Vv][Ee][Rr][Ss][Ii][Oo][Nn]%s*=%s*(%d+%.?%d*)')
end

-- =========================
-- Ñðàâíåíèå âåðñèé (1.2.3)
-- =========================
function compare_versions(v1, v2)
    if not v1 or not v2 then return false end
    
    local function split(v)
        local t = {}
        for num in v:gmatch("%d+") do
            table.insert(t, tonumber(num))
        end
        return t
    end
    
    local t1, t2 = split(v1), split(v2)
    
    for i = 1, math.max(#t1, #t2) do
        local a = t1[i] or 0
        local b = t2[i] or 0
        if a > b then return true end
        if a < b then return false end
    end
    
    return false
end

-- =========================
-- Îñíîâíàÿ ëîãèêà
-- =========================
function main()
    if not isSampAvailable() then return end
    wait(1000)

    print("[Updater] Ïðîâåðêà îáíîâëåíèÿ...")

    -- êà÷àåì ôàéë
    downloadUrlToFile(UPDATE_URL, TEMP_FILE,
        function(id, status)
            if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                
                local remote_content = read_file(TEMP_FILE)
                local local_content = read_file(LOCAL_FILE)

                local remote_version = get_version(remote_content)
                local local_version = get_version(local_content)

                print("[Updater] Ëîêàëüíàÿ âåðñèÿ:", local_version)
                print("[Updater] Óäàë¸ííàÿ âåðñèÿ:", remote_version)

                if remote_version and (not local_version or compare_versions(remote_version, local_version)) then
                    print("[Updater] Íàéäåíî îáíîâëåíèå!")

                    -- ïåðåçàïèñûâàåì òåêóùèé ñêðèïò
                    local f = io.open(LOCAL_FILE, "w")
                    f:write(remote_content)
                    f:close()

                    print("[Updater] Ñêðèïò îáíîâë¸í, ïåðåçàãðóçêà...")

                    thisScript():reload()
                else
                    print("[Updater] Îáíîâëåíèå íå òðåáóåòñÿ")
                end

                os.remove(TEMP_FILE)
            else
                print("[Updater] Îøèáêà çàãðóçêè")
            end
        end
    )

    while true do wait(0) end
end
