Gui = {}





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
        caption = "Production Analyst",
        direction = "vertical",
        style = NAME.style.base_frame
    }
    root.auto_center = true
    playerdata.gui.root = root

    -- Split frame into left (results) and right (queue/history) panes
    local main_horizontal_flow = root.add{type="flow", name=NAME.gui.main_horizontal_flow, direction="horizontal", style=NAME.style.main_horizontal_flow}

    -- Left pane
    local left_pane_flow = main_horizontal_flow.add{type="flow", name=NAME.gui.left_pane_flow, direction="vertical", style=NAME.style.left_pane_flow}

    local action_button_flow = left_pane_flow.add{type="flow", name=NAME.gui.button_flow}
    action_button_flow.add{type="button", name=NAME.gui.start_button, caption="Start"}
    action_button_flow.add{type="button", name=NAME.gui.stop_button, caption="Stop"}
    local ingredient_selector = action_button_flow.add{type="choose-elem-button", name=NAME.gui.ingredient_selector_elem_button, elem_type="signal", elem_value=forcedata.ingredient}
    if forcedata.ingredient and forcedata.ingredient.type and forcedata.ingredient.name then
        ingredient_selector.elem_value = forcedata.ingredient
    end
    local run_time_slider = action_button_flow.add{type="slider", name=NAME.gui.run_time_slider, minimum_value=5, maximum_value=60, value=60, value_step=5, discrete_slider=true}
    playerdata.gui.run_time_slider = run_time_slider

    local results_scroll_pane = left_pane_flow.add{type="scroll-pane", style="flib_naked_scroll_pane"}

    playerdata.gui.results_container = results_scroll_pane
    Gui.render_results(player_index)

    local right_pane_flow = main_horizontal_flow.add{
        type="flow", name=NAME.gui.right_pane_flow, direction="vertical",
        style=NAME.style.right_pane_flow}

    local queue_container = right_pane_flow.add{type="scroll-pane", name=NAME.gui.queue_container, style=NAME.style.queue_container}
    playerdata.gui.queue_container = queue_container
    Gui.render_queue(player_index)

    local history_container = right_pane_flow.add{type="scroll-pane", name=NAME.gui.history_container, style=NAME.style.history_container}
    playerdata.gui.history_container = history_container
    Gui.render_history(player_index)

end





function Gui.render_queue(player_index)
    local playerdata = get_make_playerdata(player_index)
    local forcedata = get_make_forcedata(playerdata.force_name)
    local parent = playerdata.gui.queue_container

    if playerdata.gui.queue_list then playerdata.gui.queue_list.destroy() end

    local contents = {}
    for i, task in pairs(forcedata.queue) do
        local str = i .. ". " .. task.ingredient.name .. " for " .. task.run_time .. "s"
        table.insert(contents, str)
    end

    local queue_listbox = parent.add{
        type="list-box", name=NAME.gui.queue_listbox, column_count=1, items=contents}
    playerdata.gui.queue_list = queue_listbox
end

function Gui.refresh_queue(force_name)
    local forcedata = get_make_forcedata(force_name)
    for player_index, playerdata in pairs(forcedata.playerdata) do
        if playerdata.is_gui_open then
            Gui.render_queue(player_index)
        end
    end
end





function Gui.render_history(player_index)
    local playerdata = get_make_playerdata(player_index)
    local forcedata = get_make_forcedata(playerdata.force_name)
    local parent = playerdata.gui.history_container

    local history_listbox = parent[NAME.gui.history_listbox]

    if history_listbox and history_listbox.valid then
        history_listbox.destroy()
    end

    local contents = {}
    for i, task in pairs(forcedata.history) do
        local str = i .. ". " .. task.ingredient.name .. " for " .. task.run_time .. "s"
        table.insert(contents, str)
    end

    local index = get_task_index(forcedata.history, playerdata.history_selected_id)
    if not index and #forcedata.history > 0 then
        index = 1
    end

    parent.add{
        type = "list-box",
        name = NAME.gui.history_listbox,
        items = contents,
        selected_index = index}

end

