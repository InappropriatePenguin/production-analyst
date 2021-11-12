require("scripts/constants")
require("scripts/core")
require("scripts/gui")
require("scripts/commands")

local event_filter = {
    {filter="type", type="assembling-machine"},
    {filter="type", type="furnace"},
    {filter="type", type="rocket-silo"}}

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

function on_player_created(event)
    get_make_playerdata(event.player_index)

    local overhead_setting =
        settings.get_player_settings(event.player_index)[NAME.setting.overhead_button].value
    if overhead_setting then Gui.create_overhead_button(event.player_index) end
end
script.on_event(defines.events.on_player_created, on_player_created)

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

---Removes playerdata references associated with the removed player
---@param event table
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

---Updates playerdata and forcedata tables to reflect force changes
---@param event table Event table
function on_player_changed_force(event)
    local playerdata = get_make_playerdata(event.player_index)
    playerdata.force_name = playerdata.luaplayer.force.name

    local new_forcedata = get_make_forcedata(playerdata.force_name)
    new_forcedata.playerdata[event.player_index] = playerdata

    local old_forcedata = get_make_forcedata(event.force.name)
    old_forcedata.playerdata[event.player_index] = nil
end
script.on_event(defines.events.on_player_changed_force, on_player_changed_force)

function on_configuration_changed(event)
    for _, player in pairs(game.players) do
        get_make_playerdata(player.index)
    end

    for _, player in pairs(game.connected_players) do
        local setting = settings.get_player_settings(player.index)[NAME.setting.overhead_button]
        if setting.value then
            Gui.create_overhead_button(player.index)
        end
    end

    for _, forcedata in pairs(global.forcedata) do
        forcedata.crafting_entities = get_crafting_entities(forcedata.name)
    end
end
script.on_configuration_changed(on_configuration_changed)

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

---Checks all forces to see if any are actively running a task
---@return boolean
function is_any_force_sampling()
    for _, forcedata in pairs(global.forcedata) do
        if forcedata.is_sampling then return true end
    end

    return false
end

---Creates a new task and adds it to the end of the queue for the player's force
---@param args table Table with {player_index, ingredient, run_time}
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

---Searches for a task in a task array and returns its index
---@param tasks table[] Array of task tables, generally a queue or a history table
---@param id string Task id
---@return number|nil index
function get_task_index(tasks, id)
    if not id then return nil end
    for index, task in pairs(tasks) do
        if task.id == id then return index end
    end
end

---Adds a task to a force's history table
---@param force_name string Force name
---@param task table Task table
function add_to_history(force_name, task)
    local forcedata = get_make_forcedata(force_name)
    table.insert(forcedata.history, 1, task)

    Gui.refresh_history(force_name, 1)
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

function delete_history(force_name)
    local forcedata = get_make_forcedata(force_name)
    for  i = #forcedata.history, 1, -1 do
        remove_from_history(force_name, forcedata.history[i].id)
    end
end

---Adds entity reference to force's crafting_entities table
---@param event table
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

---Removes entity reference from force's crafting_entities table
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

function on_surface_cleared(event)
    for _, forcedata in pairs(global.forcedata) do
        forcedata.crafting_entities[event.surface_index] = nil
    end
end
script.on_event(defines.events.on_surface_cleared, on_surface_cleared)
script.on_event(defines.events.on_surface_deleted, on_surface_cleared)

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

-- Bind hotkey to GUI toggling function
function on_toggle_hotkey(event)
    Gui.toggle(event.player_index)
end
script.on_event(NAME.input.toggle_gui, on_toggle_hotkey)
