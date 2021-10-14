Gui = {}

---Creates an overhead shortcut for the given player
---@param player_index number Player index
function Gui.create_overhead_button(player_index)
    local playerdata = get_make_playerdata(player_index)
    local button_flow = mod_gui.get_button_flow(playerdata.luaplayer)

    if button_flow[NAME.gui.overhead_button] then return end

    playerdata.gui.overhead_button = button_flow.add{
        type = "button",
        name = NAME.gui.overhead_button,
        caption = "PA",
        tooltip = {"production-analyst.toggle-gui"},
        style = "mod_gui_button"
    }
end

function Gui.create_gui(player_index)
    local playerdata = get_make_playerdata(player_index)
    local forcedata = get_make_forcedata(playerdata.force_name)

    local index = get_task_index(forcedata.history, playerdata.history_selected_id)
    if not index and #forcedata.history > 0 then
        playerdata.history_selected_id = forcedata.history[1].id
    end

    -- Create empty frame
    local root = playerdata.luaplayer.gui.screen.add{
        type = "frame",
        name = NAME.gui.root,
        direction = "vertical",
        style = NAME.style.base_frame
    }
    root.auto_center = true
    playerdata.gui.root = root

    -- Create title bar
    local titlebar_flow = root.add{type="flow", direction="horizontal"}
    titlebar_flow.drag_target = root
    titlebar_flow.add{type="label", caption="Production Analyst", ignored_by_interaction=true, style="frame_title"}
    titlebar_flow.add{type="empty-widget", ignored_by_interaction=true, style=NAME.style.titlebar_space_header}
    titlebar_flow.add{
        type="sprite-button",
        name=NAME.gui.close_button, sprite="utility/close_white", hovered_sprite="utility/close_black", style="close_button"}

    -- Split frame into left (results) and right (queue/history) panes
    local main_horizontal_flow = root.add{
        type="flow",
        name=NAME.gui.main_horizontal_flow,
        direction="horizontal",
        style=NAME.style.main_horizontal_flow}

    -- Left pane
    local left_pane_flow = main_horizontal_flow.add{
        type="flow",
        name=NAME.gui.left_pane_flow,
        direction="vertical",
        style=NAME.style.left_pane_flow}

    local action_button_flow = left_pane_flow.add{type="flow", name=NAME.gui.topbar_flow, style=NAME.style.topbar_flow}
    action_button_flow.add{type="sprite-button", name=NAME.gui.start_button, sprite="utility/play", tooltip={"production-analyst.start"}, style=NAME.style.start_button}
    action_button_flow.add{type="sprite-button", name=NAME.gui.stop_button, sprite="utility/brush_square_shape", tooltip={"production-analyst.stop"}, style=NAME.style.stop_button}
    action_button_flow.add{type="empty-widget", style=NAME.style.button_spacer}
    action_button_flow.add{type="label", name=NAME.gui.status_label}
    action_button_flow.add{type="progressbar", name=NAME.gui.status_progress_bar, style=NAME.style.status_progress_bar}
    playerdata.gui.top_bar_flow = action_button_flow
    Gui.render_topbar(player_index)

    local results_frame = left_pane_flow.add{
        type="frame", style=NAME.style.results_frame}
    local results_scroll_pane = results_frame.add{
        type="scroll-pane",
        style=NAME.style.results_container}
    playerdata.gui.results_container = results_scroll_pane
    Gui.render_results(player_index)

    -- Right pane
    local right_pane_frame = main_horizontal_flow.add{
        type="frame", name=NAME.gui.right_pane_frame, direction="vertical",
        style=NAME.style.right_pane_frame
    }

    local queue_flow = right_pane_frame.add{type="flow", direction="vertical", style=NAME.style.vertical_flow_no_spacing}
    queue_flow.add{type="label", caption={"production-analyst.queue-title"}, style="frame_title"}
    local queue_button_frame = queue_flow.add{
        type="frame",
        name=NAME.gui.queue_button_frame,
        direction="horizontal",
        style=NAME.style.queue_button_frame}
    queue_button_frame.add{
        type="choose-elem-button",
        name=NAME.gui.ingredient_selector_elem_button,
        tooltip={"production-analyst.add-to-queue"},
        elem_type="signal", style=NAME.style.queue_add_button}
    queue_button_frame.add{type="sprite", sprite="utility/add", resize_to_sprite=false, ignored_by_interaction=true, style=NAME.style.queue_add_sprite}

    queue_button_frame.add{type="sprite-button", name=NAME.gui.queue_remove_button, sprite=mod_prefix.."remove-icon", tooltip={"production-analyst.remove-from-queue"}, style=NAME.style.queue_button}
    queue_button_frame.add{type="empty-widget", style=NAME.style.button_spacer}
    queue_button_frame.add{type="sprite-button", name=NAME.gui.queue_move_down_button, sprite="utility/speed_down", tooltip={"production-analyst.move-down-queue"}, style=NAME.style.queue_button}
    queue_button_frame.add{type="sprite-button", name=NAME.gui.queue_move_up_button, sprite="utility/speed_up", tooltip={"production-analyst.move-up-queue"}, style=NAME.style.queue_button}
    playerdata.gui.queue_container = queue_flow.add{type="scroll-pane", name=NAME.gui.queue_container, style=NAME.style.queue_container}

    Gui.render_queue(player_index)

    local history_flow = right_pane_frame.add{type="flow", direction="vertical", style=NAME.style.vertical_flow_no_spacing}
    history_flow.add{type="label", caption={"production-analyst.history-title"}, style="frame_title"}
    local history_button_frame = history_flow.add{
        type="frame",
        name=NAME.gui.history_button_frame,
        direction="horizontal",
        style=NAME.style.history_button_frame}
    history_button_frame.add{type="sprite-button", name=NAME.gui.history_repeat_button, sprite="utility/reset", tooltip={"production-analyst.repeat-task"}, style=NAME.style.history_button}
    history_button_frame.add{type="empty-widget", style=NAME.style.button_spacer}
    history_button_frame.add{type="sprite-button", name=NAME.gui.history_remove_button, sprite=mod_prefix.."remove-icon", tooltip={"production-analyst.remove-history"}, style=NAME.style.history_button}
    history_button_frame.add{type="sprite-button", name=NAME.gui.history_remove_all_button, sprite="utility/trash", tooltip={"production-analyst.remove-all-history"}, style=NAME.style.history_button}
    playerdata.gui.history_container = history_flow.add{type="scroll-pane", name=NAME.gui.history_container, style=NAME.style.history_container}

    Gui.render_history(player_index)

    local run_time_flow = right_pane_frame.add{type="flow", direction="horizontal", style=NAME.style.run_time_flow}
    run_time_flow.add{type="sprite", sprite="utility/clock"}
    run_time_flow.add{type="label", caption="(s):"}
    playerdata.gui.run_time_slider = run_time_flow.add{
        type="slider",
        name=NAME.gui.run_time_slider,
        minimum_value=20,
        maximum_value=120,
        value=playerdata.run_time,
        value_step=20,
        discrete_slider=true,
        style=NAME.style.run_time_slider
    }
    playerdata.gui.run_time_textfield  = run_time_flow.add{
        type="textfield",
        name=NAME.gui.run_time_textfield,
        numeric=true, lose_focus_on_confirm=true,
        text=playerdata.run_time,
        style=NAME.style.run_time_textfield
    }

    playerdata.luaplayer.opened = root
