--[[--
QuoteCraft Settings Manager.
Handles persistent user preferences in G_reader_settings.
--]]--

local DataStorage = require("datastorage")
local lfs = require("libs/libkoreader-lfs")
local util = require("util")

local Settings = {}
Settings.__index = Settings

local THEMES = { "classic", "modern", "bookplate", "dark"}

local THEME_NAMES = {
    classic = "Classic Literary",
    modern = "Modern Minimal",
    bookplate = "Vintage Bookplate",
    dark = "Dark Mode",
}

function Settings:new()
    local o = setmetatable({}, self)
    o:ensureExportDir()
    return o
end

function Settings:get(key, default)
    if not G_reader_settings then return default end
    local val = G_reader_settings:readSetting("quotecraft_".. key)
    if val ~= nil then return val end
    return default
end

function Settings:save(key, val)
    if not G_reader_settings then return end
    G_reader_settings:saveSetting("quotecraft_".. key, val)
end

function Settings:getTheme()
    return self:get("theme", "classic")
end

function Settings:setTheme(theme)
    self:save("theme", theme)
end

function Settings:getThemeName(theme)
    return THEME_NAMES[theme or self:getTheme()] or "Classic Literary"
end

function Settings:nextTheme()
    local cur = self:getTheme()
    local next_t = THEMES[1]
    for i, t in ipairs(THEMES) do
        if t == cur then
            next_t = THEMES[(i % #THEMES) + 1]
            break
        end
    end
    self:setTheme(next_t)
    return next_t
end

function Settings:getExportDir()
    local custom = self:get("export_dir", nil)
    if custom and #custom > 0 then
        return custom:gsub("/+$", "")
    end

    -- Prefer /mnt/us/quotes on Kindle for easy USB/WebDAV access
    if lfs.attributes("/mnt/us", "mode") == "directory" then
        return "/mnt/us/quotes"
    end

    return DataStorage:getFullDataDir() .. "/quotes"
end

function Settings:ensureExportDir()
    local dir = self:getExportDir()
    pcall(util.makePath, dir)
    return dir
end

function Settings:includeCover()
    return self:get("include_cover", true)
end

function Settings:includeCitation()
    return self:get("include_citation", true)
end

return Settings
