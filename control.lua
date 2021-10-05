mod_gui = require("__core__/lualib/mod-gui")

require("scripts/core")
require("scripts/gui")




function on_init()
    global.forcedata = {}
    global.playerdata = {}

    for _, force in pairs(game.forces) do
        local force_name = force.name
        if force_name ~= "enemy" and force_name ~= "neutral" then
            get_make_forcedata(force_name)
        end
    end
end
script.on_init(on_init)




---Gets forcedata for a given `force_name` or creates it if it doesn't exist.
---@param force_name string Force's name
---@return table forcedata
function get_make_forcedata(force_name)
    if global.forcedata[force_name] then
        return global.forcedata[force_name]
    else
        global.forcedata[force_name] = {
            name = force_name,
            luaforce = game.forces[force_name],
            playerdata = {},
            -- ingredient = {},
            -- recipes = {},
            -- consumers = {},
            queue = {},
            history = {},
            is_sampling = false,
            -- run_time = 60,
            -- start_tick = nil,
            -- end_tick = nil
        }
        return global.forcedata[force_name]
    end
end

---Gets playerdata for a given `player_index` or creates it if it doesn't exist.
---@param player_index number Player index
---@return table playerdata
function get_make_playerdata(player_index)
    if global.playerdata[player_index] then
        return global.playerdata[player_index]
    else
        local player = game.players[player_index]
        global.playerdata[player_index] = {
            luaplayer = player,
            force_name = player.force.name,
            run_time = 60,
            is_gui_open = false,
            queue_selected_id = nil,
            history_selected_id = nil,
            gui = {
                overhead_button = nil,
                root = nil,
                run_time_slider = nil,
                results_container = nil,
                queue_container = nil,
                history_container = nil
            }
        }

        table.insert(global.forcedata[player.force.name].playerdata,
            global.playerdata[player_index])

        return global.playerdata[player_index]
    end
end




function on_player_joined_game(event)
    playerdata = get_make_playerdata(event.player_index)

    local button_flow = mod_gui.get_button_flow(game.players[event.player_index])
    if button_flow then
        playerdata.gui.overhead_button = button_flow.add{type="button", name=NAME.gui.overhead_button, caption="PA"} 
    end
end
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)

function on_configuration_changed()
    for _, player in pairs(game.players) do
        get_make_playerdata(player.index)
    end

    for _, player in pairs(game.connected_players) do
        local button_flow = mod_gui.get_button_flow(player)
        if button_flow and not button_flow[NAME.gui.overhead_button] then
            global.playerdata[player.index].gui.overhead_button = button_flow.add{type="button", name=NAME.gui.overhead_button, caption="PA"}
        end
    end
end
script.on_configuration_changed(on_configuration_changed)




---Gets table of recipes unlocked by the given force that consume the target ingredient.
---@param ingredient table Ingredient table containing type and name strings
---@param force table _LuaForce_, Player's force
---@return table recipes Table of tables containing _LuaRecipe_ objects, indexed by recipe name
function get_consuming_recipes(ingredient, force)
    local recipes = {}

    for _, recipe in pairs(force.recipes) do
        for __, i in pairs(recipe.ingredients) do
            if i.name == ingredient.name then
                recipes[recipe.name] = {
                    luarecipe = recipe,
                    recipe_name = recipe.name,
                    amount = i.amount,
                    machines = 0,
                    crafts = 0,
                    consumed = 0}
                break
            end
        end
    end

    return recipes
end

---Searches through all game surfaces for relevant entities that need to be monitored.
---@param ingredient string Ingredient name
---@param force table _LuaForce_ Player's force
---@return table consumers
function get_consumers(ingredient, force)
    local recipes = get_consuming_recipes(ingredient, force)
    local entities, consumers = nil, {}

    for _, surface in pairs(game.surfaces) do
        entities = surface.find_entities_filtered{type={"assembling-machine"}, force=force}
        for __, entity in pairs(entities) do
            local current_recipe = entity.get_recipe()
            local key = current_recipe and current_recipe.name or nil
            if recipes[key] then
                table.insert(consumers, {
                    luaentity = entity,
                    recipe_name = key,
                    amount = recipes[key].amount})
            end
        end
    end

    return consumers
