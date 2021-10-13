require("scripts/constants")

data:extend{
    {
        type = "custom-input",
        name = NAME.input.toggle_gui,
        key_sequence = "CONTROL + P",
    },
    {
        type = "sprite",
        name = mod_prefix .. "remove-icon",
        filename = "__production-analyst__/graphics/remove-icon.png",
        priority = "medium",
        width = 32,
        height = 32,
        flags = {"icon"}
    }
}

local guistyle = data.raw["gui-style"]["default"]

guistyle[NAME.style.base_frame] = {
    width = 1200,
    height = 800,
    type = "frame_style"
}

guistyle[NAME.style.titlebar_space_header] = {
    type = "empty_widget_style",
    parent = "draggable_space_header",
    height = 24,
    horizontally_stretchable = "on",
    left_margin = 4,
    right_margin = 4
}

guistyle[NAME.style.main_horizontal_flow] = {
    type = "horizontal_flow_style",
    natural_width = 1176,
    height = 736,
    horizontal_spacing = 12,
    horizontal_align = "right"
}

guistyle[NAME.style.left_pane_flow] = {
    type = "vertical_flow_style",
    natural_width = 916,
    height = 736,
    vertical_spacing = 8
}

guistyle[NAME.style.topbar_flow] = {
    type = "horizontal_flow_style",
    horizontally_stretchable = "stretch_and_expand",
    vertical_align = "center"
}

guistyle[NAME.style.start_button] = {
    type = "button_style",
    parent = "green_button",
    padding = 2,
    width = 32,
    height = 32
}

guistyle[NAME.style.stop_button] = {
    type = "button_style",
    parent = "tool_button_red",
    width = 32,
    height = 32
}

guistyle[NAME.style.status_label] = {
    type = "label_style"
}

guistyle[NAME.style.status_progress_bar] = {
    type = "progressbar_style",
    left_margin = 3,
    color = {0.95, 0.95, 0.95},
    bar_background = {},
    font_color = {1, 1, 1},
    filled_font_color = {0.25, 0.25, 0.25},
    width = 180,
    bar_width = 20,
    horizontal_align = "center"
}

guistyle[NAME.style.results_frame] = {
    type = "frame_style",
    parent = "inside_deep_frame",
    -- width = 908,
    -- height = 692,
    horizontally_stretchable = "stretch_and_expand",
    vertically_stretchable = "stretch_and_expand"
}

guistyle[NAME.style.results_container] = {
    type = "scroll_pane_style",
    parent = "scroll_pane",
    padding = 12,
    -- width = 908,
    -- height = 684,
    horizontally_stretchable = "stretch_and_expand",
    vertically_stretchable = "stretch_and_expand"
}

guistyle[NAME.style.results_table] = {
    type = "table_style",
    -- width = 840,
    -- height = 648,
    -- horizontally_stretchable = "stretch_and_expand",
    vertically_stretchable = "stretch_and_expand",
    -- horizontally_squashable = "off",
    top_cell_padding = 3,
    bottom_cell_padding = 3,
    horizontal_spacing = 16,
    column_alignments = {
        {column=1, alignment="left"},
        {column=2, alignment="right"},
        {column=3, alignment="right"},
        {column=4, alignment="center"},
        {column=5, alignment="left"},
        {column=6, alignment="right"},
        {column=7, alignment="right"},
        {column=8, alignment="center"}
    },
    column_widths = {
        {column=1, width=200},
        {column=2, width=65},
        {column=3, width=65},
        {column=4, width=15},
        {column=5, width=40},
        {column=6, width=67},
        {column=7, width=67},
        {column=8, width=190}
    },
    hovered_row_color = {0.4, 0.4, 0.4}
}

guistyle[NAME.style.recipe_percentage_progressbar] = {
    type = "progressbar_style",
    color = {0.95, 0.95, 0.95},
    font_color = {1, 1, 1},
    filled_font_color = {0.25, 0.25, 0.25},
    width = 180,
    bar_width = 20,
    horizontal_align = "center"
}

guistyle[NAME.style.right_pane_frame] = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    direction = "vertical",
    horizontal_align = "right",
    -- height = 736
    width = 300,
    vertical_flow_style = {type="vertical_flow_style", vertical_spacing=8},
    horizontally_stretchable = "stretch_and_expand",
    vertically_stretchable = "stretch_and_expand"
}


guistyle[NAME.style.vertical_flow_no_spacing] = {
    type = "vertical_flow_style",
    vertical_spacing = 0
}


guistyle[NAME.style.queue_button_frame] = {
    type = "frame_style",
    parent = "subheader_frame",
    direction = "horitontal",
    height = 48,
    left_padding = 8,
    right_padding = 8,
    horizontal_flow_style = {type="horizontal_flow_style", vertical_align = "center", horizontal_spacing=1},
    horizontally_stretchable = "stretch_and_expand"
}

guistyle[NAME.style.queue_button] = {
    type = "button_style",
    parent = "tool_button",
    width = 32,
    height = 32
}

guistyle[NAME.style.queue_add_button] = {
    type = "button_style",
    parent = "green_button",
    width = 32,
    height = 32
}

guistyle[NAME.style.button_spacer] = {
    type = "empty_widget_style",
    horizontally_stretchable = "stretch_and_expand"
}

guistyle[NAME.style.queue_container] = {
    type = "scroll_pane_style",
    padding = 0,
    horizontally_stretchable = "stretch_and_expand",
    vertically_stretchable = "stretch_and_expand"
}

guistyle[NAME.style.queue_listbox] = {
    type = "list_box_style",
    horizontally_stretchable = "stretch_and_expand",
    vertically_stretchable = "stretch_and_expand"
}

guistyle[NAME.style.history_button_frame] = {
    type = "frame_style",
    parent = "subheader_frame",
    direction = "horizontal",
    height = 48,
    left_padding = 8,
    right_padding = 8,
    vertical_align = "center",
    horizontal_flow_style = {type="horizontal_flow_style", horizontal_align="right", vertical_align="center", horizontal_spacing=1},
    horizontally_stretchable = "stretch_and_expand"
}

guistyle[NAME.style.history_button] = {
    type = "button_style",
    parent = "tool_button",
    width = 32,
    height = 32
}

guistyle[NAME.style.history_container] = {
    type = "scroll_pane_style",
    -- width = 200,
    -- minimal_height = 150,
    padding = 0,
    horizontally_stretchable = "stretch_and_expand",
    vertically_stretchable = "stretch_and_expand"
}

guistyle[NAME.style.history_listbox] = {
    type = "list_box_style",
    -- width = 200,
    -- minimal_height = 150,
    horizontally_stretchable = "stretch_and_expand",
    vertically_stretchable = "stretch_and_expand"
}

guistyle[NAME.style.run_time_flow] = {
    type = "horizontal_flow_style",
    vertical_align = "center"
}

guistyle[NAME.style.run_time_slider] = {
    type = "slider_style",
    parent = "notched_slider",
    natural_width = 100,
    horizontally_stretchable = "stretch_and_expand",
}

guistyle[NAME.style.run_time_textfield] = {
    type = "textbox_style",
    width = 40,
    horizontal_align = "center"
}