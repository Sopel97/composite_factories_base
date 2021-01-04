do
    -- Maybe make it as a separete library mod later on?

    local core = require("private/core")

    local cflib = {}

    cflib.gui_styles = require("private/gui_styles")

    local function add_recipe_unlock(recipe, technology)
        table.insert(data.raw.technology[technology].effects, {
            type = "unlock-recipe",
            recipe = recipe
        })
    end

    local function count_fluids(things)
        local num_fluids = 0
        for _, e in pairs(things) do
            if e.type and e.type == "fluid" then
                num_fluids = num_fluids + 1
            end
        end
        return num_fluids
    end

    data:extend {
        {
            type = "item-group",
            name = core.item_group_name,
            order = "z",
            inventory_order = "z",
            icon = "__composite_factories_pyblock__/graphics/item-group.png",
            icon_size = 64
        },
        {
            type = "item-subgroup",
            name = core.item_group_name,
            group = core.item_group_name,
            order = "a"
        },
        {
            type = "item-group",
            name = core.processing_recipe_group_name,
            order = "z",
            inventory_order = "z",
            icon = "__composite_factories_pyblock__/graphics/processing-recipe-group.png",
            icon_size = 64
        },
        {
            type = "item-subgroup",
            name = core.processing_recipe_group_name,
            group = core.processing_recipe_group_name,
            order = "a"
        }
    }

    data:extend {
        {
            type = "recipe-category",
            name = core.processing_recipe_category_name
        }
    }

    data:extend {
        {
            type = "sprite",
            name = core.time_duration_indicator_sprite_name,
            filename = "__core__/graphics/time-editor-icon.png",
            size = {32, 32}
        }
    }

    data:extend {
        {
            type = "sprite",
            name = core.energy_indicator_sprite_name,
            filename = "__core__/graphics/icons/alerts/electricity-icon-unplugged.png",
            size = {64, 64}
        }
    }

    -- The container used for material exchange.
    local function add_container(args)
        local full_name = core.make_container_name(args.name)

        local base_sprite_size = 1
        local base_hr_sprite_size = 2
        local half_size = args.size / 2

        local container_recipe_enabled = args.unlocked_by == nil

        -- Container item
        data:extend({{
            type = "item",
            name = full_name,
            icon = "__base__/graphics/icons/wooden-chest.png",
            icon_size = 64,
            icon_mipmaps = 4,
            subgroup = core.item_group_name,
            order = "a[items]-a[wooden-chest]",
            place_result = full_name,
            stack_size = 1
        }})

        -- Container recipe
        data:extend({{
            type = "recipe",
            name = full_name,
            enabled = container_recipe_enabled,
            energy_required = args.energy_required,
            category = "crafting",
            ingredients = args.ingredients,
            results = {
                {full_name, 1}
            }
        }})

        if args.unlocked_by then
            add_recipe_unlock(full_name, args.unlocked_by)
        end

        -- Container entity
        data:extend({{
            type = "container",
            name = full_name,
            icon = "__base__/graphics/icons/wooden-chest.png",
            icon_size = 64, icon_mipmaps = 4,
            flags = {"placeable-neutral", "placeable-player", "player-creation"},
            minable = {mining_time = 2, result = full_name},
            max_health = 10000,
            corpse = "big-remnants",
            dying_explosion = "medium-explosion",
            open_sound = { filename = "__base__/sound/machine-open.ogg", volume = 0.85 },
            close_sound = { filename = "__base__/sound/machine-close.ogg", volume = 0.75 },
            vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
            resistances =
            {
                {
                    type = "fire",
                    percent = 90
                }
            },
            collision_box = {{-half_size+0.1, -half_size+0.1}, {half_size-0.1, half_size-0.1}},
            selection_box = {{-half_size, -half_size}, {half_size, half_size}},
            inventory_size = args.num_slots,
            scale_info_icons = true,
            picture = {
                layers = {
                    {
                        filename = "__base__/graphics/entity/wooden-chest/wooden-chest.png",
                        priority = "high",
                        width = 32,
                        height = 36,
                        shift = util.by_pixel(0.5, -2),
                        scale = args.size / base_sprite_size,
                        hr_version = {
                            filename = "__base__/graphics/entity/wooden-chest/hr-wooden-chest.png",
                            priority = "high",
                            width = 62,
                            height = 72,
                            shift = util.by_pixel(0.5, -2),
                            scale = args.size / base_hr_sprite_size
                        }
                    },
                    {
                        filename = "__base__/graphics/entity/wooden-chest/wooden-chest-shadow.png",
                        priority = "high",
                        width = 52,
                        height = 20,
                        shift = util.by_pixel(10, 6.5),
                        draw_as_shadow = true,
                        scale = args.size / base_sprite_size,
                        hr_version = {
                            filename = "__base__/graphics/entity/wooden-chest/hr-wooden-chest-shadow.png",
                            priority = "high",
                            width = 104,
                            height = 40,
                            shift = util.by_pixel(10, 6.5),
                            draw_as_shadow = true,
                            scale = args.size / base_hr_sprite_size
                        }
                    }
                }
            }
        }})

        return full_name
    end

    cflib.add_technology = function(args)
        local full_name = core.make_technology_name(args.name)

        data:extend({{
            type = "technology",
            name = full_name,
            -- placeholder
            icon = "__base__/graphics/icons/assembling-machine-1.png",
            icon_size = 64,
            effects = {},
            prerequisites = args.prerequisites,
            order = "g-e-d",
            unit = {
                count = args.num_units,
                ingredients = args.unit_ingredients,
                time = args.unit_time
            }
        }})

        return full_name
    end

    cflib.base_technology = cflib.add_technology{
        name = "base-technology",
        prerequisites = {"logistic-science-pack"},
        num_units = 500,
        unit_ingredients = {
            {"automation-science-pack", 1},
            {"logistic-science-pack", 1}
        },
        unit_time = 60
    }

    cflib.material_exchange_container = add_container{
        name = "material-exchange-container",
        num_slots = 1000,
        size = 10,
        ingredients = {
            {"wooden-chest", 100},
            {"iron-plate", 200},
            {"stone-brick", 200},
            {"steel-plate", 200}
        },
        energy_required = 600.0,
        unlocked_by = cflib.base_technology
    }

    cflib.add_composite_factory = function(args)
        local factory_full_name = core.make_composite_factory_name(args.name)
        local processing_full_name = core.make_processing_recipe_name(args.name)

        local base_sprite_size = 3
        local base_hr_sprite_size = 6
        local half_size = args.size / 2

        local num_fluid_inputs = count_fluids(args.ingredients)
        local num_fluid_outputs = count_fluids(args.results)

        local composite_factory_recipe_enabled = args.unlocked_by == nil

        local fluid_boxes = {
            off_when_no_fluid_recipe = true
        }

        local fluid_input_spacing = args.size / (num_fluid_inputs+1)
        for i=1, num_fluid_inputs do
            table.insert(fluid_boxes, {
                production_type = "input",
                pipe_picture = assembler2pipepictures(),
                pipe_covers = pipecoverspictures(),
                base_area = 10,
                base_level = -1,
                pipe_connections = {{ type="input", position = {-half_size + i * fluid_input_spacing, -half_size-0.5} }},
                secondary_draw_orders = { north = -1 }
            })
        end

        local fluid_output_spacing = args.size / (num_fluid_outputs+1)
        for i=1, num_fluid_outputs do
            table.insert(fluid_boxes, {
                production_type = "output",
                pipe_picture = assembler2pipepictures(),
                pipe_covers = pipecoverspictures(),
                base_area = 10,
                base_level = -1,
                pipe_connections = {{ type="output", position = {-half_size + i * fluid_output_spacing, half_size+0.5} }},
                secondary_draw_orders = { north = -1 }
            })
        end

        -- Composite factory building item recipe
        data:extend({{
            type = "recipe",
            name = factory_full_name,
            enabled = composite_factory_recipe_enabled,
            energy_required = 600.0,
            category = "crafting",
            ingredients = args.constituent_buildings,
            results = {
                {factory_full_name, 1}
            }
        }})

        if args.unlocked_by then
            add_recipe_unlock(factory_full_name, args.unlocked_by)
        end

        -- Composite factory product recipe
        if #args.results == 1 then
            data:extend({{
                type = "recipe",
                name = processing_full_name,
                energy_required = args.energy_required,
                enabled = true,
                category = core.processing_recipe_category_name,
                subgroup = core.processing_recipe_group_name,
                order = "b",
                ingredients = args.ingredients,
                results = args.results
            }})
        else
            data:extend({{
                type = "recipe",
                name = processing_full_name,
                energy_required = args.energy_required,
                enabled = true,
                category = core.processing_recipe_category_name,
                subgroup = core.processing_recipe_group_name,
                -- TODO: generate an icon from products
                icon = "__base__/graphics/icons/assembling-machine-1.png",
                order = "b",
                icon_size = 64,
                ingredients = args.ingredients,
                results = args.results
            }})
        end

        -- Composite factory item
        data:extend({{
            type = "item",
            name = factory_full_name,
            icon = "__base__/graphics/icons/assembling-machine-1.png",
            icon_size = 64,
            flags = {},
            subgroup = core.item_group_name,
            order = "b",
            place_result = factory_full_name,
            stack_size = 1
        }})

        -- Composite factory entity
        data:extend({{
            type = "assembling-machine",
            name = factory_full_name,
            fixed_recipe = processing_full_name,
            icon = "__base__/graphics/icons/assembling-machine-1.png",
            icon_size = 64,
            flags = {"placeable-neutral", "player-creation"},
            minable = {mining_time = 1, result = factory_full_name},
            max_health = 10000,
            corpse = "medium-remnants",
            dying_explosion = "medium-explosion",
            collision_box = {{-half_size+0.1, -half_size+0.1}, {half_size-0.1, half_size-0.1}},
            selection_box = {{-half_size, -half_size}, {half_size, half_size}},
            match_animation_speed_to_activity = false,
            crafting_categories = {core.processing_recipe_category_name},
            scale_entity_info_icon = true,
            module_specification = {
                module_slots = 1
            },
            allowed_effects = {"consumption", "speed", "productivity", "pollution"},
            crafting_speed = 1,
            energy_source = {
                type = "electric",
                usage_priority = "secondary-input",
                emissions_per_minute = args.emissions_per_minute,
                drain = "0W"
            },
            energy_usage = args.energy_usage,
            animation = {
                layers = {
                    {
                        filename = "__base__/graphics/entity/assembling-machine-1/assembling-machine-1.png",
                        priority="high",
                        width = 108,
                        height = 114,
                        frame_count = 32,
                        line_length = 8,
                        shift = util.by_pixel(0, 2),
                        scale = args.size / base_sprite_size,
                        hr_version = {
                            filename = "__base__/graphics/entity/assembling-machine-1/hr-assembling-machine-1.png",
                            priority="high",
                            width = 214,
                            height = 226,
                            frame_count = 32,
                            line_length = 8,
                            shift = util.by_pixel(0, 2),
                            scale = args.size / base_hr_sprite_size
                        }
                    },
                    {
                        filename = "__base__/graphics/entity/assembling-machine-1/assembling-machine-1-shadow.png",
                        priority="high",
                        width = 95,
                        height = 83,
                        frame_count = 1,
                        line_length = 1,
                        repeat_count = 32,
                        draw_as_shadow = true,
                        shift = util.by_pixel(8.5, 5.5),
                        scale = args.size / base_sprite_size,
                        hr_version = {
                            filename = "__base__/graphics/entity/assembling-machine-1/hr-assembling-machine-1-shadow.png",
                            priority="high",
                            width = 190,
                            height = 165,
                            frame_count = 1,
                            line_length = 1,
                            repeat_count = 32,
                            draw_as_shadow = true,
                            shift = util.by_pixel(8.5, 5),
                            scale = args.size / base_hr_sprite_size
                        }
                    }
                }
            },
            fluid_boxes = fluid_boxes,
            vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
            working_sound =
            {
                sound = {
                    {
                        filename = "__base__/sound/assembling-machine-t1-1.ogg",
                        volume = 0.5
                    }
                },
                audible_distance_modifier = 0.5,
                fade_in_ticks = 4,
                fade_out_ticks = 20
            }
        }})
    end

    cflib.add_composite_generator = function(args)
        if #args.ingredients ~= 0 then
            error("Only generators without ingredients are supported right now.")
        end

        local full_name = core.make_generator_name(args.name)

        local base_sprite_size = 3
        local base_hr_sprite_size = 6
        local half_size = args.size / 2

        local enabled = args.unlocked_by == nil

        -- Composite factory building item recipe
        data:extend({{
            type = "recipe",
            name = full_name,
            enabled = composite_factory_recipe_enabled,
            energy_required = 600.0,
            category = "crafting",
            ingredients = args.constituent_buildings,
            results = {
                {full_name, 1}
            }
        }})

        if args.unlocked_by then
            add_recipe_unlock(full_name, args.unlocked_by)
        end

        -- Composite factory item
        data:extend({{
            type = "item",
            name = full_name,
            icon = "__base__/graphics/icons/solar-panel.png",
            icon_size = 64,
            flags = {},
            subgroup = core.item_group_name,
            order = "b",
            place_result = full_name,
            stack_size = 1
        }})

        data:extend({{
            type = "electric-energy-interface",
            name = full_name,
            icons = { {icon = "__base__/graphics/icons/solar-panel.png", tint = {r=1, g=0.6, b=0.8, a=1}} },
            icon_size = 64, icon_mipmaps = 4,
            flags = {"placeable-neutral", "player-creation"},
            minable = {mining_time = 1, result = full_name},
            max_health = 10000,
            corpse = "medium-remnants",
            subgroup = "other",
            collision_box = {{-half_size+0.1, -half_size+0.1}, {half_size-0.1, half_size-0.1}},
            selection_box = {{-half_size, -half_size}, {half_size, half_size}},
            gui_mode = "none",
            energy_source =
            {
                type = "electric",
                buffer_capacity = nil,
                usage_priority = "tertiary"
            },
            energy_production = args.energy_production,
            energy_usage = "0W",
            -- also 'pictures' for 4-way sprite is available, or 'animation' resp. 'animations'picture =
            picture = {
                layers =
                {
                    {
                        filename = "__base__/graphics/entity/solar-panel/solar-panel.png",
                        priority = "high",
                        width = 116,
                        height = 112,
                        shift = util.by_pixel(-3, 3),
                        scale = args.size / base_sprite_size,
                        hr_version = {
                            filename = "__base__/graphics/entity/solar-panel/hr-solar-panel.png",
                            priority = "high",
                            width = 230,
                            height = 224,
                            shift = util.by_pixel(-3, 3.5),
                            scale = args.size / base_hr_sprite_size
                        }
                    },
                    {
                        filename = "__base__/graphics/entity/solar-panel/solar-panel-shadow.png",
                        priority = "high",
                        width = 112,
                        height = 90,
                        shift = util.by_pixel(10, 6),
                        draw_as_shadow = true,
                        scale = args.size / base_sprite_size,
                        hr_version = {
                            filename = "__base__/graphics/entity/solar-panel/hr-solar-panel-shadow.png",
                            priority = "high",
                            width = 220,
                            height = 180,
                            shift = util.by_pixel(9.5, 6),
                            draw_as_shadow = true,
                            scale = args.size / base_hr_sprite_size
                        }
                    }
                }
            },
            vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65}
        }})
    end

    return cflib
end