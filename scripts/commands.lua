-- /reset-prod-analyst-entities
commands.add_command("reset-prod-analyst-entities", nil, function ()
    for _, forcedata in pairs(global.forcedata) do
        forcedata.crafting_entities = get_crafting_entities(forcedata.name)

        local count = 0
        for _, entities in pairs(forcedata.crafting_entities) do
            count = count + table_size(entities)
        end

        game.print({"production-analyst.forcedata-entities-refreshed", count, forcedata.name})
    end
end)
