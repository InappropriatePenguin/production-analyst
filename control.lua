require("scripts/constants")
require("scripts/core")
require("scripts/gui")
require("scripts/commands")

local event_filter = {
    {filter="type", type="assembling-machine"},
    {filter="type", type="furnace"},
    {filter="type", type="rocket-silo"}}

---Creates global tables.
function on_init()
    ---@type table<string, ForceData>
    global.forcedata = {}
    ---@type table<uint, PlayerData>
    global.playerdata = {}
end
script.on_init(on_init)

---Re-bind on_nth_tick handler if any player was sampling
function on_load()
    if is_any_force_sampling() then script.on_nth_tick(60, nth_tick_task) end
end
script.on_load(on_load)

---Creates a PlayerData table for the player and creates the overhead gui button.
---@param event on_player_created
function on_player_created(event)
    get_make_playerdata(event.player_index)

    local overhead_setting =
        settings.get_player_settings(event.player_index)[NAME.setting.overhead_button].value
    if overhead_setting then Gui.create_overhead_button(event.player_index) end
end
script.on_event(defines.events.on_player_created, on_player_created)

---Handles creation or destruction of overhead gui button based on player setting.
---@param event on_player_joined_game
function on_player_joined_game(event)
    local playerdata = get_make_playerdata(event.player_index)

    local overhead_setting =
        settings.get_player_settings(event.player_index)[NAME.setting.overhead_button].value

    if overhead_setting and not playerdata.gui.overhead_button then
        Gui.create_overhead_button(event.player_index)
    elseif not overhead_setting and playerdata.gui.overhead_button then
        playerdata.gui.overhead_button.destroy()
        playerdata.gui.overhead_button = nil
    end
end
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)

---Removes playerdata references associated with the removed player.
---@param event on_player_removed
function on_player_removed(event)
    -- Find and delete any references to playerdata in forcedata tables
    for _, forcedata in pairs(global.forcedata) do
        if forcedata.playerdata[event.player_index] then
            forcedata.playerdata[event.player_index] = nil
            break
        end
    end

    global.playerdata[event.player_index] = nil
end
script.on_event(defines.events.on_player_removed, on_player_removed)

---Updates playerdata and forcedata tables to reflect force changes.
---@param event on_player_changed_force
function on_player_changed_force(event)
    local playerdata = get_make_playerdata(event.player_index)
    playerdata.force_name = playerdata.luaplayer.force.name

    local new_forcedata = get_make_forcedata(playerdata.force_name)
    new_forcedata.playerdata[event.player_index] = playerdata

    local old_forcedata = get_make_forcedata(event.force.name)
    old_forcedata.playerdata[event.player_index] = nil
end
script.on_event(defines.events.on_player_changed_force, on_player_changed_force)

---Handles some mod data validation.
---@param event ConfigurationChangedData
function on_configuration_changed(event)
    for _, player in pairs(game.players) do get_make_playerdata(player.index) end

    for _, player in pairs(game.connected_players) do
        local setting = settings.get_player_settings(player.index)[NAME.setting.overhead_button]
        if setting.value then
            Gui.create_overhead_button(player.index)
        end
    end

    for _, forcedata in pairs(global.forcedata) do
        forcedata.crafting_entities = get_crafting_entities(forcedata.name)
    end

    validate_prototype_references()
end
script.on_configuration_changed(on_configuration_changed)

---Handles player setting changes.
---@param event on_runtime_mod_setting_changed
function on_runtime_mod_setting_changed(event)
    if event.player_index and event.setting == NAME.setting.overhead_button then
        local playerdata = get_make_playerdata(event.player_index)
        local setting = settings.get_player_settings(event.player_index)[NAME.setting.overhead_button].value

        if setting == true then
            Gui.create_overhead_button(event.player_index)
        elseif playerdata.gui.overhead_button then
            playerdata.gui.overhead_button.destroy()
            playerdata.gui.overhead_button = nil
        end
    end
end
script.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)

