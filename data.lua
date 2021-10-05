require("scripts/core")

local guistyle = data.raw["gui-style"]["default"]

guistyle[NAME.style.base_frame] = {
    width = 1200,
    height = 800,
    type = "frame_style"
}

guistyle[NAME.style.main_horizontal_flow] = {
    natural_width = 1176,
    height = 600,
    horizontal_align = "right",
    type = "horizontal_flow_style"
}

guistyle[NAME.style.left_pane_flow] = {
    type = "vertical_flow_style",
    natural_width = 948
}

guistyle[NAME.style.results_container] = {
    type = "scroll_pane_style",
    
    natural_width = 1200,
    natural_height = 300
}

guistyle[NAME.style.results_table] = {
    type = "table_style",
    natural_width = 1200,
    natural_height = 300,
    horizontal_spacing = 16
}

guistyle[NAME.style.right_pane_flow] = {
    type = "vertical_flow_style",
    horizontal_align = "right",

}

guistyle[NAME.style.queue_container] = {
    type = "scroll_pane_style",
    width = 200,
    minimal_height = 150,
    vertically_stretchable = "on"
}

guistyle[NAME.style.history_container] = {
    type = "scroll_pane_style",
    width = 200,
    minimal_height = 150,
    vertically_stretchable = "on"
}