end

function Gui.on_gui_closed(event)
    if event.element and event.element.name == NAME.gui.root then
        Gui.toggle(event.player_index, false)
    end
end
script.on_event(defines.events.on_gui_closed, Gui.on_gui_closed)

function Gui.render_topbar(player_index)
    local playerdata = get_make_playerdata(player_index)
    local forcedata = get_make_forcedata(playerdata.force_name)

    local parent = playerdata.gui.top_bar_flow

    if not (parent and parent.valid) then return end

    local status_label = parent[NAME.gui.status_label]
    local progress_bar = parent[NAME.gui.status_progress_bar]

    if forcedata.is_sampling then
        local task = forcedata.queue[1]
        local icon_str = "[img=" .. task.ingredient.type .. "/" .. task.ingredient.name .. "] "
        local localized_name = task.ingredient.type == "item" and
            game.item_prototypes[task.ingredient.name].localised_name or
            game.fluid_prototypes[task.ingredient.name].localised_name
        -- status_label.caption = {"", "Monitoring " .. #task.consumers .. " entities for " .. icon_str, localized_name, " consumption"}
        status_label.caption = {"production-analyst.topbar-status-text", #task.consumers, icon_str, localized_name}

        local start_tick = task.start_tick or game.tick
        local time_progress = (game.tick - start_tick) / (task.run_time * 60)
        progress_bar.value = time_progress
    else
        status_label.caption = ""
        progress_bar.value = 0
    end
end

function Gui.refresh_topbar(force_name)
    local forcedata = get_make_forcedata(force_name)
    for player_index, playerdata in pairs(forcedata.playerdata) do
        if playerdata.luaplayer.connected and playerdata.is_gui_open then
            Gui.render_topbar(player_index)
        end
    end
end

function Gui.render_queue(player_index)
    local playerdata = get_make_playerdata(player_index)
    local forcedata = get_make_forcedata(playerdata.force_name)
    local parent = playerdata.gui.queue_container
    local queue_listbox = playerdata.gui.queue_list
    local contents = {}

    for _, task in pairs(forcedata.queue) do
        local icon_str = "[img=" .. task.ingredient.type .. "/" .. task.ingredient.name .. "] "
        local localized_name = task.ingredient.type == "item" and
            game.item_prototypes[task.ingredient.name].localised_name or
            game.fluid_prototypes[task.ingredient.name].localised_name
            -- {(task.ingredient.type == "item" and "item-name." or "fluid-name.") .. task.ingredient.name}
        local str = {"", icon_str, localized_name, " [" .. task.run_time .. "s]"}
        table.insert(contents, str)
    end

    if queue_listbox and queue_listbox.valid then
        queue_listbox.clear_items()
        queue_listbox.items = contents
    else
        queue_listbox = parent.add{
            type="list-box", name=NAME.gui.queue_listbox, column_count=1, items=contents, style=NAME.style.queue_listbox}
    end

    playerdata.gui.queue_list = queue_listbox
    local task_index = get_task_index(forcedata.queue, playerdata.queue_selected_id)
    if task_index then playerdata.gui.queue_list.selected_index = task_index end 
end

function Gui.refresh_queue(force_name)
    local forcedata = get_make_forcedata(force_name)
    for player_index, playerdata in pairs(forcedata.playerdata) do
        if playerdata.luaplayer.connected and playerdata.is_gui_open then
            Gui.render_queue(player_index)
        end
    end
end

function Gui.render_history(player_index)
    local playerdata = get_make_playerdata(player_index)
    local forcedata = get_make_forcedata(playerdata.force_name)
    local parent = playerdata.gui.history_container

    local history_listbox = parent[NAME.gui.history_listbox]

    local contents = {}
    for _, task in pairs(forcedata.history) do
        local icon_str = "[img=" .. task.ingredient.type .. "/" .. task.ingredient.name .. "] "
        local localized_name = task.ingredient.type == "item" and
            game.item_prototypes[task.ingredient.name].localised_name or
            game.fluid_prototypes[task.ingredient.name].localised_name
        local str = {"", icon_str, localized_name, " [" .. task.run_time .. "s]"}
        table.insert(contents, str)
    end

    local index = get_task_index(forcedata.history, playerdata.history_selected_id)
    if not index and #forcedata.history > 0 then
        index = 1
        playerdata.history_selected_id = forcedata.history[index].id
    end

    if history_listbox and history_listbox.valid then
        history_listbox.clear_items()
        history_listbox.items = contents
        if index then history_listbox.selected_index = index end
    else
        parent.add{
            type = "list-box",
            name = NAME.gui.history_listbox,
            items = contents,
            selected_index = index,
            style=NAME.style.history_listbox
        }
    end

    Gui.refresh_results(forcedata.name)
end

function Gui.refresh_history(force_name, index)
    local forcedata = get_make_forcedata(force_name)
    for player_index, playerdata in pairs(forcedata.playerdata) do
        if playerdata.luaplayer.connected and playerdata.is_gui_open then
            Gui.render_history(player_index)
        end
    end
end

function Gui.get_history_selected_index(player_index)
    local playerdata = get_make_playerdata(player_index)
    if playerdata.is_gui_open then
        local listbox = playerdata.gui.history_container[NAME.gui.history_listbox]
        return listbox.selected_index
    end
end

function Gui.render_results(player_index)
    local playerdata = get_make_playerdata(player_index)
    local forcedata = get_make_forcedata(playerdata.force_name)
    local parent = playerdata.gui.results_container
    local results_table = playerdata.gui.results_container[NAME.gui.results_table]

    if results_table then
        results_table.clear()
    else
        results_table = parent.add{
            type = "table",
            name = NAME.gui.results_table, 
            column_count = 8,
            draw_horizontal_line_after_headers = true,
            style = NAME.style.results_table}
    end

    -- results_table.add{type="label", caption=""}
    results_table.add{type="label", caption="Recipe", style="bold_label"}
    results_table.add{type="label", caption="Machines", style="bold_label"}
    results_table.add{type="label", caption="Amount", style="bold_label"}
    results_table.add{type="label", caption=""}
    results_table.add{type="label", caption="Crafts", style="bold_label"}
    results_table.add{type="label", caption="Total", style="bold_label"}
    results_table.add{type="label", caption="Per minute", style="bold_label"}
    results_table.add{type="label", caption="%", style="bold_label"}
    -- results_table.add{type="label", caption=""}

    local recipes_sorted = {}

    if #forcedata.history == 0 then return end

    local index = get_task_index(forcedata.history,
        playerdata.history_selected_id)
    local task = index and forcedata.history[index] or nil

    if not task then return end

    for _, recipe in pairs(task.recipes) do
        if recipe.consumed > 0 then
            table.insert(recipes_sorted, recipe)
        end
    end

    table.sort(recipes_sorted, function (a, b)
        if a.consumed > b.consumed then
            return true
        elseif a.consumed < b.consumed then
            return false
        elseif a.recipe_name < b.recipe_name then
            return true
        else
            return false
        end
    end)

    for _, recipe in pairs(recipes_sorted) do
        -- results_table.add{type="sprite-button", style="slot_button", sprite=recipe_icon}
        local recipe_icon = "[img=recipe/" .. recipe.recipe_name .. "] "
        local percentage = string.format("%.00f", recipe.percentage).."%"

        results_table.add{type="label", caption={"", recipe_icon, recipe.luarecipe.localised_name}}
        results_table.add{type="label", caption=recipe.machines}
        results_table.add{type="label", caption=recipe.amount}
        results_table.add{type="label", caption="×"}
        results_table.add{type="label", caption=recipe.crafts}
        results_table.add{type="label", caption=recipe.consumed}
        results_table.add{type="label", caption=string.format("%.00f", recipe.consumed_per_min)}
        results_table.add{type="progressbar", value=recipe.percentage/100, caption=percentage, style=NAME.style.recipe_percentage_progressbar}
        -- results_table.add{type="label", caption=string.format("%.00f", recipe.percentage).."%"}
    end
end

function Gui.refresh_results(force_name)
    local forcedata = get_make_forcedata(force_name)

    for player_index, playerdata in pairs(forcedata.playerdata) do
        if playerdata.luaplayer.connected then
            if not playerdata.history_selected_id and #forcedata.history > 0 then
                playerdata.history_selected_id = forcedata.history[1].id
                Gui.render_history(player_index)
            end

            local index = get_task_index(forcedata.history, playerdata.history_selected_id)
            if playerdata.is_gui_open then
                Gui.render_results(player_index)
            end
        end
    end
end

function Gui.on_gui_click(event)
    local playerdata = get_make_playerdata(event.player_index)
    local forcedata = get_make_forcedata(playerdata.force_name)

    if event.element.name == NAME.gui.overhead_button then
        Gui.toggle(event.player_index)
    elseif event.element.name == NAME.gui.close_button then
        Gui.toggle(event.player_index, false)
    elseif event.element.name == NAME.gui.start_button then
        if not forcedata.is_sampling and #forcedata.queue > 0 then
            start_task(game.players[event.player_index].force.name, 1)
        end
    elseif event.element.name == NAME.gui.stop_button then
        if forcedata.is_sampling and #forcedata.queue > 0 then
            forcedata.is_sampling = false
            stop_task(forcedata, 1)
        end
    elseif event.element.name == NAME.gui.queue_remove_button then
        local task_index = playerdata.gui.queue_container[NAME.gui.queue_listbox].selected_index
        local task = forcedata.queue[task_index]

        if #forcedata.queue > 1 then
            local new_task_index = task_index < #forcedata.queue and task_index+1 or task_index-1
            playerdata.queue_selected_id = forcedata.queue[new_task_index].id
        end

        if task then remove_from_queue(forcedata.name, task.id) end
    elseif event.element.name == NAME.gui.queue_move_down_button then
        local task_index = playerdata.gui.queue_container[NAME.gui.queue_listbox].selected_index
        local task = forcedata.queue[task_index]

        if task then move_down_queue(forcedata.name, task.id) end
    elseif event.element.name == NAME.gui.queue_move_up_button then
        local task_index = playerdata.gui.queue_container[NAME.gui.queue_listbox].selected_index
        local task = forcedata.queue[task_index]

        if task then move_up_queue(forcedata.name, task.id) end
    elseif event.element.name == NAME.gui.history_repeat_button then
        local task_index = playerdata.gui.history_container[NAME.gui.history_listbox].selected_index
        local task = forcedata.history[task_index]

        add_to_queue{ingredient=task.ingredient, run_time=task.run_time, player_index=event.player_index}
    elseif event.element.name == NAME.gui.history_remove_button then
        local task_index = playerdata.gui.history_container[NAME.gui.history_listbox].selected_index
        local task = forcedata.history[task_index]

        if #forcedata.history > 1 then
            local new_task_index = task_index < #forcedata.history and task_index+1 or task_index-1
            playerdata.history_selected_id = forcedata.history[new_task_index].id
        end

        if task then remove_from_history(forcedata.name, task.id) end
    elseif event.element.name == NAME.gui.history_remove_all_button then
        delete_history(playerdata.force_name)
    end
end
script.on_event(defines.events.on_gui_click, Gui.on_gui_click)

function Gui.on_gui_elem_changed(event)
    if event.element.name ~= NAME.gui.ingredient_selector_elem_button then return end

    local playerdata = get_make_playerdata(event.player_index)

    local elem_value = event.element.elem_value
    if elem_value and (elem_value.type == "item" or elem_value.type == "fluid") then
        add_to_queue{
            player_index = event.player_index,
            ingredient = event.element.elem_value,
            run_time = playerdata.run_time
        }
    end

    event.element.elem_value = nil
end
script.on_event(defines.events.on_gui_elem_changed, Gui.on_gui_elem_changed)

function Gui.on_gui_value_changed(event)
    if event.element.name ~= NAME.gui.run_time_slider then return end

    local playerdata = get_make_playerdata(event.player_index)
    local value = event.element.slider_value

    playerdata.run_time = value
    playerdata.gui.run_time_textfield.text = tostring(value)
end
script.on_event(defines.events.on_gui_value_changed, Gui.on_gui_value_changed)

function on_gui_text_changed(event)
    if event.element.name ~= NAME.gui.run_time_textfield then return end

    local playerdata = get_make_playerdata(event.player_index)
    local value = tonumber(event.element.text) or 30

    playerdata.run_time = value
    playerdata.gui.run_time_slider.slider_value = value
end
script.on_event(defines.events.on_gui_text_changed, on_gui_text_changed)

function Gui.on_gui_selection_state_changed(event)
    local playerdata = get_make_playerdata(event.player_index)
    local forcedata = get_make_forcedata(playerdata.force_name)

    if event.element.name == NAME.gui.queue_listbox then
        playerdata.queue_selected_id = forcedata.queue[event.element.selected_index].id
    elseif event.element.name == NAME.gui.history_listbox then
        playerdata.history_selected_id = forcedata.history[event.element.selected_index].id
        Gui.render_results(event.player_index)
    end
end
script.on_event(defines.events.on_gui_selection_state_changed, Gui.on_gui_selection_state_changed)

function Gui.toggle(player_index, state)
    local playerdata = get_make_playerdata(player_index)
    local root = playerdata.gui.root

    if root and root.valid and not state then
        root.destroy()
        playerdata.is_gui_open = false
    else
        Gui.create_gui(player_index)
        playerdata.is_gui_open = true
    end
end