---Validates each task and recipe to remove reference to items, fluids, and recipes that are no
---longer in the game.
function validate_prototype_references()
    for _, forcedata in pairs(global.forcedata) do
        local is_queue_modified = false
        local is_history_modified = false
        local n_queue = #forcedata.queue
        local n_history = #forcedata.history

        -- Remove queue tasks based on no-longer-valid ingredients
        for i, task in pairs(forcedata.queue) do
            local proto = task.ingredient.type == "item" and "item_prototypes" or "fluid_prototypes"
            if not game[proto][task.ingredient.name] then
                if forcedata.is_sampling and i == 1 then
                    forcedata.is_sampling = false
                    stop_task(forcedata, 1, true)
                end
                forcedata.queue[i] = nil
                is_queue_modified = true
            end
        end

        -- If queue was modified, recompact it into an array
        if is_queue_modified == true then
            local queue = {}
            for i = 1, n_queue do
                if forcedata.queue[i] then table.insert(queue, forcedata.queue[i]) end
            end
            forcedata.queue = queue
        end

        -- Remove history tasks if they reference invalid prototypes
        for i, task in pairs(forcedata.history) do
            local proto = task.ingredient.type == "item" and "item_prototypes" or "fluid_prototypes"
            if not game[proto][task.ingredient.name] then
                forcedata.history[i] = nil
                is_history_modified = true
            end
        end

        -- If history was modified, recompact it into an array
        if is_history_modified == true then
            local history = {}
            for i = 1, n_history do
                if forcedata.history[i] then table.insert(history, forcedata.history[i]) end
            end
            forcedata.history = history
        end

        -- Update all guis
        Gui.refresh_topbar(forcedata.name)
        Gui.refresh_queue(forcedata.name)
        Gui.refresh_history(forcedata.name)
        Gui.refresh_results(forcedata.name)
    end
end

---Checks all forces to see if any are actively running a task.
---@return boolean is_sampling
function is_any_force_sampling()
    for _, forcedata in pairs(global.forcedata) do
        if forcedata.is_sampling then return true end
    end

    return false
end

---Creates a new task and adds it to the end of the queue for the player's force.
---@param args table<string, uint|IngredientInfo> Table with {player_index, ingredient, run_time}
function add_to_queue(args)
    local playerdata = get_make_playerdata(args.player_index)
    local forcedata = get_make_forcedata(playerdata.force_name)

    assert(args.ingredient.type and args.ingredient.name, "Invalid ingredient passed to queue")
    assert(args.ingredient.type == "item" or args.ingredient.type == "fluid",
        "Invalid ingredient type passed to queue")

    if args.ingredient and (args.ingredient.type == "item" or args.ingredient.type == "fluid") then
        local task = {
            id = args.player_index .. "-" .. game.tick,
            ingredient = args.ingredient,
            recipes = {},
            consumers = {},
            run_time = args.run_time,
            start_tick = nil,
            end_tick = nil,
            player_index=args.player_index
        }
        table.insert(forcedata.queue, task)
    end

    Gui.refresh_queue(forcedata.name)
end

---Removes a task from queue as long as it's not already in progress
---@param force_name string Force name
---@param task_id string Unique id for task to be removed
function remove_from_queue(force_name, task_id)
    local forcedata = get_make_forcedata(force_name)
    local index = get_task_index(forcedata.queue, task_id)

    if forcedata.is_sampling and index == 1 then return end

    if index then
        table.remove(forcedata.queue, index)
        Gui.refresh_queue(forcedata.name)
    end
end

---Moves a task up the queue.
---@param force_name string Force name
---@param task_id string Unique task identifier
function move_up_queue(force_name, task_id)
    local forcedata = get_make_forcedata(force_name)
    local queue = forcedata.queue
    local task_index = get_task_index(queue, task_id)

    if not task_index or task_index == 1 then return end
    if forcedata.is_sampling and task_index - 1 == 1 then return end

    local new_task = queue[task_index]
    local old_task = queue[task_index - 1]

    queue[task_index] = old_task
    queue[task_index - 1] = new_task

    Gui.refresh_queue(force_name)
end

---Moves a task down the queue.
---@param force_name string Force name
---@param task_id string Unique task identifier
function move_down_queue(force_name, task_id)
    local forcedata = get_make_forcedata(force_name)
    local queue = forcedata.queue
    local task_index = get_task_index(queue, task_id)

    if not task_index or task_index == #queue then return end
    if forcedata.is_sampling and task_index == 1 then return end

    local new_task = queue[task_index]
    local old_task = queue[task_index + 1]

    queue[task_index] = old_task
    queue[task_index + 1] = new_task

    Gui.refresh_queue(force_name)
end

---Searches for a task in a task array and returns its index.
---@param tasks Task[] Array of tasks, generally a queue or a history table
---@param id string Unique task identifier
---@return uint|nil index
function get_task_index(tasks, id)
    if not id then return nil end
    for index, task in pairs(tasks) do
        if task.id == id then return index end
    end