end




---Updates number of crafts completed by each consumer.
---@param consumers table Consumers table
function inspect_machines(consumers)
    for key, consumer in pairs(consumers) do
        if consumer.luaentity and consumer.luaentity.valid then
            consumer.count = consumer.luaentity.products_finished - consumer.start
        else
            consumers[key] = nil
        end
    end
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
end

function remove_from_queue(player_index, position)
    local playerdata = get_make_playerdata(player_index)
    local forcedata = get_make_forcedata(playerdata.force_name)

    table.remove(forcedata.queue, position)
end


function get_task_index(tasks, id)
    if not id then return nil end
    for index, task in pairs(tasks) do
        if task.id == id then return index end
    end
end



function start(force_name)
    local forcedata = get_make_forcedata(force_name)

    forcedata.recipes = get_consuming_recipes(forcedata.ingredient, forcedata.luaforce)
    forcedata.consumers = get_consumers(forcedata.ingredient, forcedata.luaforce)

    for i, consumer in pairs(forcedata.consumers) do
        if consumer.luaentity and consumer.luaentity.valid then
            consumer.start = consumer.luaentity.products_finished
        end
    end

    forcedata.start_tick = game.tick
    forcedata.is_sampling = true
    forcedata.end_tick = forcedata.start_tick + (forcedata.run_time*60)
end




function compute_totals(task)
    local total_consumed = 0

    local time_in_sec = (game.tick - task.start_tick) / 60
    local time_in_min = (game.tick - task.start_tick) / 3600

    for _, recipe in pairs(task.recipes) do
        recipe.crafts = 0
        recipe.consumed = 0
        recipe.machines = 0
    end

    for _, consumer in pairs(task.consumers) do
        local recipe_entry = task.recipes[consumer.recipe_name]
        local consumed = consumer.count * consumer.amount

        recipe_entry.machines = recipe_entry.machines + 1
        recipe_entry.crafts = recipe_entry.crafts + consumer.count
        recipe_entry.consumed = recipe_entry.consumed + consumed
        total_consumed = total_consumed + consumed
    end
    for _, recipe in pairs(task.recipes) do
        recipe.consumed_per_s = recipe.consumed / time_in_sec
        recipe.consumed_per_min = recipe.consumed / time_in_min
        recipe.percentage = (recipe.consumed / total_consumed * 100)
    end
end





function add_to_history(force_name, task)
    local forcedata = get_make_forcedata(force_name)
    table.insert(forcedata.history, 1, task)
    Gui.refresh_history(force_name, 1)
end





function start_task(force_name)
    local forcedata = get_make_forcedata(force_name)
    local task = forcedata.queue[1]

    task.recipes = get_consuming_recipes(task.ingredient, forcedata.luaforce)
    task.consumers = get_consumers(task.ingredient, forcedata.luaforce)

    for _, consumer in pairs(task.consumers) do
        if consumer.luaentity and consumer.luaentity.valid then
            consumer.start = consumer.luaentity.products_finished
        end
    end

    task.start_tick = game.tick
    forcedata.is_sampling = true
    task.end_tick = game.tick + (task.run_time * 60)
    add_to_history(force_name, task)
end




function stop_task(forcedata)
    forcedata.queue[1].consumers = nil
    table.remove(forcedata.queue, 1)
    Gui.refresh_queue(forcedata.name)

    if #forcedata.queue == 0 then
        forcedata.is_sampling = false
    end
end





function tick_task(event)
    for _, forcedata in pairs(global.forcedata) do
        if forcedata.is_sampling then
            local task = forcedata.queue[1]
            if not task.start_tick then
                start_task(forcedata.name)
            else
                inspect_machines(task.consumers)
                compute_totals(task)
            end

            Gui.update_results(forcedata.name)

            if game.tick > task.start_tick + (task.run_time * 60) then
                -- complete_task
                stop_task(forcedata)
                if #forcedata.queue > 0 then
                    start_task(forcedata.name)
                end
            end
        end
    end
end
script.on_nth_tick(60, tick_task)




require("scripts/remote")