require("lib/core")

cflib.init_flags = {}
cflib.event_handlers = {}
cflib.global_event_handlers = {}

    -- TODO: try to unify these with event_handlers?
cflib.on_every_10th_tick_while_open = {}
cflib.on_researched_finished_while_open = {}

do
    -- TODO: utility lib?
    local function multi_index_set(table, indices, value)
        local t = table
        local num_indices = #indices

        for i=1,num_indices do
            local j = indices[i]
            if i == num_indices then
                t[j] = value
            else
                if not t[j] then
                    t[j] = {}
                end
                t = t[j]
            end
        end
    end

    local function multi_index_get(table, indices)
        local t = table
        local num_indices = #indices

        for i=1,num_indices do
            local j = indices[i]
            if not t[j] then
                return nil
            end
            t = t[j]
        end

        return t
    end

    local function is_initialized(player, name)
        local player_index = player.index

        local b = multi_index_get(cflib.init_flags, {player_index, name})
        return b or false
    end

    local function set_initialized(player, name)
        local player_index = player.index

        multi_index_set(cflib.init_flags, {player_index, name}, true)
    end

    local function set_not_initialized(player, name)
        local player_index = player.index

        multi_index_set(cflib.init_flags, {player_index, name}, false)
    end

    local function get_recipe_name_to_technology_map()
        local technologies_by_recipe = {}

        for _, tech in pairs(game.technology_prototypes) do
            local tech_name = tech.name

            for _, effect in pairs(tech.effects) do
                if effect.type == "unlock-recipe" then
                    local recipe_name = effect.recipe

                    if not technologies_by_recipe[recipe_name] then
                        technologies_by_recipe[recipe_name] = {tech}
                    else
                        table.insert(technologies_by_recipe[recipe_name], tech)
                    end
                end
            end
        end

        return technologies_by_recipe
    end

    get_research_depth_memo = {}
    local function get_research_depth(tech_prototype)
        local name = tech_prototype.name
        local memoized_depth = get_research_depth_memo[name]
        if memoized_depth then
            return memoized_depth
        else
            local depth = 0
            for _, parent in pairs(tech_prototype.prerequisites) do
                local parent_depth = get_research_depth(parent)
                depth = math.max(depth, parent_depth)
            end
            get_research_depth_memo[name] = depth
            return depth
        end
    end

    local function is_recipe_researched(player, recipe_prototype)
        local force = player.force
        local recipes = force.recipes
        return recipes[recipe_prototype.name] ~= nil
    end

    local function get_research_ordering_value(tech_prototype)
        if not tech_prototype then
            return 0.0
        end

        local science_level = #tech_prototype.research_unit_ingredients
        local depth = get_research_depth(tech_prototype)

        return science_level * 1000.0 + depth
    end

    local function get_entity_area(entity_prototype)
        local collision_box = entity_prototype.collision_box
        local width = collision_box.right_bottom.x - collision_box.left_top.x
        local height = collision_box.right_bottom.y - collision_box.left_top.y
        return width * height
    end

    local function get_composite_factory_ordering_value(entity, entity_item_recipe, processing_recipe, unlocked_by)
        -- The ordering is lexicographical over (research_level, research_depth, area).
        -- TODO: make it not use the floating point values "hack",
        --       instead we want the ordering value to be a tuple.
        local max_area = 1000.0 * 1000.0
        local base_value = get_research_ordering_value(unlocked_by)
        local value = base_value + (get_entity_area(entity) / max_area)
        return value
    end

    local function get_composite_generator_ordering_value(entity, entity_item_recipe, unlocked_by)
        local max_area = 1000.0 * 1000.0
        local base_value = get_research_ordering_value(unlocked_by)
        local value = base_value + (get_entity_area(entity) / max_area)
        return value
    end

    local function get_composite_factories_prototypes()
        local technologies_by_recipe = get_recipe_name_to_technology_map()

        local factories = {}

        for name, e in pairs(game.entity_prototypes) do
            if e.type == "assembling-machine" then
                if cflib.is_mod_prefixed_name(name) then
                    raw_name = cflib.unmake_composite_factory_name(name)
                    processing_recipe_name = cflib.make_processing_recipe_name(raw_name)

                    entity = e
                    processing_recipe = game.recipe_prototypes[processing_recipe_name]
                    entity_item = game.item_prototypes[name]
                    entity_item_recipe = game.recipe_prototypes[name]
                    searchable_names = {entity_item.name}
                    for _, p in pairs(processing_recipe.products) do
                        table.insert(searchable_names, p.name)
                    end

                    table.insert(factories, {
                        entity = entity,
                        processing_recipe = processing_recipe,
                        entity_item = entity_item,
                        entity_item_recipe = entity_item_recipe,
                        unlocked_by = technologies_by_recipe[entity_item_recipe.name],
                        ordering_value = get_composite_factory_ordering_value(entity, entity_item_recipe, processing_recipe, unlocked_by),
                        searchable_names = searchable_names
                    })
                end
            elseif e.type == "electric-energy-interface" then
                if cflib.is_mod_prefixed_name(name) then
                    entity = e
                    entity_item = game.item_prototypes[name]
                    entity_item_recipe = game.recipe_prototypes[name]

                    table.insert(factories, {
                        entity = entity,
                        entity_item = entity_item,
                        entity_item_recipe = entity_item_recipe,
                        unlocked_by = technologies_by_recipe[entity_item_recipe.name],
                        ordering_value = get_composite_generator_ordering_value(entity, entity_item_recipe, unlocked_by),
                        searchable_names = {entity_item.name}
                    })
                end
            end
        end

        table.sort(factories, function(lhs, rhs)
            return lhs.ordering_value < rhs.ordering_value
        end)

        return factories
    end

    -- TODO: move all stuff like that to cflib.*?
    local function add_gui_event_handler(event_type, player, gui_element_name, func)
        local player_index = player.index

        multi_index_set(cflib.event_handlers, { player_index, event_type, gui_element_name }, func)
    end

    -- TODO: move all stuff like that to cflib.*?
    local function add_global_gui_event_handler(event_type, func)
        handlers = multi_index_get(cflib.global_event_handlers, { event_type })
        if handlers == nil then
            multi_index_set(cflib.global_event_handlers, { event_type }, { func })
        else
            table.insert(handlers, func)
        end
    end

    local function get_gui_event_handler(event_type, event)
        if event.element == nil then
            return nil
        end

        local player_index = event.player_index
        local gui_element_name = event.element.name

        return multi_index_get(cflib.event_handlers, { player_index, event_type, gui_element_name })
    end

    local function get_global_gui_event_handlers(event_type)
        return multi_index_get(cflib.global_event_handlers, { event_type })
    end

    -- TODO: separate file for every gui, interface through cflib.* and global.*?
    local function setup_material_exchange_container_gui(player)
        local gui_name = cflib.make_gui_element_name("material-exchange-container-gui")
        local main_pane_name = cflib.make_gui_element_name("material-exchange-container-gui-main-pane")
        local exchange_table_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table")

        local gui_style_name = cflib.make_gui_style_name("material-exchange-container-gui")
        local exchange_table_row_style_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table")
        local exchange_table_header_style_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-header")
        local exchange_table_header_cell_style_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-header-cell")

        local hide_not_craftable_checkbox_name = cflib.make_gui_element_name("material-exchange-container-gui-hide-not-craftable")
        local hide_not_researched_checkbox_name = cflib.make_gui_element_name("material-exchange-container-gui-hide-not-researched")
        local search_textfield_name = cflib.make_gui_element_name("material-exchange-container-gui-search")

        local gui = player.gui.relative.add{
            type = "frame",
            name = gui_name,
            direction = "vertical",
            caption = "Material Exchange",
            anchor = {
                gui = defines.relative_gui_type.container_gui,
                position = defines.relative_gui_position.right,
                name = cflib.make_container_name("material-exchange-container")
            },
            style = gui_style_name
        }

        gui.add{
            type = "checkbox",
            name = hide_not_craftable_checkbox_name,
            caption = {"", "Hide not craftable"},
            state = false
        }

        gui.add{
            type = "checkbox",
            name = hide_not_researched_checkbox_name,
            caption = {"", "Hide not researched"},
            state = true
        }

        gui.add{
            type = "textfield",
            name = search_textfield_name
        }

        local exchange_table_header = gui.add{
            type = "flow",
            style = exchange_table_header_style_name,
            direction = "vertical"
        }

        local main_gui_pane = gui.add{
            type = "scroll-pane",
            name = main_pane_name,
            vertical_scroll_policy = "auto-and-reserve-space",
            horizontal_scroll_policy = "never"
        }

        local exchange_table = main_gui_pane.add{
            type = "flow",
            name = exchange_table_name,
            direction = "vertical"
        }

        local exchange_table_row = exchange_table_header.add{
            type = "table",
            name = exchange_table_row_name,
            -- Craft | Info | Tech icon | Building ingredients | Product summary | Energy required | Ingredient summary
            column_count = 7,
            draw_vertical_lines = true,
            draw_horizontal_lines = true,
            draw_horizontal_line_after_header = true,
            vertical_centering = false,
            style = exchange_table_row_style_name
        }

        exchange_table_row.add{
            type = "label",
            caption = {"", "Craft"},
            style = exchange_table_header_cell_style_name
        }

        exchange_table_row.add{
            type = "label",
            caption = {"", "Info"},
            style = exchange_table_header_cell_style_name
        }

        exchange_table_row.add{
            type = "label",
            caption = {"", "Tech"},
            style = exchange_table_header_cell_style_name
        }

        exchange_table_row.add{
            type = "label",
            caption = {"", "Building ingredients"},
            style = exchange_table_header_cell_style_name
        }

        exchange_table_row.add{
            type = "label",
            caption = {"", "Products"},
            style = exchange_table_header_cell_style_name
        }

        exchange_table_row.add{
            type = "label",
            caption = {"", "Time"},
            style = exchange_table_header_cell_style_name
        }

        exchange_table_row.add{
            type = "label",
            caption = {"", "Ingredients"},
            style = exchange_table_header_cell_style_name
        }

        local add_exchange_item = function(prototypes)
            local entity = prototypes.entity
            local name = entity.name
            local entity_item = prototypes.entity_item
            local entity_item_recipe = prototypes.entity_item_recipe
            local processing_recipe = prototypes.processing_recipe
            local unlocked_by = prototypes.unlocked_by

            local entity_collision_box = entity.collision_box
            local entity_width = math.floor(entity_collision_box.right_bottom.x - entity_collision_box.left_top.x + 0.5)
            local entity_height = math.floor(entity_collision_box.right_bottom.y - entity_collision_box.left_top.y + 0.5)

            local info_string = "Entity size: " .. tostring(entity_width) .. "x" .. tostring(entity_height)

            local unlocked_by_button_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-unlocked-by-" .. name)
            local exchange_table_row_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-row-" .. name)
            local exchange_table_row_line_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-row-line-" .. name)
            local craft_button_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-craft-" .. name)
            local building_ingredients_flow_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-flow-" .. name)
            local building_ingredients_panel_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-panel-" .. name)
            local building_ingredients_preview_panel_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-preview-panel-" .. name)
            local expand_button_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-expand-button-" .. name)
            local collapse_button_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-collapse-button-" .. name)

            local craft_button_style_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-craft")
            local info_button_style_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-info")
            local building_ingredients_flow_style_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-building-ingredients-flow")
            local ingredient_summary_panel_style_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-ingredient-summary-panel")
            local product_summary_panel_style_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-product-summary-panel")
            local energy_required_panel_style_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-energy-required-panel")
            local building_ingredients_preview_panel_style_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-building-ingredients-preview-panel")
            local building_ingredients_panel_style_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-building-ingredients-panel")
            local item_preview_style_normal_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-normal")
            local item_preview_dotdotdot_style_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-dotdotdot")
            local item_preview_expand_collapse_style_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-expand-collapse")

            local num_building_ingredients_columns = 5;
            local num_processing_recipe_ingredients_columns = 2;
            local num_processing_recipe_products_columns = 2;

            local exchange_table_row = exchange_table.add{
                type = "table",
                name = exchange_table_row_name,
                -- Craft | Info | Tech icon | Building ingredients | Product summary | Energy required | Ingredient summary
                column_count = 7,
                draw_vertical_lines = true,
                draw_horizontal_lines = true,
                draw_horizontal_line_after_header = true,
                vertical_centering = false,
                style = exchange_table_row_style_name
            }

            exchange_table.add{
                type = "line",
                name = exchange_table_row_line_name,
                direction = "horizontal"
            }

            exchange_table_row.add{
                type = "sprite-button",
                name = craft_button_name,
                sprite = cflib.craft_button_sprite_name,
                style = craft_button_style_name
            }

            exchange_table_row.add{
                type = "sprite-button",
                sprite = cflib.info_sprite_name,
                style = info_button_style_name,
                tooltip = {"", info_string},
                enabled = false
            }

            if unlocked_by then
                local tech = unlocked_by[1]

                exchange_table_row.add{
                    type = "sprite-button",
                    name = unlocked_by_button_name,
                    sprite = "technology/" .. tech.name,
                    style = item_preview_style_normal_name,
                    tooltip = {"", tech.localised_name},
                }
            else
                exchange_table_row.add{
                    type = "label",
                    caption = ""
                }
            end

            local building_ingredients_flow = exchange_table_row.add{
                type = "flow",
                direction = "vertical",
                name = building_ingredients_flow_name
            }

            local building_ingredients_preview_panel = building_ingredients_flow.add{
                type = "table",
                column_count = num_building_ingredients_columns,
                name = building_ingredients_preview_panel_name,
                style = building_ingredients_preview_panel_style_name
            }

            local building_ingredients_panel = building_ingredients_flow.add{
                type = "table",
                column_count = num_building_ingredients_columns,
                name = building_ingredients_panel_name,
                visible = false,
                style = building_ingredients_panel_style_name
            }

            do
                local num_items = 0
                for _, ingredient in pairs(entity_item_recipe.ingredients) do
                    num_items = num_items + 1
                end

                local i = 0

                for _, ingredient in pairs(entity_item_recipe.ingredients) do
                    local name = ingredient.name
                    local type = ingredient.type
                    local amount = ingredient.amount
                    local item = (type == "item" and game.item_prototypes[name]) or (type == "fluid" and game.fluid_prototypes[name])

                    local args = {
                        type = "sprite-button",
                        name = name,
                        sprite = type .. "/" .. name,
                        number = amount,
                        tooltip = {"", 0, "/", amount, " ", item.localised_name},
                        style = item_preview_style_normal_name
                    }

                    building_ingredients_panel.add(args)

                    if i < num_building_ingredients_columns - 1 or num_items <= num_building_ingredients_columns then
                        building_ingredients_preview_panel.add(args)
                    elseif i == num_building_ingredients_columns - 1 then
                        building_ingredients_preview_panel.add{
                            type = "button",
                            name = expand_button_name,
                            caption = "...",
                            tooltip = {"", "Expand"},
                            style = item_preview_expand_collapse_style_name
                        }
                    end

                    i = i + 1
                end

                building_ingredients_panel.add{
                    type = "button",
                    name = collapse_button_name,
                    caption = "^^",
                    tooltip = {"", "Collapse"},
                    style = item_preview_expand_collapse_style_name
                }
            end

            local product_summary_panel = exchange_table_row.add{
                type = "table",
                column_count = num_processing_recipe_products_columns,
                direction = "vertical",
                style = product_summary_panel_style_name
            }

            if entity.type == "electric-energy-interface" then
                local energy_produced_mw = entity.max_energy_production * 60.0 / 1000000.0

                product_summary_panel.add{
                    type = "sprite-button",
                    sprite = cflib.energy_indicator_sprite_name,
                    number = energy_produced_mw * 1000000,
                    tooltip = {"", energy_produced_mw, "MW"},
                    style = item_preview_style_normal_name
                }
            elseif entity.type == "assembling-machine" and processing_recipe then
                for _, product in pairs(processing_recipe.products) do
                    local name = product.name
                    local type = product.type
                    local amount = product.amount
                    local item = (type == "item" and game.item_prototypes[name]) or (type == "fluid" and game.fluid_prototypes[name])

                    product_summary_panel.add{
                        type = "sprite-button",
                        sprite = type .. "/" .. name,
                        number = amount,
                        tooltip = {"", amount, " ", item.localised_name},
                        style = item_preview_style_normal_name
                    }
                end
            end

            local energy_required_panel = exchange_table_row.add{
                type = "table",
                column_count = 1,
                style = energy_required_panel_style_name
            }

            if processing_recipe then
                energy_required_panel.add{
                    type = "sprite-button",
                    sprite = cflib.time_duration_indicator_sprite_name,
                    number = processing_recipe.energy,
                    style = item_preview_style_normal_name
                }
            end

            local ingredient_summary_panel = exchange_table_row.add{
                type = "table",
                column_count = num_processing_recipe_ingredients_columns,
                direction = "vertical",
                style = ingredient_summary_panel_style_name
            }

            if processing_recipe then
                local energy_usage_mw = entity.max_energy_usage * 60.0 / 1000000.0

                if energy_usage_mw > 0 then
                    ingredient_summary_panel.add{
                        type = "sprite-button",
                        sprite = cflib.energy_indicator_sprite_name,
                        number = energy_usage_mw * 1000000,
                        tooltip = {"", energy_usage_mw, "MW"},
                        style = item_preview_style_normal_name
                    }
                end

                for _, ingredient in pairs(processing_recipe.ingredients) do
                    local name = ingredient.name
                    local type = ingredient.type
                    local amount = ingredient.amount
                    local item = (type == "item" and game.item_prototypes[name]) or (type == "fluid" and game.fluid_prototypes[name])

                    ingredient_summary_panel.add{
                        type = "sprite-button",
                        sprite = type .. "/" .. name,
                        number = amount,
                        tooltip = {"", amount, " ", item.localised_name},
                        style = item_preview_style_normal_name
                    }
                end
            end
        end

        for _, p in ipairs(global.prototypes) do
            add_exchange_item(p)
        end

        return gui
    end

    local function is_craftable_from(recipe, item_stacks)
        for _, ingredient in pairs(recipe.ingredients) do
            local count = item_stacks[ingredient.name]
            if not count or count < ingredient.amount then
                return false
            end
        end

        return true
    end

    -- TODO: move to lib?
    local function craft_inside_inventory(player, inventory, recipe)
        for _, ingredient in pairs(recipe.ingredients) do
            inventory.remove({
                name = ingredient.name,
                count = ingredient.amount
            })
        end

        for _, product in pairs(recipe.products) do
            inventory.insert({
                name = product.name,
                count = product.amount
            })
        end
    end

    local function try_craft_inside_inventory(player, container, recipe_prototype)
        local force = player.force
        local recipe = force.recipes[recipe_prototype.name]
        if not recipe then
            return
        end

        local container_inventory = container.get_inventory(defines.inventory.item_main)
        local container_contents = container_inventory.get_contents()

        local num_products = #recipe.products

        if container_inventory.count_empty_stacks() < num_products then
            player.print("Not enough space in the container to craft.")
            return false
        end

        if not is_craftable_from(recipe, container_contents) then
            player.print("Not enough ingredients in the container to craft.")
            return false
        end

        if not is_recipe_researched(player, recipe_prototype) then
            player.print("Recipe is not researched.")
            return false
        end

        craft_inside_inventory(player, container_inventory, recipe)

        return true
    end

    local function setup_material_exchange_container_gui_events(player)
        local gui_name = cflib.make_gui_element_name("material-exchange-container-gui")
        local main_pane_name = cflib.make_gui_element_name("material-exchange-container-gui-main-pane")
        local exchange_table_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table")

        local gui = player.gui.relative[gui_name]
        local exchange_table = gui[main_pane_name][exchange_table_name]

        local add_events_for_exchange_item = function(prototypes)
            local entity = prototypes.entity
            local entity_item_recipe = prototypes.entity_item_recipe
            local name = entity.name
            local unlocked_by = prototypes.unlocked_by

            local exchange_table_row_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-row-" .. name)
            local craft_button_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-craft-" .. name)
            local unlocked_by_button_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-unlocked-by-" .. name)
            local building_ingredients_flow_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-flow-" .. name)
            local building_ingredients_panel_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-panel-" .. name)
            local building_ingredients_preview_panel_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-preview-panel-" .. name)
            local expand_button_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-expand-button-" .. name)
            local collapse_button_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-collapse-button-" .. name)

            local exchange_table_row = exchange_table[exchange_table_row_name]
            local unlocked_by_button = exchange_table_row[unlocked_by_button_name]
            local building_ingredients_flow = exchange_table_row[building_ingredients_flow_name]
            local building_ingredients_preview_panel = building_ingredients_flow[building_ingredients_preview_panel_name]
            local building_ingredients_panel = building_ingredients_flow[building_ingredients_panel_name]

            if unlocked_by then
                local tech = unlocked_by[1]

                add_gui_event_handler(defines.events.on_gui_click, player, unlocked_by_button_name, function(event)
                    player.open_technology_gui(tech)
                end)
            end

            add_gui_event_handler(defines.events.on_gui_click, player, craft_button_name, function(event)
                local opened_entity = player.opened
                -- TODO: this should always point to the container but we might add some assertions in the future
                try_craft_inside_inventory(player, opened_entity, entity_item_recipe)
            end)

            add_gui_event_handler(defines.events.on_gui_click, player, expand_button_name, function(event)
                building_ingredients_preview_panel.visible = false
                building_ingredients_panel.visible = true
            end)

            add_gui_event_handler(defines.events.on_gui_click, player, collapse_button_name, function(event)
                building_ingredients_preview_panel.visible = true
                building_ingredients_panel.visible = false
            end)
        end

        for _, p in ipairs(global.prototypes) do
            add_events_for_exchange_item(p)
        end
    end

    -- TODO: move to lib?
    local function are_tables_equal(a, b)
        local count = 0

        for _ in pairs(a) do count = count + 1 end
        for _ in pairs(b) do count = count - 1 end

        if count ~= 0 then
            return false
        end

        for k, v in pairs(a) do
            if v ~= b[k] then
                return false
            end
        end

        return true
    end

    local function is_technology_researched(player, technology)
        local force = player.force
        local technologies = force.technologies

        return technologies[technology.name].researched
    end

    local function can_technology_be_researched(player, technology)
        local force = player.force
        local technologies = force.technologies

        for _, prerequisite in pairs(technology.prerequisites) do
            if not technologies[prerequisite.name].researched then
                return false
            end
        end

        return true
    end

    local function any_contains(names, text)
        for _, name in pairs(names) do
            if string.find(name, text, 1, true) then
                return true
            end
        end

        return false
    end

    local function update_material_exchange_container_gui(gui, container, player)
        local prev_container_contents_path = { player.index, "material_exchange_container", "prev_container_contents" }
        local prev_container_contents = multi_index_get(global, prev_container_contents_path)

        local prev_filters_path = { player.index, "material_exchange_container", "prev_filters" }
        local prev_filters = multi_index_get(global, prev_filters_path)

        local hide_not_craftable_checkbox_name = cflib.make_gui_element_name("material-exchange-container-gui-hide-not-craftable")
        local hide_not_researched_checkbox_name = cflib.make_gui_element_name("material-exchange-container-gui-hide-not-researched")
        local search_textfield_name = cflib.make_gui_element_name("material-exchange-container-gui-search")

        local hide_not_craftable_checkbox = gui[hide_not_craftable_checkbox_name]
        local hide_not_researched_checkbox = gui[hide_not_researched_checkbox_name]
        local search_textfield = gui[search_textfield_name]

        local container_inventory = container.get_inventory(defines.inventory.item_main)
        local container_contents = container_inventory.get_contents()

        local filters = {
            hide_not_craftable = hide_not_craftable_checkbox.state,
            hide_not_researched = hide_not_researched_checkbox.state,
            text_contains = search_textfield.text
        }

        -- Always ensure that events work here because this is the place that's reached
        -- when the player is looking inside the inventory, so it's the best place
        -- to do this check.
        if not is_initialized(player, "material-exchange-container-gui-events") then
            setup_material_exchange_container_gui_events(player)
            set_initialized(player, "material-exchange-container-gui-events")
        end

        local no_update_needed = true
        no_update_needed = no_update_needed and prev_container_contents
        no_update_needed = no_update_needed and are_tables_equal(prev_container_contents, container_contents)
        no_update_needed = no_update_needed and prev_filters
        no_update_needed = no_update_needed and are_tables_equal(prev_filters, filters)
        if no_update_needed then
            return
        end

        multi_index_set(global, prev_container_contents_path, container_contents)
        multi_index_set(global, prev_filters_path, filters)

        local main_pane_name = cflib.make_gui_element_name("material-exchange-container-gui-main-pane")
        local exchange_table_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table")

        local exchange_table = gui[main_pane_name][exchange_table_name]

        local hide_not_craftable = filters.hide_not_craftable
        local hide_not_researched = filters.hide_not_researched

        local update_exchange_item = function(prototypes)
            local entity = prototypes.entity
            local entity_item_recipe = prototypes.entity_item_recipe
            local name = entity.name
            local unlocked_by = prototypes.unlocked_by
            local processing_recipe = prototypes.processing_recipe
            local searchable_names = prototypes.searchable_names

            local unlocked_by_button_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-unlocked-by-" .. name)
            local exchange_table_row_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-row-" .. name)
            local exchange_table_row_line_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-row-line-" .. name)
            local craft_button_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-craft-" .. name)
            local building_ingredients_flow_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-flow-" .. name)
            local building_ingredients_panel_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-panel-" .. name)
            local building_ingredients_preview_panel_name = cflib.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-preview-panel-" .. name)

            local item_preview_style_green_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-green")
            local item_preview_style_yellow_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-yellow")
            local item_preview_style_red_name = cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-red")

            local exchange_table_row = exchange_table[exchange_table_row_name]
            local exchange_table_row_line = exchange_table[exchange_table_row_line_name]
            local craft_button = exchange_table_row[craft_button_name]
            local building_ingredients_flow = exchange_table_row[building_ingredients_flow_name]
            local building_ingredients_preview_panel = building_ingredients_flow[building_ingredients_preview_panel_name]
            local building_ingredients_panel = building_ingredients_flow[building_ingredients_panel_name]

            local do_hide = (filters.text_contains and not any_contains(searchable_names, filters.text_contains))

            local is_craftable = true
            local is_researched = true
            if not do_hide then
                if unlocked_by then
                    is_researched = is_technology_researched(player, unlocked_by[1])

                    local unlocked_by_button = exchange_table_row[unlocked_by_button_name]

                    if is_researched then
                        unlocked_by_button.style = item_preview_style_green_name
                    elseif not hide_not_researched and can_technology_be_researched(player, unlocked_by[1]) then
                        unlocked_by_button.style = item_preview_style_yellow_name
                    elseif not hide_not_researched then
                        unlocked_by_button.style = item_preview_style_red_name
                    end
                end

                local update_sprite_button = function(e)
                    local ingredient_name = e.name
                    local required_amount = e.number
                    local owned_amount = container_contents[ingredient_name] or 0
                    local style = item_preview_style_green_name
                    local can_afford = owned_amount >= required_amount
                    if not can_afford then
                        style = item_preview_style_red_name
                    end

                    e.tooltip = {"", owned_amount, "/", required_amount, " ", e.tooltip[6]}
                    e.style = style

                    return can_afford
                end

                local num_preview_ingredients = 0
                for _, e in pairs(building_ingredients_preview_panel.children) do
                    if e.type == "sprite-button" then
                        update_sprite_button(e)
                        num_preview_ingredients = num_preview_ingredients + 1
                    end
                end

                local num_total_ingredients = 0
                for _, e in pairs(building_ingredients_panel.children) do
                    if e.type == "sprite-button" then
                        is_craftable = update_sprite_button(e) and is_craftable
                        num_total_ingredients = num_total_ingredients + 1
                    end
                end

                craft_button.enabled = is_craftable and is_researched
            end

            do_hide = do_hide or (hide_not_craftable and not is_craftable) or (hide_not_researched and not is_researched)

            exchange_table_row.visible = not do_hide
            exchange_table_row_line.visible = not do_hide
        end

        for _, p in ipairs(global.prototypes) do
            update_exchange_item(p)
        end
    end

    local function get_material_exchange_container_gui(player)
        local material_exchange_container_gui_name = cflib.make_gui_element_name("material-exchange-container-gui")

        -- TODO: maybe stup guis for each player when they connect? would be easier to reset on config change.
        local gui = player.gui.relative[material_exchange_container_gui_name] or setup_material_exchange_container_gui(player)

        return gui
    end

    local function setup_material_exchange_container_gui_global_events()
        cflib.on_every_10th_tick_while_open[cflib.make_gui_element_name("material-exchange-container-gui")] = function(player, opened_gui)
            local gui = opened_gui.gui
            local entity = opened_gui.entity
            update_material_exchange_container_gui(gui, entity, player)
        end

        cflib.on_researched_finished_while_open[cflib.make_gui_element_name("material-exchange-container-gui")] = function(player, opened_gui)
            local gui = opened_gui.gui
            local entity = opened_gui.entity
            update_material_exchange_container_gui(gui, entity, player)
        end

        add_global_gui_event_handler(defines.events.on_gui_opened, function(event)
            if not event.gui_type == defines.gui_type.entity then
                return
            end

            if event.entity == nil then
                return
            end

            if event.entity.type ~= "container" then
                return
            end

            if event.entity.name ~= cflib.make_container_name("material-exchange-container") then
                return
            end

            local player = game.get_player(event.player_index)
            local gui = get_material_exchange_container_gui(player)
            update_material_exchange_container_gui(gui, event.entity, player)

            multi_index_set(global, { player.index, "opened_guis" }, { gui = gui, entity = event.entity })
        end)

        add_global_gui_event_handler(defines.events.on_gui_closed, function(event)
            if not event.gui_type == defines.gui_type.entity then
                return
            end

            if event.entity == nil then
                return
            end

            if event.entity.type ~= "container" then
                return
            end

            if event.entity.name ~= cflib.make_container_name("material-exchange-container") then
                return
            end

            local player = game.get_player(event.player_index)
            local gui = get_material_exchange_container_gui(player)

            local path = { player.index, "opened_guis" }
            local opened_gui = multi_index_get(global, path)
            if opened_gui and opened_gui.gui.name == gui.name then
                multi_index_set(global, path, nil)
            end
        end)
    end

    local function setup_cache()
        global.prototypes = get_composite_factories_prototypes()
    end

    local function reset_material_exchange_container_gui()
        local material_exchange_container_gui_name = cflib.make_gui_element_name("material-exchange-container-gui")

        for _, player in pairs(game.players) do
            -- Needed for rewiring to the new gui
            local path = { player.index, "opened_guis" }
            local opened_gui = multi_index_get(global, path)
            local opened_gui_name = opened_gui and opened_gui.gui.name

            if player.gui.relative[material_exchange_container_gui_name] then
                player.gui.relative[material_exchange_container_gui_name].destroy()
            end
            set_not_initialized(player, "material-exchange-container-gui-events")

            -- Reset the previous state so that the gui is updated for the first time.
            local prev_container_contents_path = { player.index, "material_exchange_container", "prev_container_contents" }
            local prev_filters_path = { player.index, "material_exchange_container", "prev_filters" }
            multi_index_set(global, prev_container_contents_path, nil)
            multi_index_set(global, prev_filters_path, nil)

            -- Rewire the gui.
            if opened_gui_name and opened_gui_name == material_exchange_container_gui_name then
                local gui = get_material_exchange_container_gui(player)

                -- Update the gui because it was recreated.
                opened_gui.gui = gui
                update_material_exchange_container_gui(gui, opened_gui.entity, player)
            end
        end
    end

    local function reset_guis()
        reset_material_exchange_container_gui()
    end

    local function reinitialize()
        setup_cache()
        reset_guis()
    end

    script.on_init(function()
        reinitialize()
    end)

    script.on_configuration_changed(function(event)
        reinitialize()
    end)

    local function handle_gui_event(event_type, event)
        local global_handlers = get_global_gui_event_handlers(event_type)
        if global_handlers then
            for _, global_handler in ipairs(global_handlers) do
                global_handler(event)
            end
        end

        local handler = get_gui_event_handler(event_type, event)
        if handler then
            handler(event)
        end
    end

    script.on_event(defines.events.on_gui_click, function(event)
        handle_gui_event(defines.events.on_gui_click, event)
    end)

    script.on_event(defines.events.on_gui_opened, function(event)
        handle_gui_event(defines.events.on_gui_opened, event)
    end)

    script.on_event(defines.events.on_gui_closed, function(event)
        handle_gui_event(defines.events.on_gui_closed, event)
    end)

    local function on_something_while_open(event, something)
        for _, player in pairs(game.players) do
            local player_index = player.index

            local path = { player_index, "opened_guis" }
            local opened_gui = multi_index_get(global, path)
            if opened_gui then
                if opened_gui.entity.valid then
                    local func = something[opened_gui.gui.name]
                    if func then
                        func(player, opened_gui)
                    end
                else
                    multi_index_set(global, path, nil)
                end
            end
        end
    end

    local function setup_entity_counter_tool_gui_events(player)
        add_gui_event_handler(defines.events.on_gui_click, player, "composite_factories_entity_counter_tool_close_button", function(e)
            local frame = multi_index_get(global, { e.player_index, "entity_counter_tool_frame" })
            if frame and frame.valid then
                frame.destroy()
                multi_index_set(global, { e.player_index, "entity_counter_tool_frame" }, nil)
                game.get_player(e.player_index).opened = nil
            end
        end)

        add_gui_event_handler(defines.events.on_gui_closed, player, "composite_factories_entity_counter_tool_frame", function(e)
            local frame = multi_index_get(global, { e.player_index, "entity_counter_tool_frame" })
            if frame and frame.valid then
                frame.destroy()
                multi_index_set(global, { e.player_index, "entity_counter_tool_frame" }, nil)
                game.get_player(e.player_index).opened = nil
            end
        end)
    end

    local function run_entity_counter_tool(e, is_alt_pressed)
        local counts = {}

        if #e.entities == 0 then
            return
        end

        for _, entity in pairs(e.entities) do
            if entity.valid then
                local name = entity.name
                if name == "entity-ghost" then
                    name = entity.ghost_name
                end
                counts[name] = (counts[name] or 0) + 1

                local module_inventory = entity.get_module_inventory()
                if module_inventory and module_inventory.valid then
                    for name, count in pairs(module_inventory.get_contents()) do
                        counts[name] = (counts[name] or 0) + count
                    end
                end
            end
        end

        if table_size(counts) == 0 then
            return
        end

        local composite_factory_type = ""
        if is_alt_pressed then
            composite_factory_type = "generator"
            composite_factory_creation_func = "cflib.add_composite_generator"
        else
            composite_factory_type = "assembler"
            composite_factory_creation_func = "cflib.add_composite_factory"
        end

        selection_width = e.area.right_bottom.x - e.area.left_top.x
        selection_height = e.area.right_bottom.y - e.area.left_top.y
        selection_area = selection_width * selection_height

        local output_lines = {
            "-- This is a composite factory definition template.",
            "-- You will need some basic mod creation knowledge to use this.",
            "-- To create a composite factory one must make their own mod that",
            "-- contains the definitions of the desired composite factories.",
            "-- If you're unsure how to make such a mod check then out how it's done in",
            "-- https://github.com/Sopel97/composite_factories_pyblock",
            "-- Inspect the code in the repository above to learn how to define",
            "-- composite factories. You can use the code from that repository",
            "-- as a skeleton for your mod, just make sure to remove the existing pyblock content.",
            composite_factory_creation_func .. "{",
            "    name = \"\", -- the name of the building/entity",
            "    size = " .. math.ceil(math.sqrt(selection_area)) .. ",",
            "    unlocked_by = cflib.base_technology, -- default tech",
            "    subgroup = \"\", -- your collection (mod) should define an item subgroup to use here",
            "    roof_tile_cost = 1.0, -- default",
            "    wall_tile_cost = 10.0, -- default",
            "    roof_material = \"steel-plate\", -- default",
            "    wall_material = \"stone-brick\", -- default",
        }

        table.insert(output_lines, "    ingredients = {}, -- fill yourself")

        if composite_factory_type == "assembler" then
            table.insert(output_lines, "    results = {}, -- fill yourself")
            table.insert(output_lines, "    energy_required = 1.0, -- default 1s crafting time")
            table.insert(output_lines, "    energy_usage = \"0MW\", -- fill yourself, must be at least 1W")
            table.insert(output_lines, "    drain = \"0MW\", -- fill yourself")
            table.insert(output_lines, "    emissions_per_minute = 0, -- fill yourself")
        elseif composite_factory_type == "generator" then
            table.insert(output_lines, "    results = {}, -- fill yourself or leave empty, does not support liquids")
            table.insert(output_lines, "    usage_priority = \"primary-output\", -- can be primary-output, secondary-output, or tertiary")
            table.insert(output_lines, "    energy_production_per_craft = \"0MJ\", -- fill yourself, only used if ingredients are specified, if you set energy_required above one, multiply by it if you want a specific amount constantly")
            table.insert(output_lines, "    energy_required = 1.0, -- fill yourself, only used if ingredients are specified")
            table.insert(output_lines, "    energy_production = \"0MW\", -- fill yourself, only used if ingredients are not specified")
            table.insert(output_lines, "    buffer_capacity = \"0MJ\", -- fill yourself, only used if ingredients are not specified")
            table.insert(output_lines, "    emissions_per_minute = 0, -- fill yourself")
        else
            return
        end

        table.insert(output_lines, "    constituent_buildings = {")

        for name, count in pairs(counts) do
            table.insert(output_lines, "        {\"" .. name .. "\", " .. count .. "},")
        end
        table.insert(output_lines, "    },")
        table.insert(output_lines, "}")

        local player = game.get_player(e.player_index)
        if not is_initialized(player, "entity-counter-tool-gui-events") then
            setup_entity_counter_tool_gui_events(player)
            set_initialized(player, "entity-counter-tool-gui-events")
        end

        local frame = multi_index_get(global, { e.player_index, "entity_counter_tool_frame" })
        if not frame or not frame.valid then
            frame = player.gui.screen.add({
                type = "frame",
                name = "composite_factories_entity_counter_tool_frame",
                direction = "vertical",
                caption = "Composite factory definition template",
            })

            frame.add({
                type = "sprite-button",
                name = "composite_factories_entity_counter_tool_close_button",
                style = "frame_action_button",
                sprite = "utility/close_white",
                hovered_sprite = "utility/close_black",
                clicked_sprite = "utility/close_black",
            })

            local textbox = frame.add({ type = "text-box", name = "textbox" })
            textbox.style.width = 640
            textbox.style.height = 480

            frame.force_auto_center()

            multi_index_set(global, { e.player_index, "entity_counter_tool_frame" }, frame)

            player.opened = frame
        end

        local textbox = frame.textbox
        textbox.text = table.concat(output_lines, "\n")
        textbox.focus()
        player.clear_cursor()
    end

    local function setup_entity_counter_tool_global_events()
        script.on_event({ defines.events.on_player_selected_area }, function(e)
            if e.item ~= "composite-factory-entity-counter-tool" then
                return
            end

            run_entity_counter_tool(e, false)
        end)

        script.on_event({ defines.events.on_player_alt_selected_area }, function(e)
            if e.item ~= "composite-factory-entity-counter-tool" then
                return
            end

            run_entity_counter_tool(e, true)
        end)

        script.on_event({ defines.events.on_player_cursor_stack_changed }, function(e)
            local player = game.get_player(e.player_index)
            local held_item_stack = player.cursor_stack

            if held_item_stack == nil then
                return
            end

            if held_item_stack.valid_for_read and held_item_stack.name == "composite-factory-entity-counter-tool" then
                player.cursor_stack.label = "Normal mode: Assembler. Shift mode: Generator."
            end
        end)
    end

    script.on_nth_tick(10, function(event)
        on_something_while_open(event, cflib.on_every_10th_tick_while_open)
    end)

    script.on_event(defines.events.on_research_finished, function(event)
        on_something_while_open(event, cflib.on_research_finished)
    end)

    setup_material_exchange_container_gui_global_events()

    setup_entity_counter_tool_global_events()
end