end

---Adds a task to a force's history table.
---@param force_name string Force name
---@param task Task Task to be added
function add_to_history(force_name, task)
    local forcedata = get_make_forcedata(force_name)
    table.insert(forcedata.history, 1, task)

    Gui.refresh_history(force_name)
end

---Removes a task from a force's history as long as it's not in progress.
---@param force_name string Force name
---@param task_id string
function remove_from_history(force_name, task_id)
    local forcedata = get_make_forcedata(force_name)
    local index = get_task_index(forcedata.history, task_id)

    if forcedata.is_sampling and index == 1 then return end

    if index then
        table.remove(forcedata.history, index)
        Gui.refresh_history(forcedata.name)
    end
end

---Deletes the entire history table of a force.
---@param force_name string Force name
function delete_history(force_name)
    local forcedata = get_make_forcedata(force_name)
    for  i = #forcedata.history, 1, -1 do
        remove_from_history(force_name, forcedata.history[i].id)
    end
end

---Adds entity reference to force's crafting_entities table.
---@param event EntityCreationData
function on_entity_created(event)
    local entity = event.created_entity or event.entity or event.destination
    local forcedata = get_make_forcedata(entity.force.name)

    local crafting_entities = forcedata.crafting_entities
    local surface_index = entity.surface.index

    -- Create surface table if one doesn't exist
    crafting_entities[surface_index] = crafting_entities[surface_index] or {}

    -- Add entity to appropriate crafting_entities table
    crafting_entities[surface_index][entity.unit_number] = entity
end
script.on_event(defines.events.on_built_entity, on_entity_created, event_filter)
script.on_event(defines.events.on_robot_built_entity, on_entity_created, event_filter)
script.on_event(defines.events.on_entity_cloned, on_entity_created, event_filter)
script.on_event(defines.events.script_raised_built, on_entity_created, event_filter)
script.on_event(defines.events.script_raised_revive, on_entity_created, event_filter)

---Removes entity reference from force's crafting_entities table.
---@param event table
function on_entity_destroyed(event)
    local entity = event.entity
    local forcedata = get_make_forcedata(entity.force.name)
    local surface_index = entity.surface.index

    -- Remove entity reference if it exists
    if forcedata.crafting_entities[surface_index] then
        forcedata.crafting_entities[surface_index][entity.unit_number] = nil
    end

    -- Remove surface table reference if empty
    if table_size(forcedata.crafting_entities[surface_index]) == 0 then
        forcedata.crafting_entities[surface_index] = nil
    end
end
script.on_event(defines.events.on_entity_died, on_entity_destroyed, event_filter)
script.on_event(defines.events.on_player_mined_entity, on_entity_destroyed, event_filter)
script.on_event(defines.events.on_robot_mined_entity, on_entity_destroyed, event_filter)
script.on_event(defines.events.script_raised_destroy, on_entity_destroyed, event_filter)

---Deletes entities that were on cleared or deleted surface from crafting entity lists.
---@param event on_surface_cleared|on_surface_deleted
function on_surface_cleared(event)
    for _, forcedata in pairs(global.forcedata) do
        forcedata.crafting_entities[event.surface_index] = nil
    end
end
script.on_event(defines.events.on_surface_cleared, on_surface_cleared)
script.on_event(defines.events.on_surface_deleted, on_surface_cleared)

---Seeks new data from monitored machines and refreshes guis if appropriate.
---@param event NthTickEventData
function nth_tick_task(event)
    for _, forcedata in pairs(global.forcedata) do
        if forcedata.is_sampling then
            local task = forcedata.queue[1]
            if not task.start_tick then
                start_task(forcedata.name)
            else
                inspect_machines(task.consumers)
                compute_totals(task)
            end

            Gui.refresh_results(forcedata.name)
            Gui.refresh_topbar(forcedata.name)

            if game.tick > task.start_tick + (task.run_time * 60) then
                stop_task(forcedata, 1)
                if #forcedata.queue > 0 then
                    start_task(forcedata.name, 1)
                end
            end
        end
    end
end

---Bind hotkey to GUI toggling function.
---@param event CustomInputEvent
function on_toggle_hotkey(event)
    Gui.toggle(event.player_index)
end
script.on_event(NAME.input.toggle_gui, on_toggle_hotkey)
