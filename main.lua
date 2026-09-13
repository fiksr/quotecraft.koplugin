--[[--
QuoteCraft Plugin for KOReader.
Generates beautiful typographic quote cards from highlights with high-res PNG export and lockscreen wallpaper support.
--]]--

local Device = require("device")
local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local util = require("util")
local _ = require("gettext")

-- Safe submodule loader
local plugin_dir = debug.getinfo(1, "S").source:match("@?(.*[/\\])") or ""
local Settings = dofile(plugin_dir .. "settings.lua")
local CardView = dofile(plugin_dir .. "cardview.lua")

-- Register into KOReader's menu order system
local function addToMenuOrder(module_path, section, name)
    local ok, order = pcall(require, module_path)
    if ok and order and order[section] then
        for i, v in ipairs(order[section]) do
            if v == name then return end
        end
        table.insert(order[section], name)
    end
end
addToMenuOrder("ui/elements/reader_menu_order", "more_tools", "quotecraft")
addToMenuOrder("ui/elements/filemanager_menu_order", "more_tools", "quotecraft")

local QuoteCraft = WidgetContainer:extend{
    name = "quotecraft",
    is_doc_only = false,
}


function QuoteCraft:onDispatcherRegisterActions()
    Dispatcher:registerAction("quotecraft", {
        category = "none",
        event = "ShowQuoteCraft",
        title = _("QuoteCraft"),
        general = true,
    })
end

function QuoteCraft:onShowQuoteCraft()
    local Menu = require("ui/widget/menu")
    local menu = Menu:new{
        title = _("QuoteCraft"),
        item_table = self:getSubMenuItems(),
        is_borderless = true,
    }
    UIManager:show(menu)
end

function QuoteCraft:init()
    self.settings = Settings:new()

    -- Hook into the Reader's highlight dialog
    if self.ui and self.ui.highlight then
        self:addToHighlightDialog()
    end

    -- Register into KOReader's main menu
    if self.ui and self.ui.menu then
        self.ui.menu:registerToMainMenu(self)
    end
end

-- Safely split combined title and author strings (e.g. "Deca vremena - Adrian Tchaikovsky")
local function splitTitleAndAuthor(raw_title, raw_author)
    local title = raw_title or "Untitled"
    local author = raw_author or ""

    title = title:gsub("%.%w+$", "")
    title = title:gsub("^%s+", ""):gsub("%s+$", "")
    author = author:gsub("^%s+", ""):gsub("%s+$", "")

    local t_part, a_part = title:match("^(.-)%s+[%-–—]%s+(.+)$")
    if t_part and a_part and #t_part > 0 and #a_part > 0 then
        title = t_part
        if not author or author == "" or author:lower():find(a_part:lower(), 1, true) or a_part:lower():find(author:lower(), 1, true) then
            author = a_part
        end
    end

    title = title:gsub("^%s+", ""):gsub("%s+$", "")
    author = author:gsub("^%s+", ""):gsub("%s+$", "")

    return title, author
end

function QuoteCraft:addToHighlightDialog()
    -- 00_quotecraft places our button right at the top of the highlight action popup
    self.ui.highlight:addToHighlightDialog("00_quotecraft", function(this)
        return {
            text = _("Create Quote Card"),
            callback = function()
                this:highlightFromHoldPos()
                if not (this.selected_text and this.selected_text.pos0 and this.selected_text.pos1) then return end

                local text = this.selected_text.text
                if this.ui.rolling then
                    local extended = this.document:extendXPointersToSentenceSegment(this.selected_text.pos0, this.selected_text.pos1)
                    text = extended and extended.text or text
                end

                text = util.cleanupSelectedText(text or this.selected_text.text or "")
                if #text == 0 then return end

                this:onClose(true)
                self:openQuoteCard(text)
            end,
        } end)
end

function QuoteCraft:openQuoteCard(text)
    local doc = self.ui and self.ui.document
    local props = (doc and doc.getProps and doc:getProps()) or (self.ui and self.ui.doc_props) or {}

    local raw_title = props.display_title or props.title or (doc and doc.file and doc.file:match("([^/]+)%.%w+$")) or "Untitled"
    local raw_author = props.authors or props.author or ""
    local title, author = splitTitleAndAuthor(raw_title, raw_author)

    -- Chapter title
    local chapter_title = nil
    if self.ui and self.ui.toc and self.ui.toc.getTocTitleOfCurrentPage then
        local ok_ct, ct = pcall(function() return self.ui.toc:getTocTitleOfCurrentPage() end)
        if ok_ct and ct and #ct > 0 then
            chapter_title = ct:gsub("[\r\n]+", ""):gsub("^%s+", ""):gsub("%s+$", "")
        end
    end

    -- Page citation
    local page_str = nil
    local cur_page = (self.ui and self.ui.getCurrentPage and self.ui:getCurrentPage())
                  or (self.ui and self.ui.view and self.ui.view.footer and self.ui.view.footer.pageno)
                  or 1
    local total_pages = (self.ui and self.ui.view and self.ui.view.footer and self.ui.view.footer.pages)
                     or (doc and doc.getPageCount and doc:getPageCount())
                     or 1

    if cur_page and total_pages and total_pages > 1 then
        page_str = string.format("Page %d of %d", cur_page, total_pages)
    end

    -- Book Cover Thumbnail
    local cover_bb = nil
    if doc and doc.getCoverPageImage then
        local ok_cov, img = pcall(function() return doc:getCoverPageImage() end)
        if ok_cov and img then cover_bb = img end
    end
    if not cover_bb and self.ui and self.ui.bookinfo and self.ui.bookinfo.getCoverImage and doc and doc.file then
        local ok_cov, img = pcall(function() return self.ui.bookinfo:getCoverImage(doc, doc.file) end)
        if ok_cov and img then cover_bb = img end
    end

    local card = CardView:new{
        text = text,
        book_title = title,
        book_author = author,
        chapter_title = chapter_title,
        page_str = page_str,
        cover_bb = cover_bb,
        settings = self.settings,
        ui = self.ui,
    }

    UIManager:show(card)
end

function QuoteCraft:addToMainMenu(menu_items)
    menu_items.quotecraft = {
        text = _("QuoteCraft"),
        sorting_hint = "more_tools",
        sub_item_table_func = function()
            return self:getSubMenuItems()
        end,
        sub_item_table = self:getSubMenuItems(),
    }
end

function QuoteCraft:getSubMenuItems()
    return {
        {
            text = _("Browse Saved Quotes"),
            callback = function()
                local dir = self.settings:getExportDir()
                local FileManager = require("apps/filemanager/filemanager")
                FileManager:showFiles(dir)
            end,
        },
        {
            text_func = function()
                return string.format(_("Default Style: %s"), self.settings:getThemeName())
            end,
            callback = function()
                self.settings:nextTheme()
                UIManager:show(InfoMessage:new{
                    text = string.format(_("Default style set to: %s"), self.settings:getThemeName()),
                    timeout = 2,
                })
            end,
        },
        {
            text = _("️ Include Book Cover in Cards"),
            checked_func = function()
                return self.settings:includeCover()
            end,
            callback = function()
                self.settings:save("include_cover", not self.settings:includeCover())
            end,
        },
        {
            text = _("Include Chapter & Page"),
            checked_func = function()
                return self.settings:includeCitation()
            end,
            callback = function()
                self.settings:save("include_citation", not self.settings:includeCitation())
            end,
        },
    } end

return QuoteCraft
