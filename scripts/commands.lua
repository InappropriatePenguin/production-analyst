---Resets the `crafting_entities` table belonging to each force and repopulates it using
---`find_entities_filtered` calls.
function reset_crafting_entities()
    for _, forcedata in pairs(global.forcedata) do
        forcedata.crafting_entities = get_crafting_entities(forcedata.name)

        local count = 0
        for _, entities in pairs(forcedata.crafting_entities) do
            count = count + table_size(entities)
        end

        game.print({"production-analyst.forcedata-entities-refreshed", count, forcedata.name})
    end
end
-- /reset-prod-analyst-entities
commands.add_command("reset-prod-analyst-entities", {"command-help.prod-analyst-reset-entities"},
    reset_crafting_entities)
