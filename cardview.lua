--[[--
QuoteCraft Card View Compositor.
Builds high-contrast e-ink quote cards with live theme switching and interactive export controls.
--]]--

local Blitbuffer = require("ffi/blitbuffer")
local Button = require("ui/widget/button")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local ImageWidget = require("ui/widget/imagewidget")
local InfoMessage = require("ui/widget/infomessage")
local InputContainer = require("ui/widget/container/inputcontainer")
local LineWidget = require("ui/widget/linewidget")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local _ = require("gettext")
local Screen = Device.screen

local Exporter = require("exporter")

local CardView = InputContainer:extend{
    name = "quotecraft_card_view",
    is_modal = true,
    covers_fullscreen = true,
    text = "",
    book_title = "Untitled",
    book_author = "Unknown Author",
    chapter_title = nil,
    page_str = nil,
    cover_bb = nil,
    settings = nil,
    theme = "classic",
}

function CardView:init()
    local screen_w = Screen:getWidth()
    local screen_h = Screen:getHeight()
    self.dimen = Geom:new{ x = 0, y = 0, w = screen_w, h = screen_h }

    if Device:hasKeys() then
        self.key_events.AnyKeyPressed = { { Device.input.group.Any } }
    end
    if Device:isTouchDevice() then
        self.ges_events.Swipe = {
            GestureRange:new{ ges = "swipe", range = Geom:new{ x = 0, y = 0, w = screen_w, h = screen_h } }
        }
    end

    if self.settings then
        self.theme = self.settings:getTheme()
    end

    self:buildView()
end

-- Calculate dynamic font size based on quote length
local function getOptimalFontSize(text_len)
    if text_len <= 80 then
        return 28
    elseif text_len <= 180 then
        return 24
    elseif text_len <= 350 then
        return 20
    elseif text_len <= 600 then
        return 17
    else
        return 15
    end
end

