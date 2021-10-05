remote.add_interface("prod-analyst", {

    -- /c remote.call("prod-analyst", "get_consuming_recipes", "iron-plate", game.player.force)
    get_consuming_recipes = get_consuming_recipes,

    -- /c remote.call("prod-analyst", "get_consumers", "iron-plate", game.player.force)
    get_consumers = get_consumers,

    start = function()
        local forcedata = global.forcedata[game.player.force.name]
        forcedata.ingredient = "iron-plate"
        forcedata.consumers = get_consumers("iron-plate", game.player.force)
        
        start(global.forcedata[game.player.force.name])
    end
})