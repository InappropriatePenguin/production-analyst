---@alias EntityCreationData on_built_entity|on_robot_built_entity|on_entity_cloned|script_raised_built|script_raised_revive
---@alias EntityRemovalData on_entity_died|on_player_mined_entity|on_robot_mined_entity|script_raised_destroy

---Contains data pertaining to a force.
---@class ForceData
  ---@field name string Force name
  ---@field luaforce LuaForce Reference to force LuaObject
  ---@field playerdata table<uint, PlayerData> Table of Playerdata objects that belong to force
  ---@field crafting_entities table<uint, table<uint, LuaEntity>> Table of crafting entities, indexed by surface index and unit number
  ---@field queue Task[] Array of tasks, ordered by position in queue
  ---@field history Task[] Array of tasks performed by force
  ---@field is_sampling boolean Is force activley sampling?

---Contains data pertaining to a player.
---@class PlayerData
  ---@field luaplayer LuaPlayer Reference to player LuaObject
  ---@field force_name string Force name
  ---@field run_time uint Runtime set in gui for future runs, in seconds
  ---@field is_gui_open boolean Is player gui open?
  ---@field gui table<string, LuaGuiElement> Main window gui references
    ---@field queue_selected_id? string ID of selected queue entry if any
    ---@field history_selected_id? string ID of selected history entry if any

---Contains data pertaining to a task.
---@class Task
  ---@field consumers table<uint, Consumer> Table of entities that consu
  ---@field id string Unique identifier
  ---@field ingredient IngredientInfo Item or fluid being evaluated
  ---@field player_index uint Index of player who created this task
  ---@field recipes table<string, Recipe> Table of recipes, indexed by recipe name
  ---@field run_time uint Duration of run in seconds
    ---@field start_tick? uint Tick in which run was started, if any
    ---@field end_tick? uint Tick in which run was ended, if any

---Contains data pertaining to an ingredient.
---@class IngredientInfo
  ---@field type string Can be item or fluid
  ---@field name string Ingredient name

---Contains data pertaining to a recipe.
---@class Recipe
  ---@field luarecipe LuaRecipe
  ---@field recipe_name string Recipe name
  ---@field amount uint Amount of ingredient consumed by recipe
  ---@field energy uint Energy used by recipe
  ---@field machines uint Number of crafting entities set to recipe
  ---@field crafts uint Number of times recipe was completed
  ---@field max_crafts uint Maximum number of times recipe could have been completed
  ---@field consumed uint Amount of ingredient directly consumed by recipe

---Contains data pertaining to a consuming crafting entity.
---@class Consumer
  ---@field luaentity LuaEntity Reference to entity LuaObject
  ---@field recipe_name string Recipe name that entity is set to
  ---@field amount uint Amount of ingredient consumed by entity per craft
  ---@field crafting_speed float Crafting speed of entity
  ---@field multiplier uint Relevant for rocket silos
  ---@field start uint Value of products_finished at the beginning of sampling
  ---@field count uint Number of crafts completed by consumer
