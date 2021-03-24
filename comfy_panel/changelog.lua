local Global = require 'utils.global'
local Tabs = require 'comfy_panel.main'

local changelog = {
    localised_category = false,
    main_caption = nil,
    main_caption_color = {r = 0.6, g = 0.3, b = 0.99},
    sub_caption = nil,
    sub_caption_color = {r = 0.2, g = 0.9, b = 0.2},
    text = nil
}

Global.register(
    changelog,
    function(tbl)
        changelog = tbl
    end
)

local Public = {}

function Public.Pop_changelog()
    return changelog
end

local create_changelog = (function(player, frame)
    frame.clear()
    frame.style.padding = 4
    frame.style.margin = 0

    local t = frame.add {type = 'table', column_count = 1}

    local line = t.add {type = 'line'}
    line.style.top_margin = 4
    line.style.bottom_margin = 4

    local caption = changelog.main_caption or {changelog.localised_category .. '.changelog_main_caption'}
    local sub_caption = changelog.sub_caption or {changelog.localised_category .. '.changelog_sub_caption'}
    local text = changelog.text or {changelog.localised_category .. '.changelog_text'}

    if changelog.localised_category then
        changelog.main_caption = caption
        changelog.sub_caption = sub_caption
        changelog.text = text
    end
    local l = t.add {type = 'label', caption = changelog.main_caption}
    l.style.font = 'heading-1'
    l.style.font_color = changelog.main_caption_color
    l.style.minimal_width = 780
    l.style.horizontal_align = 'center'
    l.style.vertical_align = 'center'

    local l_2 = t.add {type = 'label', caption = changelog.sub_caption}
    l_2.style.font = 'heading-2'
    l_2.style.font_color = changelog.sub_caption_color
    l_2.style.minimal_width = 780
    l_2.style.horizontal_align = 'center'
    l_2.style.vertical_align = 'center'

    local line_2 = t.add {type = 'line'}
    line_2.style.top_margin = 4
    line_2.style.bottom_margin = 4

    local scroll_pane =
        frame.add {
        type = 'scroll-pane',
        name = 'scroll_pane',
        direction = 'vertical',
        horizontal_scroll_policy = 'never',
        vertical_scroll_policy = 'auto'
    }
    scroll_pane.style.maximal_height = 320
    scroll_pane.style.minimal_height = 320

    local l_3 = scroll_pane.add {type = 'label', caption = changelog.text}
    l_3.style.font = 'scenario-message-dialog'
    l_3.style.single_line = false
    l_3.style.font_color = {r = 0.85, g = 0.85, b = 0.88}
    l_3.style.minimal_width = 780
    l_3.style.horizontal_align = 'left'
    l_3.style.vertical_align = 'center'

    local b = frame.add {type = 'button', caption = 'CLOSE', name = 'close_changelog'}
    b.style.font = 'heading-2'
    b.style.padding = 2
    b.style.top_margin = 3
    b.style.left_margin = 333
    b.style.horizontal_align = 'center'
    b.style.vertical_align = 'center'
end)

local function on_gui_click(event)
    if not event then
        return
    end
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    if event.element.name == 'close_changelog' then
        game.players[event.player_index].gui.left.comfy_panel.destroy()
        return
    end
end

comfy_panel_tabs['Change Log'] = {gui = create_changelog, admin = false}

local event = require 'utils.event'
event.add(defines.events.on_gui_click, on_gui_click)

return Public
