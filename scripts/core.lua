---Gets forcedata for a given `force_name` or creates it if it doesn't exist.
---@param force_name string Force's name
---@return table forcedata
function get_make_forcedata(force_name)
    local forcedata = global.forcedata[force_name]

    if not forcedata then
        forcedata = {
            name = force_name,
            luaforce = game.forces[force_name],
            playerdata = {},
            queue = {},
            history = {},
            is_sampling = false
        }

        -- Save forcedata to global table
        global.forcedata[force_name] = forcedata
    end

    return forcedata
end

---Gets playerdata for a given `player_index` or creates it if it doesn't exist.
---@param player_index number Player index
---@return table playerdata
function get_make_playerdata(player_index)
    local playerdata = global.playerdata[player_index]

    if not playerdata then
        local player = game.players[player_index]

        playerdata = {
            luaplayer = player,
            force_name = player.force.name,
            run_time = DEFAULT_RUN_TIME,
            is_gui_open = false,
            queue_selected_id = nil,
            history_selected_id = nil,
            gui = {
                overhead_button = nil,
                root = nil,
                top_bar_flow = nil,
                run_time_slider = nil,
                results_container = nil,
                queue_container = nil,
                history_container = nil
            }
        }

        local forcedata = get_make_forcedata(player.force.name)
        forcedata.playerdata[player_index] = playerdata
        global.playerdata[player_index] = playerdata
    end

    return playerdata
end

function start_task(force_name, index)
    local forcedata = get_make_forcedata(force_name)
    local task = forcedata.queue[index or 1]

    if not task then return end

    task.recipes = get_consuming_recipes(task.ingredient, forcedata)
    task.consumers = get_consumers(task, forcedata)

    for _, consumer in pairs(task.consumers) do
        if consumer.luaentity and consumer.luaentity.valid then
            consumer.start = consumer.luaentity.products_finished
        end
    end

    task.start_tick = game.tick
    forcedata.is_sampling = true
    add_to_history(force_name, task)

    Gui.refresh_topbar(forcedata.name)

    script.on_nth_tick(60, tick_task)
end

function get_ingredient_amount(ingredient_name, recipe)
    if recipe.object_name ~= "LuaRecipe" then return end

    for _, ingredient in pairs(recipe.ingredients) do
        if ingredient_name == ingredient.name then
            return ingredient.amount
        end
    end
end

---Gets table of recipes unlocked by the given force that consume the target ingredient.
---@param ingredient table Ingredient table containing type and name strings
---@param forcedata table `forcedata` table
---@return table recipes Table of tables containing _LuaRecipe_ objects, indexed by recipe name
function get_consuming_recipes(ingredient, forcedata)
    local recipes = {}
    local prototypes

    if ingredient.type == "item" then
        prototypes = game.get_filtered_recipe_prototypes{{
            filter="has-ingredient-item", elem_filters={{filter="name", name=ingredient.name}}}}
    elseif ingredient.type == "fluid" then
        prototypes = game.get_filtered_recipe_prototypes{{
            filter="has-ingredient-fluid", elem_filters={{filter="name", name=ingredient.name}}}}
    end

    for index, _ in pairs(prototypes) do
        local recipe = forcedata.luaforce.recipes[index]
        if recipe then
            recipes[index] = {
                luarecipe = recipe,
                recipe_name = recipe.name,
                amount = get_ingredient_amount(ingredient.name, recipe),
                machines = 0,
                crafts = 0,
                consumed = 0
            }
        end
    end

    return recipes
end

---Searches through all game surfaces for relevant entities that need to be monitored.
---@param task table Task table
---@param forcedata table forcedata table
---@return table consumers
function get_consumers(task, forcedata)
    local recipes = task.recipes
    local entities, consumers = nil, {}

    for _, surface in pairs(game.surfaces) do
        entities = surface.find_entities_filtered{
            type={"assembling-machine", "furnace", "rocket-silo"}, force=forcedata.luaforce}
        for __, entity in pairs(entities) do
            local current_recipe = entity.get_recipe()
            local key = current_recipe and current_recipe.name or nil

            local multiplier = 1
            if entity.type == "rocket-silo" then
                multiplier = entity.prototype.rocket_parts_required
            end

            if recipes[key] then
                table.insert(consumers, {
                    luaentity = entity,
                    recipe_name = key,
                    amount = recipes[key].amount,
                    multiplier = multiplier
                })
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
            local active_recipe = consumer.luaentity.get_recipe()
            if active_recipe and active_recipe.name == consumer.recipe_name then
                consumer.count = (consumer.luaentity.products_finished - consumer.start) * consumer.multiplier
            end
        else
            consumers[key] = nil
        end
    end
end

---Calculates consumption figures in the recipes table of a task
---@param task table
function compute_totals(task)
    local time_in_sec = (game.tick - task.start_tick) / 60
    local time_in_min = (game.tick - task.start_tick) / 3600
    local total_consumed = 0

    -- Zero out counts in the recipes table
    for _, recipe in pairs(task.recipes) do
        recipe.crafts = 0
        recipe.consumed = 0
        recipe.machines = 0
    end

    -- Tally consumption from each monitored entity
    for _, consumer in pairs(task.consumers) do
        local recipe_entry = task.recipes[consumer.recipe_name]
        local consumed = consumer.count * consumer.amount

        recipe_entry.machines = recipe_entry.machines + 1
        recipe_entry.crafts = recipe_entry.crafts + consumer.count
        recipe_entry.consumed = recipe_entry.consumed + consumed
        total_consumed = total_consumed + consumed
    end

    -- Compute per-unit-time figures and percentages
    for _, recipe in pairs(task.recipes) do
        recipe.consumed_per_s = recipe.consumed / time_in_sec
        recipe.consumed_per_min = recipe.consumed / time_in_min
        recipe.percentage = (recipe.consumed / total_consumed * 100)
    end
end

function stop_task(forcedata, index)
    index = index or 1

    assert(forcedata.queue[index], "Attempted to stop a non-existent task.")

    -- Delete consumers table since it's no longer needed
    forcedata.queue[index].consumers = nil
    forcedata.queue[index].end_tick = game.tick

    table.remove(forcedata.queue, index)

    if #forcedata.queue == 0 then
        forcedata.is_sampling = false
    end

    -- Refresh queues and topbars of players on this force
    Gui.refresh_queue(forcedata.name)
    Gui.refresh_topbar(forcedata.name)

    -- Unbind tick task it no forces are currently sampling
    if not is_any_force_sampling() then script.on_nth_tick(60, nil) end
end
