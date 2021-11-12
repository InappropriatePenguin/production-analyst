---Gets forcedata for a given `force_name` or creates it if it doesn't exist.
---@param force_name string Force's name
---@return ForceData forcedata
function get_make_forcedata(force_name)
    local forcedata = global.forcedata[force_name]

    if not forcedata then
        forcedata = {
            name = force_name,
            luaforce = game.forces[force_name],
            playerdata = {},
            crafting_entities = get_crafting_entities(force_name),
            queue = {},
            history = {},
            is_sampling = false
        }

        ---@type ForceData
        global.forcedata[force_name] = forcedata
    end

    return forcedata
end

---Gets playerdata for a given `player_index` or creates it if it doesn't exist.
---@param player_index uint Player index
---@return PlayerData playerdata
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

---Gets crafting entities belonging to force.
---@param force_name string Force name
---@return table<uint, table<uint, LuaEntity>> crafting_entities Table of crafting entities indexed by surface index and unit number
function get_crafting_entities(force_name)
    local luaforce = game.forces[force_name]
    local crafting_entities = {}

    for _, surface in pairs(game.surfaces) do
        local entities = surface.find_entities_filtered{
            type={"assembling-machine", "furnace", "rocket-silo"}, force=luaforce}
        if #entities > 0 then
            local entities_indexed = {}
            for _, entity in pairs(entities) do entities_indexed[entity.unit_number] = entity end
            crafting_entities[surface.index] = entities_indexed
        end
    end

    return crafting_entities
end

---Start analysis of a task (first in queue if no index is gen) belonging to certain force
---@param force_name string Force's name
---@param index uint Index of task to be started within queue table, defaults to 1
function start_task(force_name, index)
    local forcedata = get_make_forcedata(force_name)
    local task = forcedata.queue[index or 1]

    if not task then return end

    task.recipes = get_consuming_recipes(task.ingredient, forcedata)
    task.consumers = get_consumers(task, forcedata)

    task.start_tick = game.tick
    forcedata.is_sampling = true
    add_to_history(force_name, task)

    Gui.refresh_topbar(forcedata.name)

    script.on_nth_tick(60, nth_tick_task)
end

---Gets the amount of ingredient consumed by a recipe after subtracting average product yield of
---of the ingredient from the recipe
---@param ingredient_name string Ingredient name
---@param recipe table `LuaRecipe`
---@return number|nil amount Amount of ingredient consumed by recipe, nil if that is <= 0
function get_ingredient_amount(ingredient_name, recipe)
    if recipe.object_name ~= "LuaRecipe" then return end

    local amount

    for _, ingredient in pairs(recipe.ingredients) do
        if ingredient_name == ingredient.name then
            amount = ingredient.amount
        end
    end

    for _, product in pairs(recipe.products) do
        if ingredient_name == product.name then
            local product_amount = product.amount or (0.5*(product.amount_min + product.amount_max))
            product_amount = product_amount * (product.probability or 1)
            amount = amount - (product.amount * product.probability)
        end
    end

    return amount > 0 and amount or nil
end

---Gets table of recipes unlocked by the given force that consume the target ingredient.
---@param ingredient table Ingredient table containing type and name strings
---@param forcedata ForceData Data pertaining to force
---@return table<string, Recipe> recipes Table of consuming recipes, indexed by recipe name
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
        local amount = get_ingredient_amount(ingredient.name, recipe)
        if recipe and amount then
            recipes[index] = {
                luarecipe = recipe,
                recipe_name = recipe.name,
                amount = amount,
                energy = recipe.energy,
                machines = 0,
                crafts = 0,
                max_crafts = 0,
                consumed = 0
            }
        end
    end

    return recipes
end

---Searches through all game surfaces for relevant entities that need to be monitored.
---@param task Task Task information
---@param forcedata ForceData forcedata table
---@return table<uint, Consumer> consumers
function get_consumers(task, forcedata)
    local recipes = task.recipes
    local consumers = {}

    for surface_index, entities in pairs(forcedata.crafting_entities) do
        for unit_number, entity in pairs(entities) do
            if entity.valid then
                local current_recipe = entity.get_recipe()
                local key = current_recipe and current_recipe.name or nil

                local multiplier = 1
                if entity.type == "rocket-silo" then
                    multiplier = entity.prototype.rocket_parts_required
                end

                if recipes[key] then
                    consumers[entity.unit_number] = {
                        luaentity = entity,
                        recipe_name = key,
                        amount = recipes[key].amount,
                        crafting_speed = entity.crafting_speed,
                        multiplier = multiplier,
                        start = entity.products_finished,
                        count = 0
                    }
                end
            else
                entities[unit_number] = nil
                if table_size(entities) == 0 then
                    forcedata[surface_index] = nil
                end
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
        recipe.max_crafts = 0
        recipe.consumed = 0
        recipe.machines = 0
    end

    -- Tally consumption from each monitored entity
    for _, consumer in pairs(task.consumers) do
        local recipe = task.recipes[consumer.recipe_name]
        local consumed = consumer.count * consumer.amount

        recipe.machines = recipe.machines + 1
        recipe.crafts = recipe.crafts + consumer.count
        recipe.max_crafts = recipe.max_crafts + ((consumer.crafting_speed * time_in_sec) / recipe.energy)
        recipe.consumed = recipe.consumed + consumed
        total_consumed = total_consumed + consumed
    end

    -- Compute per-unit-time figures and percentages
    for _, recipe in pairs(task.recipes) do
        recipe.consumed_per_s = recipe.consumed / time_in_sec
        recipe.consumed_per_min = recipe.consumed / time_in_min
        recipe.percentage = (recipe.consumed / total_consumed * 100)
    end
end

---Stops work on task for a given force.
---@param forcedata table Forcedata table
---@param index number Index of task within forcedata queue, defaults to 1
---@param no_gui_refresh boolean Should players guis be refereshed to reflect change?
function stop_task(forcedata, index, no_gui_refresh)
    index = index or 1
    no_gui_refresh = no_gui_refresh or false

    assert(forcedata.queue[index], "Attempted to stop a non-existent task.")

    -- Delete consumers table since it's no longer needed
    forcedata.queue[index].consumers = nil
    forcedata.queue[index].end_tick = game.tick

    table.remove(forcedata.queue, index)

    forcedata.is_sampling = false

    -- Refresh queues and topbars of players on this force
    if not no_gui_refresh then
        Gui.refresh_queue(forcedata.name)
        Gui.refresh_topbar(forcedata.name)
    end

    -- Unbind tick task it no forces are currently sampling
    if not is_any_force_sampling() then script.on_nth_tick(60, nil) end
end
