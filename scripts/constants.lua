mod_prefix = "prod-analyst-"

NAME = {
    input = {
        toggle_gui = mod_prefix .. "toggle-gui"
    },
    setting = {
        overhead_button = mod_prefix .. "overhead-button"
    },
    gui = {
        overhead_button = mod_prefix .. "overhead-button",
        root = mod_prefix .. "root",
        close_button = mod_prefix .. "close-button",
        main_horizontal_flow = mod_prefix .. "main-horizontal-flow",

        left_pane_flow = mod_prefix .. "left-pane-flow",
        topbar_flow = mod_prefix .. "top-bar-flow",
        start_button = mod_prefix .. "start-button",
        stop_button = mod_prefix .. "stop-button",
        status_label = mod_prefix .. "status-label",
        status_progress_bar = mod_prefix .. "status-progress-bar",

        ingredient_selector_elem_button = mod_prefix .. "ingredient-selector-elem-button",
        results_frame = mod_prefix .. "results-frame",
        results_table = mod_prefix .. "results-table",

        right_pane_frame = mod_prefix .. "right-pane-frame",
        queue_button_frame = mod_prefix .. "queue-button-flow",
        queue_add_button = mod_prefix .. "queue-add-button",
        queue_remove_button = mod_prefix .. "queue-remove-button",
        queue_move_up_button = mod_prefix .. "queue-move-up-button",
        queue_move_down_button = mod_prefix .. "queue-move-down-button",
        queue_container = mod_prefix .. "queue-container",
        queue_listbox = mod_prefix .. "queue-listbox",

        history_button_frame = mod_prefix .. "history-button-frame",
        history_repeat_button = mod_prefix .. "history-repeat-button",
        history_remove_button = mod_prefix .. "history-remove-button",
        history_remove_all_button = mod_prefix .. "history-remove-all-button",
        history_container = mod_prefix .. "history-container",
        history_listbox = mod_prefix .. "history-listbox",

        run_time_slider = mod_prefix .. "run-time-slider",
        run_time_textfield = mod_prefix .. "run-time-textfield"
    },
    style = {
        base_frame = mod_prefix .. "base-frame",
        titlebar_space_header = mod_prefix .. "titlebar-space-header",
        main_horizontal_flow = mod_prefix .. "main-horizontal-flow",

        left_pane_flow = mod_prefix .. "left-pane-flow",
        topbar_flow = mod_prefix .. "topbar-flow",
        start_button = mod_prefix .. "start-button",
        stop_button = mod_prefix .. "stop-button",
        status_label = mod_prefix .. "status-label",
        status_progress_bar = mod_prefix .. "status-progress-bar",

        results_frame = mod_prefix .. "results-frame",
        results_container = mod_prefix .. "results-table-container",
        results_table = mod_prefix .. "results-table",
        recipe_percentage_progressbar = mod_prefix .. "recipe-percentage-progressbar",

        right_pane_frame = mod_prefix .. "right-pane-frame",

        vertical_flow_no_spacing = mod_prefix .. "vertical_flow_no_spacing",

        button_spacer = mod_prefix .. "queue_button_space",

        queue_button_frame = mod_prefix .. "queue-button-frame",
        queue_add_button = mod_prefix .. "queue-add-button",
        queue_button = mod_prefix .. "queue_button",
        queue_container = mod_prefix .. "queue-container",
        queue_listbox = mod_prefix .. "queue-listbox",

        history_button_frame = mod_prefix .. "history-button-frame",
        history_button = mod_prefix .. "history-button",
        history_container = mod_prefix .. "history-container",
        history_listbox = mod_prefix .. "history-table",

        run_time_flow = mod_prefix .. "run-time-flow",
        run_time_slider = mod_prefix .. "run-time-slider",
        run_time_textfield = mod_prefix .. "run-time-textfield"
    }
}

DEFAULT_RUN_TIME = 20