function Gui.refresh_history(force_name, index)
    local forcedata = get_make_forcedata(force_name)
    for player_index, playerdata in pairs(forcedata.playerdata) do
        if playerdata.is_gui_open then
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

    if results_table then results_table.destroy() end

    results_table = parent.add{
        type = "table",
        name = NAME.gui.results_table, 
        column_count = 8,
        draw_horizontal_line_after_headers = true,
        style = NAME.style.results_table}

    results_table.add{type="label", caption="Name"}
    results_table.add{type="label", caption="Amount/craft"}
    results_table.add{type="label", caption="Machines"}
    results_table.add{type="label", caption="Crafts"}
    results_table.add{type="label", caption="Consumption"}
    results_table.add{type="label", caption="Amount per minute"}
    results_table.add{type="label", caption="Percentage"}
    results_table.add{type="label", caption=""}

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
        results_table.add{type="label", caption=recipe.luarecipe.localised_name}
        results_table.add{type="label", caption=recipe.amount}
        results_table.add{type="label", caption=recipe.machines}
        results_table.add{type="label", caption=recipe.crafts}
        results_table.add{type="label", caption=recipe.consumed}
        results_table.add{type="label", caption=string.format("%.00f", recipe.consumed_per_min)}
        results_table.add{type="label", caption=string.format("%.00f", recipe.percentage).."%"}
        results_table.add{type="progressbar", value=recipe.percentage/100}
    end
end

function Gui.update_results(force_name)
    local forcedata = get_make_forcedata(force_name)
    for player_index, playerdata in pairs(forcedata.playerdata) do
        if not playerdata.history_selected_id and #forcedata.history > 0 then
            playerdata.history_selected_id = forcedata.history[1].id
            Gui.render_history(player_index)
        end

        local index = get_task_index(forcedata.history, playerdata.history_selected_id)
        if playerdata.is_gui_open and index == 1 then
            Gui.render_results(player_index)
        end
    end
end





function Gui.on_gui_click(event)
    if event.element.name == NAME.gui.overhead_button then
        Gui.toggle(event.player_index)
    elseif event.element.name == NAME.gui.start_button then
        local playerdata = get_make_playerdata(event.player_index)
        local forcedata = get_make_forcedata(playerdata.force_name)
        forcedata.run_time = playerdata.run_time
        start_task(game.players[event.player_index].force.name)
    elseif event.element.name == NAME.gui.stop_button then
        -- TODO
    end
end
script.on_event(defines.events.on_gui_click, Gui.on_gui_click)

function Gui.on_gui_elem_changed(event)
    if event.element.name ~= NAME.gui.ingredient_selector_elem_button then return end

    local playerdata = get_make_playerdata(event.player_index)
    local forcedata = get_make_forcedata(playerdata.force_name)

    local elem_value = event.element.elem_value
    if elem_value and (elem_value.type == "item" or elem_value.type == "fluid") then
        add_to_queue{
            player_index = event.player_index,
            ingredient = event.element.elem_value,
            run_time = playerdata.gui.run_time_slider.slider_value
        }
    end

    Gui.refresh_queue(forcedata.name)
end
script.on_event(defines.events.on_gui_elem_changed, Gui.on_gui_elem_changed)





function Gui.on_gui_value_changed(event)
    if event.element.name ~= NAME.gui.run_time_slider then return end

    local playerdata = get_make_playerdata(event.player_index)
    playerdata.run_time = event.element.slider_value
end
script.on_event(defines.events.on_gui_value_changed, Gui.on_gui_value_changed)





function Gui.on_gui_selection_state_changed(event)
    local playerdata = get_make_playerdata(event.player_index)
    local forcedata = get_make_forcedata(playerdata.force_name)

    if event.element.name == NAME.gui.queue_listbox then
        playerdata.queue_index = event.element.selected_index
    elseif event.element.name == NAME.gui.history_listbox then
        playerdata.history_selected_id = forcedata.history[event.element.selected_index].id
        Gui.render_results(event.player_index)
    end
end
script.on_event(defines.events.on_gui_selection_state_changed, Gui.on_gui_selection_state_changed)





function Gui.toggle(player_index)
    local playerdata = get_make_playerdata(player_index)
    local root = playerdata.gui.root

    if root and root.valid then
        root.destroy()
        playerdata.is_gui_open = false
    else
        Gui.create_gui(player_index)
        playerdata.is_gui_open = true
    end
end
