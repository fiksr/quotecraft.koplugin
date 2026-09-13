--[[--
QuoteCraft Exporter.
Renders typographic quote cards to PNG and integrates with KOReader's screensaver.
--]]--

local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local _ = require("gettext")
local Screen = Device.screen

local Exporter = {}

-- Clean a string to make it safe for filenames
local function sanitizeFilename(str)
    if not str or #str == 0 then return "quote"end
    local clean = str:gsub("[^%w%-_]", "_"):gsub("_+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if #clean == 0 then clean = "quote"end
    if #clean > 25 then clean = clean:sub(1, 25) end
    return clean
end

-- Save quote card to disk as a high-resolution PNG
function Exporter.saveCard(card_view, is_wallpaper)
    local settings = card_view.settings
    local export_dir = settings:ensureExportDir()
    local safe_title = sanitizeFilename(card_view.book_title)
    local date_str = os.date("%Y%m%d_%H%M%S")
    local filename = string.format("Quote_%s_%s.png", safe_title, date_str)
    local filepath = export_dir .. "/".. filename

    -- Temporarily hide the interactive action toolbar so the saved card is 100% pristine
    if card_view.toolbar_widget then
        card_view.toolbar_widget.hidden = true
    end

    -- Force full repaint of pristine card
    UIManager:setDirty(card_view, "full")
    UIManager:forceRePaint()

    -- Capture screen directly to PNG
    local ok, err = pcall(function()
        Screen:shot(filepath)
    end)

    -- Restore toolbar
    if card_view.toolbar_widget then
        card_view.toolbar_widget.hidden = false
    end
    UIManager:setDirty(card_view, "ui")

    if not ok then
        UIManager:show(InfoMessage:new{
            text = string.format(_("Error saving quote card:\n%s"), tostring(err)),
            timeout = 5,
        })
        return nil
    end

    if is_wallpaper then
        if G_reader_settings then
            G_reader_settings:saveSetting("screensaver_type", "document_cover")
            G_reader_settings:saveSetting("screensaver_document_cover", filepath)
        end
        UIManager:show(InfoMessage:new{
            text = string.format(_("️ Set as Lockscreen Wallpaper!\n\nSaved to:\n%s"), filepath),
            timeout = 4,
        })
    else
        UIManager:show(InfoMessage:new{
            text = string.format(_("Quote Card Saved!\n\n%s"), filepath),
            timeout = 3,
        })
    end

    return filepath
end

return Exporter