function CardView:buildView()
    local screen_w = Screen:getWidth()
    local screen_h = Screen:getHeight()

    local is_dark = (self.theme == "dark")
    local bg_color = is_dark and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_WHITE
    local fg_color = is_dark and Blitbuffer.COLOR_WHITE or Blitbuffer.COLOR_BLACK
    local dim_color = is_dark and Blitbuffer.COLOR_LIGHT_GRAY or Blitbuffer.COLOR_DARK_GRAY
    local line_color = is_dark and Blitbuffer.COLOR_GRAY or Blitbuffer.COLOR_DARK_GRAY

    local content_w = screen_w - 80
    local font_size = getOptimalFontSize(#self.text)

    local card_items = {}

    if self.theme == "classic" then
        -- THEME 1: Classic Literary (Serif, curly quotes, elegant rule)
        table.insert(card_items, TextWidget:new{
            text = "“",
            face = Font:getFace("cfont", 38),
            bold = true,
            fgcolor = fg_color,
        })
        table.insert(card_items, VerticalSpan:new{ width = 6 })

        table.insert(card_items, TextBoxWidget:new{
            text = self.text,
            face = Font:getFace("cfont", font_size),
            italic = true,
            width = content_w,
            fgcolor = fg_color,
            alignment = "left",
        })

        table.insert(card_items, VerticalSpan:new{ width = 16 })
        table.insert(card_items, LineWidget:new{
            background = line_color,
            dimen = Geom:new{ w = content_w, h = 1 },
        })
        table.insert(card_items, VerticalSpan:new{ width = 14 })

        -- Citation Block
        local cite_items = {
            align = "left",
            TextWidget:new{
                text = "— " .. self.book_title,
                face = Font:getFace("cfont", 20),
                bold = true,
                fgcolor = fg_color,
                max_width = content_w - 100,
            },
        }
        if self.book_author and #self.book_author > 0 then
            table.insert(cite_items, VerticalSpan:new{ width = 4 })
            table.insert(cite_items, TextWidget:new{
                text = "by " .. self.book_author,
                face = Font:getFace("cfont", 16),
                italic = true,
                fgcolor = dim_color,
                max_width = content_w - 100,
            })
        end

        local meta_parts = {}
        if self.chapter_title and #self.chapter_title > 0 then
            table.insert(meta_parts, self.chapter_title)
        end
        if self.page_str and #self.page_str > 0 then
            table.insert(meta_parts, self.page_str)
        end
        if #meta_parts > 0 then
            table.insert(cite_items, VerticalSpan:new{ width = 4 })
            table.insert(cite_items, TextWidget:new{
                text = table.concat(meta_parts, "  •  "),
                face = Font:getFace("cfont", 13),
                fgcolor = dim_color,
                max_width = content_w - 100,
            })
        end

        local cite_col = VerticalGroup:new(cite_items)

        -- Optional book cover thumbnail beside citation
        if self.cover_bb and self.settings and self.settings:includeCover() then
            local thumb_w = 70
            local thumb_h = 100
            local thumb = ImageWidget:new{
                image = self.cover_bb,
                width = thumb_w,
                height = thumb_h,
                scale_factor = 0,
            }
            local cite_row = HorizontalGroup:new{
                align = "center",
                cite_col,
                HorizontalSpan:new{ width = 20 },
                thumb,
            }
            table.insert(card_items, cite_row)
        else
            table.insert(card_items, cite_col)
        end

    elseif self.theme == "modern" then
        -- THEME 2: Modern Minimal (Left accent line, crisp sans-serif)
        local quote_box = TextBoxWidget:new{
            text = self.text,
            face = Font:getFace("cfont", font_size),
            width = content_w - 24,
            fgcolor = fg_color,
            alignment = "left",
        }

        local quote_with_bar = HorizontalGroup:new{
            align = "top",
            LineWidget:new{
                background = fg_color,
                dimen = Geom:new{ w = 4, h = math.max(60, font_size * 4) },
            },
            HorizontalSpan:new{ width = 16 },
            quote_box,
        }
        table.insert(card_items, quote_with_bar)

        table.insert(card_items, VerticalSpan:new{ width = 24 })
        table.insert(card_items, LineWidget:new{
            background = line_color,
            dimen = Geom:new{ w = content_w, h = 1 },
        })
        table.insert(card_items, VerticalSpan:new{ width = 12 })

        local meta_line = self.book_title
        if self.book_author and #self.book_author > 0 then
            meta_line = meta_line .. "  •  " .. self.book_author
        end
        if self.page_str and #self.page_str > 0 then
            meta_line = meta_line .. "  (" .. self.page_str .. ")"
        end
        table.insert(card_items, TextWidget:new{
            text = meta_line,
            face = Font:getFace("cfont", 15),
            bold = true,
            fgcolor = fg_color,
            max_width = content_w,
        })

    elseif self.theme == "bookplate" then
        -- THEME 3: Vintage Bookplate (Double frame border, centered layout)
        table.insert(card_items, TextWidget:new{
            text = "“",
            face = Font:getFace("cfont", 32),
            bold = true,
            fgcolor = fg_color,
        })
        table.insert(card_items, VerticalSpan:new{ width = 8 })

        table.insert(card_items, TextBoxWidget:new{
            text = self.text,
            face = Font:getFace("cfont", font_size),
            width = content_w - 40,
            fgcolor = fg_color,
            alignment = "center",
        })

        table.insert(card_items, VerticalSpan:new{ width = 20 })
        table.insert(card_items, TextWidget:new{
            text = "—  ◆  —",
            face = Font:getFace("cfont", 14),
            bold = true,
            fgcolor = dim_color,
        })
        table.insert(card_items, VerticalSpan:new{ width = 14 })

        table.insert(card_items, TextWidget:new{
            text = self.book_title,
            face = Font:getFace("cfont", 20),
            bold = true,
            fgcolor = fg_color,
            max_width = content_w - 40,
        })
        if self.book_author and #self.book_author > 0 then
            table.insert(card_items, VerticalSpan:new{ width = 4 })
            table.insert(card_items, TextWidget:new{
                text = "by " .. self.book_author,
                face = Font:getFace("cfont", 16),
                italic = true,
                fgcolor = dim_color,
                max_width = content_w - 40,
            })
        end

    else -- "dark"
        -- THEME 4: Dark Mode (Inverted OLED/e-ink nighttime appearance)
        table.insert(card_items, TextWidget:new{
            text = "“",
            face = Font:getFace("cfont", 36),
            bold = true,
            fgcolor = fg_color,
        })
        table.insert(card_items, VerticalSpan:new{ width = 6 })

        table.insert(card_items, TextBoxWidget:new{
            text = self.text,
            face = Font:getFace("cfont", font_size),
            italic = true,
            width = content_w,
            fgcolor = fg_color,
            alignment = "left",
        })

        table.insert(card_items, VerticalSpan:new{ width = 18 })
        table.insert(card_items, LineWidget:new{
            background = line_color,
            dimen = Geom:new{ w = content_w, h = 1 },
        })
        table.insert(card_items, VerticalSpan:new{ width = 12 })

        table.insert(card_items, TextWidget:new{
            text = "— " .. self.book_title,
            face = Font:getFace("cfont", 19),
            bold = true,
            fgcolor = fg_color,
            max_width = content_w,
        })
        if self.book_author and #self.book_author > 0 then
            table.insert(card_items, VerticalSpan:new{ width = 4 })
            table.insert(card_items, TextWidget:new{
                text = "by " .. self.book_author,
                face = Font:getFace("cfont", 15),
                italic = true,
                fgcolor = dim_color,
                max_width = content_w,
            })
        end
    end

    local card_inner = VerticalGroup:new(card_items)

    -- Wrap in card container with border if bookplate
    local card_container
    if self.theme == "bookplate" then
        card_container = FrameContainer:new{
            width = content_w + 30,
            background = bg_color,
            bordersize = 2,
            color = fg_color,
            padding = 24,
            margin = 0,
            card_inner,
        }
    else
        card_container = FrameContainer:new{
            width = content_w,
            background = bg_color,
            bordersize = 0,
            padding = 0,
            margin = 0,
            card_inner,
        }
    end

    -- Centered card presentation on screen
    local centered_card = CenterContainer:new{
        dimen = Geom:new{ w = screen_w, h = screen_h - 90 },
        card_container,
    }

    -- Interactive Bottom Action Toolbar
    local theme_name = self.settings and self.settings:getThemeName(self.theme) or "Classic"
    local btn_theme = Button:new{
        text = "🎨 " .. theme_name,
        callback = function()
            self:onCycleTheme()
        end,
        bordersize = 1,
        padding = 8,
    }

    local btn_save = Button:new{
        text = "💾 Save",
        callback = function()
            Exporter.saveCard(self, false)
        end,
        bordersize = 1,
        padding = 8,
    }

    local btn_wallpaper = Button:new{
        text = "🖼️ Wallpaper",
        callback = function()
            Exporter.saveCard(self, true)
        end,
        bordersize = 1,
        padding = 8,
    }

    local btn_copy = Button:new{
        text = "📋 Copy",
        callback = function()
            self:onCopyText()
        end,
        bordersize = 1,
        padding = 8,
    }

    local btn_close = Button:new{
        text = "✕ Close",
        callback = function()
            UIManager:close(self)
        end,
        bordersize = 1,
        padding = 8,
    }

    local toolbar = HorizontalGroup:new{
        align = "center",
        btn_theme,
        HorizontalSpan:new{ width = 6 },
        btn_save,
        HorizontalSpan:new{ width = 6 },
        btn_wallpaper,
        HorizontalSpan:new{ width = 6 },
        btn_copy,
        HorizontalSpan:new{ width = 6 },
        btn_close,
    }

    self.toolbar_widget = FrameContainer:new{
        width = screen_w,
        background = bg_color,
        bordersize = 0,
        padding = 4,
        margin = 0,
        CenterContainer:new{
            dimen = Geom:new{ w = screen_w, h = 56 },
            toolbar,
        },
    }

    self[1] = VerticalGroup:new{
        align = "center",
        centered_card,
        self.toolbar_widget,
    }
end

function CardView:onShow()
    UIManager:setDirty(self, function()
        return "full", Geom:new{ x = 0, y = 0, w = Screen:getWidth(), h = Screen:getHeight() }, true
    end)
    return true
end

function CardView:paintTo(bb, x, y)
    local screen_w = Screen:getWidth()
    local screen_h = Screen:getHeight()
    local is_dark = (self.theme == "dark")
    local bg_color = is_dark and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_WHITE
    bb:paintRect(0, 0, screen_w, screen_h, bg_color)
    if self[1] then
        self[1]:paintTo(bb, x, y)
    end
end

function CardView:onCycleTheme()
    if self.settings then
        self.theme = self.settings:nextTheme()
    end
    self:buildView()
    UIManager:setDirty(self, "full")
end

function CardView:onCopyText()
    local citation = "— " .. self.book_title
    if self.book_author and #self.book_author > 0 then
        citation = citation .. ", by " .. self.book_author
    end
    if self.page_str and #self.page_str > 0 then
        citation = citation .. " (" .. self.page_str .. ")"
    end
    local full_quote = string.format("“%s”\n\n%s", self.text, citation)

    if Device:hasClipboard() then
        Device.input.setClipboardText(full_quote)
        UIManager:show(InfoMessage:new{
            text = _("Quote copied to clipboard!"),
            timeout = 2,
        })
    end
end

function CardView:onSwipe(arg, ges)
    UIManager:close(self)
    return true
end

function CardView:onAnyKeyPressed()
    UIManager:close(self)
    return true
end

function CardView:onClose()
    UIManager:setDirty(nil, "full")
end

return CardView
