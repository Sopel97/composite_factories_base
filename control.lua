do
    local core = require("private/core")

    local cflib = {
        init_flags = {},
        event_handlers = {},

        -- TODO: try to unify these with event_handlers?
        on_every_10th_tick_while_open = {},
        on_researched_finished_while_open = {}
    }

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

    local function is_recipe_researched(player, recipe_prototype)
        local force = player.force
        local unlocked_recipes = force.recipes

        return unlocked_recipes[recipe_prototype.name] ~= nil
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

    local function get_composite_factories_prototypes()
        local technologies_by_recipe = get_recipe_name_to_technology_map()

        local factories = {}

        for name, e in pairs(game.entity_prototypes) do
            if e.type == "assembling-machine" then
                if core.is_mod_prefixed_name(name) then
                    raw_name = core.unmake_composite_factory_name(name)
                    processing_recipe_name = core.make_processing_recipe_name(raw_name)

                    entity = e
                    processing_recipe = game.recipe_prototypes[processing_recipe_name]
                    entity_item = game.item_prototypes[name]
                    entity_item_recipe = game.recipe_prototypes[name]
                    table.insert(factories, {
                        entity = entity,
                        processing_recipe = processing_recipe,
                        entity_item = entity_item,
                        entity_item_recipe = entity_item_recipe,
                        unlocked_by = technologies_by_recipe[entity_item_recipe.name]
                    })
                end
            elseif e.type == "electric-energy-interface" then
                if core.is_mod_prefixed_name(name) then
                    entity = e
                    entity_item = game.item_prototypes[name]
                    entity_item_recipe = game.recipe_prototypes[name]

                    table.insert(factories, {
                        entity = entity,
                        entity_item = entity_item,
                        entity_item_recipe = entity_item_recipe,
                        unlocked_by = technologies_by_recipe[entity_item_recipe.name]
                    })
                end
            end
        end

        return factories
    end

    -- TODO: move all stuff like that to cflib.*?
    local function add_gui_event_handler(event_type, player, gui_element_name, func)
        local player_index = player.index

        multi_index_set(cflib.event_handlers, {player_index, event_type, gui_element_name}, func)
    end

    local function get_gui_event_handler(event_type, event)
        local player_index = event.player_index
        local gui_element_name = event.element.name

        return multi_index_get(cflib.event_handlers, {player_index, event_type, gui_element_name})
    end

    -- TODO: separate file for every gui, interface through cflib.* and global.*?
    local function setup_material_exchange_container_gui(player)
        local gui_name = core.make_gui_element_name("material-exchange-container-gui")
        local main_pane_name = core.make_gui_element_name("material-exchange-container-gui-main-pane")
        local exchange_table_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table")

        local gui_style_name = core.make_gui_style_name("material-exchange-container-gui")
        local exchange_table_row_style_name = core.make_gui_style_name("material-exchange-container-gui-exchange-table")

        local hide_not_craftable_checkbox_name = core.make_gui_element_name("material-exchange-container-gui-hide-not-craftable")
        local hide_not_researched_checkbox_name = core.make_gui_element_name("material-exchange-container-gui-hide-not-researched")

        local gui = player.gui.relative.add{
            type = "frame",
            name = gui_name,
            direction = "vertical",
            caption = "Material Exchange",
            anchor = {
                gui = defines.relative_gui_type.container_gui,
                position = defines.relative_gui_position.right,
                name = core.make_container_name("material-exchange-container")
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

        local add_exchange_item = function(prototypes)
            local entity = prototypes.entity
            local name = entity.name
            local entity_item = prototypes.entity_item
            local entity_item_recipe = prototypes.entity_item_recipe
            local processing_recipe = prototypes.processing_recipe
            local unlocked_by = prototypes.unlocked_by

            local unlocked_by_panel_name = core.make_gui_style_name("material-exchange-container-gui-exchange-unlocked-by-" .. name)
            local exchange_table_row_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-row-" .. name)
            local exchange_table_row_line_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-row-line-" .. name)
            local craft_button_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-craft-" .. name)
            local building_ingredients_flow_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-flow-" .. name)
            local building_ingredients_panel_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-panel-" .. name)
            local building_ingredients_preview_panel_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-preview-panel-" .. name)
            local toggle_visibility_button_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-toggle-visibility-button-" .. name)

            local craft_button_style_name = core.make_gui_style_name("material-exchange-container-gui-exchange-table-craft")
            local toggle_visibility_button_style_name = core.make_gui_style_name("material-exchange-container-gui-exchange-table-toggle-visibility-button")
            local building_ingredients_flow_style_name = core.make_gui_style_name("material-exchange-container-gui-exchange-table-building-ingredients-flow")
            local ingredient_summary_panel_style_name = core.make_gui_style_name("material-exchange-container-gui-exchange-table-ingredient-summary-panel")
            local product_summary_panel_style_name = core.make_gui_style_name("material-exchange-container-gui-exchange-table-product-summary-panel")
            local energy_required_panel_style_name = core.make_gui_style_name("material-exchange-container-gui-exchange-table-energy-required-panel")
            local building_ingredients_preview_panel_style_name = core.make_gui_style_name("material-exchange-container-gui-exchange-table-building-ingredients-preview-panel")
            local building_ingredients_panel_style_name = core.make_gui_style_name("material-exchange-container-gui-exchange-table-building-ingredients-panel")
            local item_preview_style_normal_name = core.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-normal")

            local num_building_ingredients_columns = 5;
            local num_processing_recipe_ingredients_columns = 2;
            local num_processing_recipe_products_columns = 2;

            local exchange_table_row = exchange_table.add{
                type = "table",
                name = exchange_table_row_name,
                -- Craft | Show/hide button | Tech icon | Icon/hidden building ingredients | Product summary | Energy required | Ingredient summary
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
                type = "button",
                name = craft_button_name,
                caption = "Craft 1",
                style = craft_button_style_name
            }

            local toggle_visibility_button = exchange_table_row.add{
                type = "button",
                name = toggle_visibility_button_name,
                caption = "S",
                style = toggle_visibility_button_style_name
            }

            if unlocked_by then
                local tech = unlocked_by[1]

                exchange_table_row.add{
                    type = "sprite-button",
                    name = unlocked_by_panel_name,
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

                    if i < num_building_ingredients_columns - 1 then
                        building_ingredients_preview_panel.add(args)
                    elseif i == num_building_ingredients_columns - 1 then
                        building_ingredients_preview_panel.add{
                            type = "label",
                            caption = "   ...   "
                        }
                    end

                    i = i + 1
                end
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
                    sprite = core.energy_indicator_sprite_name,
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
                    sprite = core.time_duration_indicator_sprite_name,
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

        for _, p in pairs(global.prototypes) do
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
        local gui_name = core.make_gui_element_name("material-exchange-container-gui")
        local main_pane_name = core.make_gui_element_name("material-exchange-container-gui-main-pane")
        local exchange_table_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table")

        local gui = player.gui.relative[gui_name]
        local exchange_table = gui[main_pane_name][exchange_table_name]

        local add_events_for_exchange_item = function(prototypes)
            local entity = prototypes.entity
            local entity_item_recipe = prototypes.entity_item_recipe
            local name = entity.name

            local exchange_table_row_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-row-" .. name)
            local craft_button_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-craft-" .. name)
            local building_ingredients_flow_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-flow-" .. name)
            local building_ingredients_panel_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-panel-" .. name)
            local building_ingredients_preview_panel_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-preview-panel-" .. name)
            local toggle_visibility_button_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-toggle-visibility-button-" .. name)

            local exchange_table_row = exchange_table[exchange_table_row_name]
            local toggle_visibility_button = exchange_table_row[toggle_visibility_button_name]
            local building_ingredients_flow = exchange_table_row[building_ingredients_flow_name]
            local building_ingredients_preview_panel = building_ingredients_flow[building_ingredients_preview_panel_name]
            local building_ingredients_panel = building_ingredients_flow[building_ingredients_panel_name]

            add_gui_event_handler(defines.events.on_gui_click, player, craft_button_name, function(event)
                local opened_entity = player.opened
                -- TODO: this should always point to the container but we might add some assertions in the future
                try_craft_inside_inventory(player, opened_entity, entity_item_recipe)
            end)

            add_gui_event_handler(defines.events.on_gui_click, player, toggle_visibility_button_name, function(event)
                if toggle_visibility_button.caption == "S" then
                    toggle_visibility_button.caption = "H"
                else
                    toggle_visibility_button.caption = "S"
                end

                building_ingredients_preview_panel.visible = not building_ingredients_preview_panel.visible
                building_ingredients_panel.visible = not building_ingredients_panel.visible
            end)
        end

        for _, p in pairs(global.prototypes) do
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

    local function can_be_researched(player, technology)
        local force = player.force
        local technologies = force.technologies

        for _, prerequisite in pairs(technology.prerequisites) do
            if not technologies[prerequisite] then
                return false
            end
        end

        return true
    end

    local function update_material_exchange_container_gui(gui, container, player)
        local prev_container_contents_path = {"material_exchange_container", "prev_container_contents", player.index}
        local prev_container_contents = multi_index_get(global, prev_container_contents_path)

        local prev_filters_path = {"material_exchange_container", "prev_filters", player.index}
        local prev_filters = multi_index_get(global, prev_filters_path)

        local hide_not_craftable_checkbox_name = core.make_gui_element_name("material-exchange-container-gui-hide-not-craftable")
        local hide_not_researched_checkbox_name = core.make_gui_element_name("material-exchange-container-gui-hide-not-researched")

        local hide_not_craftable_checkbox = gui[hide_not_craftable_checkbox_name]
        local hide_not_researched_checkbox = gui[hide_not_researched_checkbox_name]

        local container_inventory = container.get_inventory(defines.inventory.item_main)
        local container_contents = container_inventory.get_contents()

        local filters = {
            hide_not_craftable = hide_not_craftable_checkbox.state,
            hide_not_researched = hide_not_researched_checkbox.state
        }

        if prev_container_contents and are_tables_equal(prev_container_contents, container_contents) and prev_filters and are_tables_equal(prev_filters, filters) then
            return
        end

        multi_index_set(global, prev_container_contents_path, container_contents)
        multi_index_set(global, prev_filters_path, filters)

        local main_pane_name = core.make_gui_element_name("material-exchange-container-gui-main-pane")
        local exchange_table_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table")

        local exchange_table = gui[main_pane_name][exchange_table_name]

        local hide_not_craftable = filters.hide_not_craftable
        local hide_not_researched = filters.hide_not_researched

        local update_exchange_item = function(prototypes)
            local entity = prototypes.entity
            local entity_item_recipe = prototypes.entity_item_recipe
            local name = entity.name
            local unlocked_by = prototypes.unlocked_by

            local is_researched = is_recipe_researched(player, entity_item_recipe)

            local unlocked_by_panel_name = core.make_gui_style_name("material-exchange-container-gui-exchange-unlocked-by-" .. name)
            local exchange_table_row_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-row-" .. name)
            local exchange_table_row_line_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-row-line-" .. name)
            local craft_button_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-craft-" .. name)
            local building_ingredients_flow_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-flow-" .. name)
            local building_ingredients_panel_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-panel-" .. name)
            local building_ingredients_preview_panel_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-building-ingredients-preview-panel-" .. name)
            local toggle_visibility_button_name = core.make_gui_element_name("material-exchange-container-gui-exchange-table-toggle-visibility-button-" .. name)

            local item_preview_style_green_name = core.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-green")
            local item_preview_style_yellow_name = core.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-yellow")
            local item_preview_style_red_name = core.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-red")

            local exchange_table_row = exchange_table[exchange_table_row_name]
            local exchange_table_row_line = exchange_table[exchange_table_row_line_name]
            local toggle_visibility_button = exchange_table_row[toggle_visibility_button_name]
            local building_ingredients_flow = exchange_table_row[building_ingredients_flow_name]
            local building_ingredients_preview_panel = building_ingredients_flow[building_ingredients_preview_panel_name]
            local building_ingredients_panel = building_ingredients_flow[building_ingredients_panel_name]

            if unlocked_by then
                local unlocked_by_panel = exchange_table_row[unlocked_by_panel_name]

                if is_researched then
                    unlocked_by_panel.style = item_preview_style_green_name
                elseif not hide_not_researched and can_be_researched(player, unlocked_by[1]) then
                    unlocked_by_panel.style = item_preview_style_yellow_name
                elseif not hide_not_researched then
                    unlocked_by_panel.style = item_preview_style_red_name
                end
            end

            local update_sprite_button = function(e)
                local ingredient_name = e.name
                local required_amount = e.number
                local owned_amount = container_contents[ingredient_name] or 0
                local style = item_preview_style_green_name
                if owned_amount < required_amount then
                    style = item_preview_style_red_name
                end

                e.tooltip = {"", owned_amount, "/", required_amount, " ", e.tooltip[6]}
                e.style = style
            end

            for _, e in pairs(building_ingredients_preview_panel.children) do
                if e.type == "sprite-button" then
                    update_sprite_button(e)
                end
            end

            local is_craftable = true
            for _, e in pairs(building_ingredients_panel.children) do
                if e.type == "sprite-button" then
                    is_craftable = update_sprite_button(e) and is_craftable
                end
            end

            local do_hide = (hide_not_craftable and not is_craftable) or (hide_not_researched and not is_researched)
            exchange_table_row.visible = not do_hide
            exchange_table_row_line.visible = not do_hide
        end

        for _, p in pairs(global.prototypes) do
            update_exchange_item(p)
        end
    end

    local function setup_material_exchange_container_gui_global_events()
        cflib.on_every_10th_tick_while_open[core.make_gui_element_name("material-exchange-container-gui")] = function(player, opened_gui)
            local gui = opened_gui.gui
            local entity = opened_gui.entity
            update_material_exchange_container_gui(gui, entity, player)
        end

        cflib.on_researched_finished_while_open[core.make_gui_element_name("material-exchange-container-gui")] = function(player, opened_gui)
            local gui = opened_gui.gui
            local entity = opened_gui.entity
            update_material_exchange_container_gui(gui, entity, player)
        end
    end

    local function get_material_exchange_container_gui(player)
        local material_exchange_container_gui_name = core.make_gui_element_name("material-exchange-container-gui")

        -- TODO: maybe stup guis for each player when they connect? would be easier to reset on config change.
        local gui = player.gui.relative[material_exchange_container_gui_name] or setup_material_exchange_container_gui(player)

        if not is_initialized(player, "material-exchange-container-gui-events") then
            setup_material_exchange_container_gui_events(player)
            set_initialized(player, "material-exchange-container-gui-events")
        end

        return gui
    end

    local function setup_cache()
        global.prototypes = get_composite_factories_prototypes()
    end

    local function reset_material_exchange_container_gui()
        local material_exchange_container_gui_name = core.make_gui_element_name("material-exchange-container-gui")

        for _, player in pairs(game.players) do
            if player.gui.relative[material_exchange_container_gui_name] then
                player.gui.relative[material_exchange_container_gui_name].destroy()
            end
            set_not_initialized(player, "material-exchange-container-gui-events")
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

    script.on_event(defines.events.on_gui_click, function(event)
        local handler = get_gui_event_handler(defines.events.on_gui_click, event)
        if handler then
            handler(event)
        end
    end)

    script.on_event(defines.events.on_gui_opened, function(event)
        if not event.gui_type == defines.gui_type.entity then
            return
        end

        if event.entity == nil then
            return
        end

        if event.entity.type ~= "container" then
            return
        end

        if event.entity.name ~= core.make_container_name("material-exchange-container") then
            return
        end

        local player = game.get_player(event.player_index)
        local gui = get_material_exchange_container_gui(player)
        update_material_exchange_container_gui(gui, event.entity, player)

        multi_index_set(global, { "opened_guis", player.index }, { gui = gui, entity = event.entity })
    end)

    script.on_event(defines.events.on_gui_closed, function(event)
        if not event.gui_type == defines.gui_type.entity then
            return
        end

        if event.entity == nil then
            return
        end

        if event.entity.type ~= "container" then
            return
        end

        if event.entity.name ~= core.make_container_name("material-exchange-container") then
            return
        end

        local player = game.get_player(event.player_index)
        local gui = get_material_exchange_container_gui(player)

        local path = { "opened_guis", player.index }
        local opened_gui = multi_index_get(global, path)
        if opened_gui and opened_gui.gui.name == gui.name then
            multi_index_set(global, path, nil)
        end
    end)

    local function on_something_while_open(event, something)
        for _, player in pairs(game.players) do
            local player_index = player.index

            local opened_gui = multi_index_get(global, { "opened_guis", player_index })
            if opened_gui then
                local func = something[opened_gui.gui.name]
                if func then
                    func(player, opened_gui)
                end
            end
        end
    end

    script.on_nth_tick(10, function(event)
        on_something_while_open(event, cflib.on_every_10th_tick_while_open)
    end)

    script.on_event(defines.events.on_research_finished, function(event)
        on_something_while_open(event, cflib.on_research_finished)
    end)

    setup_material_exchange_container_gui_global_events()
end
