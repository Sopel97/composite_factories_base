require("lib/core")

do
    cflib.gui_styles = require("prototypes/gui_styles")

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
            name = cflib.item_group_name,
            order = "z",
            inventory_order = "z",
            icon = "__composite_factories_base__/graphics/icons/item_group.png",
            icon_size = 64
        },
        {
            type = "item-group",
            name = cflib.processing_recipe_group_name,
            order = "z",
            inventory_order = "z",
            icon = "__composite_factories_base__/graphics/icons/processing_recipe_group.png",
            icon_size = 64
        },
        {
            type = "item-subgroup",
            name = cflib.processing_recipe_group_name,
            group = cflib.processing_recipe_group_name,
            order = "a"
        }
    }

    data:extend {
        {
            type = "recipe-category",
            name = cflib.processing_recipe_category_name
        }
    }

    data:extend {
        {
            type = "sprite",
            name = cflib.time_duration_indicator_sprite_name,
            filename = "__core__/graphics/time-editor-icon.png",
            size = {32, 32}
        }
    }

    data:extend {
        {
            type = "sprite",
            name = cflib.energy_indicator_sprite_name,
            filename = "__core__/graphics/icons/alerts/electricity-icon-unplugged.png",
            size = {64, 64}
        }
    }

    data:extend {
        {
            type = "sprite",
            name = cflib.info_sprite_name,
            filename = "__base__/graphics/icons/info.png",
            size = {64, 64},
            mipmap_count = 4
        }
    }

    data:extend {
        {
            type = "sprite",
            name = cflib.craft_button_sprite_name,
            filename = "__composite_factories_base__/graphics/icons/craft_button.png",
            size = {64, 64}
        }
    }

    cflib.add_item_subgroup = function(args)
        local name = cflib.make_item_subgroup_name(args.name)
        data:extend {
            {
                type = "item-subgroup",
                name = name,
                group = cflib.item_group_name,
                order = args.order
            }
        }
        return name
    end

    local container_item_subgroup = cflib.add_item_subgroup {
        name = "container",
        order = "a"
    }

    local function generate_composite_factory_picture(size)
        local tile_size_in_pixels = 32

        local half_size = size / 2

        local roof_sprite_size = { 436, 228 }
        local roof_apparent_size = { 436, 219 }
        local roof_slope = 10.0

        local roof_bottom_bevel_sprite_size = { 436, 16 }
        local roof_bottom_bevel_apparent_size = { 436, 6 }

        local roof_side_bevel_sprite_size = { 8, 228 }

        local roof_corner_bevel_sprite_size = { 16, 16 }

        local roof_shadow_sprite_size = { 436, 42 }

        local front_sprite_size = { 436, 164 }

        local front_left_bevel_sprite_size = { 8, 164 }
        local front_right_bevel_sprite_size = { 8, 164 }

        local shadow_sprite_size = { 106, 228 }

        local building_height_pixels = 64
        local front_inset_pixels = 16

        local function get_roof_height_at(x, scale)
            return (roof_slope * scale) / (roof_sprite_size[1] * scale) * x
        end

        -- The position is relative to bottom left corner
        local function make_sprite(args, filename, raw_sprite_size)
            if not args.width_slice then
                args.width_slice = 1
            end

            if not args.scale then
                args.scale = 1
            end

            if not args.shift then
                args.shift = { 0, 0 }
            end

            local sprite_size = {
                raw_sprite_size[1] * args.width_slice,
                raw_sprite_size[2]
            }

            args.shift[1] = args.shift[1] - half_size + args.scale * sprite_size[1] / 2 / tile_size_in_pixels
            args.shift[2] = args.shift[2] + half_size - args.scale * sprite_size[2] / 2 / tile_size_in_pixels

            local sprite = {
                filename = filename,
                priority = "medium",
                size = sprite_size
            }

            for k, v in pairs(args) do
                sprite[k] = v
            end

            return sprite
        end

        local function make_roof_left_sprite(args)
            return make_sprite(
                args,
                "__composite_factories_base__/graphics/entity/composite_factory_roof_left.png",
                roof_sprite_size
            )
        end

        local function make_roof_right_sprite(args)
            if not args.width_slice then
                args.width_slice = 1
            end
            args.x = roof_sprite_size[1] * (1-args.width_slice)
            return make_sprite(
                args,
                "__composite_factories_base__/graphics/entity/composite_factory_roof_right.png",
                roof_sprite_size
            )
        end

        local function make_roof_left_bottom_bevel_sprite(args)
            return make_sprite(
                args,
                "__composite_factories_base__/graphics/entity/composite_factory_roof_left_bottom_bevel.png",
                roof_bottom_bevel_sprite_size
            )
        end

        local function make_roof_right_bottom_bevel_sprite(args)
            if not args.width_slice then
                args.width_slice = 1
            end
            args.x = roof_bottom_bevel_sprite_size[1] * (1-args.width_slice)
            return make_sprite(
                args,
                "__composite_factories_base__/graphics/entity/composite_factory_roof_right_bottom_bevel.png",
                roof_bottom_bevel_sprite_size
            )
        end

        local function make_roof_left_left_bevel_sprite(args)
            return make_sprite(
                args,
                "__composite_factories_base__/graphics/entity/composite_factory_roof_left_left_bevel.png",
                roof_side_bevel_sprite_size
            )
        end

        local function make_roof_right_right_bevel_sprite(args)
            if not args.width_slice then
                args.width_slice = 1
            end
            args.x = roof_side_bevel_sprite_size[1] * (1-args.width_slice)
            return make_sprite(
                args,
                "__composite_factories_base__/graphics/entity/composite_factory_roof_right_right_bevel.png",
                roof_side_bevel_sprite_size
            )
        end

        local function make_roof_left_bottom_left_bevel_sprite(args)
            return make_sprite(
                args,
                "__composite_factories_base__/graphics/entity/composite_factory_roof_left_bottom_left_bevel.png",
                roof_corner_bevel_sprite_size
            )
        end

        local function make_roof_right_bottom_right_bevel_sprite(args)
            if not args.width_slice then
                args.width_slice = 1
            end
            args.x = roof_corner_bevel_sprite_size[1] * (1-args.width_slice)
            return make_sprite(
                args,
                "__composite_factories_base__/graphics/entity/composite_factory_roof_right_bottom_right_bevel.png",
                roof_corner_bevel_sprite_size
            )
        end

        local function make_roof_left_shadow_sprite(args)
            return make_sprite(
                args,
                "__composite_factories_base__/graphics/entity/composite_factory_shadow_front_left.png",
                roof_shadow_sprite_size
            )
        end

        local function make_roof_right_shadow_sprite(args)
            if not args.width_slice then
                args.width_slice = 1
            end
            if not args.x then
                args.x = 0
            end
            args.x = args.x + roof_shadow_sprite_size[1] * (1-args.width_slice)
            return make_sprite(
                args,
                "__composite_factories_base__/graphics/entity/composite_factory_shadow_front_right.png",
                roof_shadow_sprite_size
            )
        end

        local function make_front_left_bevel_sprite(args)
            return make_sprite(
                args,
                "__composite_factories_base__/graphics/entity/composite_factory_front_3_left_bevel.png",
                front_left_bevel_sprite_size
            )
        end

        local function make_front_right_bevel_sprite(args)
            return make_sprite(
                args,
                "__composite_factories_base__/graphics/entity/composite_factory_front_3_right_bevel.png",
                front_right_bevel_sprite_size
            )
        end

        local function make_front_sprite(args)
            return make_sprite(
                args,
                "__composite_factories_base__/graphics/entity/composite_factory_front_3.png",
                front_sprite_size
            )
        end

        local function make_shadow_sprite(args)
            return make_sprite(
                args,
                "__composite_factories_base__/graphics/entity/composite_factory_shadow.png",
                shadow_sprite_size
            )
        end

        local layers = {}

        local entity_size_in_pixels = {
            size * tile_size_in_pixels,
            size * tile_size_in_pixels
        }

        -- We do 1 pixel of padding everywhere so that empty spaces
        -- don't show up on some zooms

        local function make_front_decals(x, front_sprite_count, scale)
            table.insert(layers, make_front_left_bevel_sprite{
                shift = util.by_pixel(
                    x,
                    0
                ),
                scale = scale
            })

            table.insert(layers, make_front_right_bevel_sprite{
                shift = util.by_pixel(
                    x - front_sprite_count + (front_sprite_count * front_sprite_size[1] - front_right_bevel_sprite_size[1]) * scale + 1,
                    0
                ),
                scale = scale
            })
        end

        local function make_front()
            local ideal_num_front_sprites = (entity_size_in_pixels[1] - front_inset_pixels * 2) / (front_sprite_size[1] - 1)

            local front_sprite_scale = ideal_num_front_sprites / math.floor(ideal_num_front_sprites)

            local num_front_sprites = math.floor(ideal_num_front_sprites)

            local xmax = num_front_sprites-1
            for x=0,xmax do
                -- -x/y for padding (we overlap by 1 pixel)
                table.insert(layers, make_front_sprite{
                    shift = util.by_pixel(
                        x*front_sprite_size[1]*front_sprite_scale - x + front_inset_pixels,
                        0
                    ),
                    scale = front_sprite_scale
                })
            end

            make_front_decals(
                front_inset_pixels,
                num_front_sprites,
                front_sprite_scale
            )
        end

        local function make_roof_bottom_bevel(num_roof_sprites, roof_sprite_scale)
            local xmax = math.floor(num_roof_sprites[1])
            local ymax = num_roof_sprites[2]-1
            for x=0,xmax do
                local width_slice = 1
                if x == xmax then
                    -- Add one pixel so it doesn't produce a gap on some zooms
                    width_slice = num_roof_sprites[1] - math.floor(num_roof_sprites[1]) + 0.005
                    if width_slice < 0.001 then
                        break
                    end
                end

                -- -x/y for padding (we overlap by 1 pixel)
                table.insert(layers, make_roof_left_bottom_bevel_sprite{
                    shift = util.by_pixel(
                        x*roof_apparent_size[1]*roof_sprite_scale - x,
                        -x*roof_slope*roof_sprite_scale - building_height_pixels
                    ),
                    scale = roof_sprite_scale,
                    width_slice = width_slice
                })

                table.insert(layers, make_roof_right_bottom_bevel_sprite{
                    shift = util.by_pixel(
                        size * tile_size_in_pixels - x*roof_apparent_size[1]*roof_sprite_scale - roof_apparent_size[1]*width_slice*roof_sprite_scale + x,
                        -x*roof_slope*roof_sprite_scale - building_height_pixels
                    ),
                    scale = roof_sprite_scale,
                    width_slice = width_slice
                })
            end
        end

        local function make_roof_side_bevel(num_roof_sprites, roof_sprite_scale)
            local xmax = math.floor(num_roof_sprites[1])
            local ymax = num_roof_sprites[2]-1
            for y=0,ymax do
                -- -x/y for padding (we overlap by 1 pixel)
                table.insert(layers, make_roof_left_left_bevel_sprite{
                    shift = util.by_pixel(
                        0,
                        -y*roof_apparent_size[2]*roof_sprite_scale - building_height_pixels + y
                    ),
                    scale = roof_sprite_scale
                })

                table.insert(layers, make_roof_right_right_bevel_sprite{
                    shift = util.by_pixel(
                        size * tile_size_in_pixels - roof_side_bevel_sprite_size[1]*roof_sprite_scale + xmax,
                        -y*roof_apparent_size[2]*roof_sprite_scale - building_height_pixels + y
                    ),
                    scale = roof_sprite_scale
                })
            end
        end

        local function make_roof_corner_bevel(num_roof_sprites, roof_sprite_scale)
            local xmax = math.floor(num_roof_sprites[1])
            -- -x/y for padding (we overlap by 1 pixel)
            table.insert(layers, make_roof_left_bottom_left_bevel_sprite{
                shift = util.by_pixel(
                    0,
                    -building_height_pixels
                ),
                scale = roof_sprite_scale
            })

            table.insert(layers, make_roof_right_bottom_right_bevel_sprite{
                shift = util.by_pixel(
                    size * tile_size_in_pixels - roof_corner_bevel_sprite_size[1]*roof_sprite_scale + xmax,
                    -building_height_pixels
                ),
                scale = roof_sprite_scale
            })
        end

        local function make_roof_shadow(num_roof_sprites, roof_sprite_scale)
            -- TODO: make this draw correctly.
            --       It's hard due to transparency and the need for cutting it at both edges.
            --[[
            local xmax = math.floor(num_roof_sprites[1])
            local ymax = num_roof_sprites[2]-1
            for x=0,xmax do
                local width_slice = 1
                if x == xmax then
                    -- Add one pixel so it doesn't produce a gap on some zooms
                    width_slice = num_roof_sprites[1] - math.floor(num_roof_sprites[1]) + 0.005
                    if width_slice < 0.001 then
                        break
                    end
                end

                -- -x/y for padding (we overlap by 1 pixel)
                table.insert(layers, make_roof_left_shadow_sprite{
                    shift = util.by_pixel(
                        x*roof_shadow_sprite_size[1]*roof_sprite_scale - x,
                        -(x+1)*roof_slope*roof_sprite_scale - building_height_pixels + roof_shadow_sprite_size[2] * roof_sprite_scale - 1
                    ),
                    scale = roof_sprite_scale,
                    width_slice = width_slice
                })

                table.insert(layers, make_roof_right_shadow_sprite{
                    shift = util.by_pixel(
                        size * tile_size_in_pixels - x*roof_shadow_sprite_size[1]*roof_sprite_scale - roof_shadow_sprite_size[1]*width_slice*roof_sprite_scale + x,
                        -(x+1)*roof_slope*roof_sprite_scale - building_height_pixels + roof_shadow_sprite_size[2] * roof_sprite_scale - 1
                    ),
                    scale = roof_sprite_scale,
                    width_slice = width_slice
                })
            end
            ]]--
        end

        local function make_roof_decals(num_roof_sprites, roof_sprite_scale)
            make_roof_bottom_bevel(num_roof_sprites, roof_sprite_scale)
            make_roof_side_bevel(num_roof_sprites, roof_sprite_scale)
            make_roof_corner_bevel(num_roof_sprites, roof_sprite_scale)
            make_roof_shadow(num_roof_sprites, roof_sprite_scale)
        end

        local function make_roof()
            -- This will be a fraction amount
            local ideal_num_roof_sprites = {
                entity_size_in_pixels[1] / (roof_apparent_size[1] - 1),
                entity_size_in_pixels[2] / (roof_apparent_size[2] - 1)
            }

            -- We can only cut the roof sprite on the left/right, not from top/bottom
            -- so we have to have an integer amount of sprites in the y direction
            -- and a possibly fractional amount in the x direction
            -- And we can't have separate scales for x and y...
            local roof_sprite_scale = ideal_num_roof_sprites[2] / math.floor(ideal_num_roof_sprites[2])

            local num_roof_sprites = {
                -- Divided by 2 because it's for one side
                entity_size_in_pixels[1] / (roof_apparent_size[1] * roof_sprite_scale) / 2,
                math.floor(ideal_num_roof_sprites[2])
            }

            local xmax = math.floor(num_roof_sprites[1])
            local ymax = num_roof_sprites[2]-1
            for x=0,xmax do
                local width_slice = 1
                if x == xmax then
                    -- Add one pixel so it doesn't produce a gap on some zooms
                    width_slice = num_roof_sprites[1] - math.floor(num_roof_sprites[1]) + 0.005
                    if width_slice < 0.001 then
                        break
                    end
                end

                for y=0,ymax do
                    -- -x/y for padding (we overlap by 1 pixel)
                    table.insert(layers, make_roof_left_sprite{
                        shift = util.by_pixel(
                            x*roof_apparent_size[1]*roof_sprite_scale - x,
                            -(y*roof_apparent_size[2]+x*roof_slope)*roof_sprite_scale - building_height_pixels + y
                        ),
                        scale = roof_sprite_scale,
                        width_slice = width_slice
                    })

                    table.insert(layers, make_roof_right_sprite{
                        shift = util.by_pixel(
                            size * tile_size_in_pixels - x*roof_apparent_size[1]*roof_sprite_scale - roof_apparent_size[1]*width_slice*roof_sprite_scale + x,
                            -(y*roof_apparent_size[2]+x*roof_slope)*roof_sprite_scale - building_height_pixels + y
                        ),
                        scale = roof_sprite_scale,
                        width_slice = width_slice
                    })
                end
            end

            make_roof_decals(num_roof_sprites, roof_sprite_scale)
        end

        local function make_shadow()
            -- This will be a fraction amount
            local ideal_num_roof_sprites = {
                entity_size_in_pixels[1] / (roof_apparent_size[1] - 1),
                entity_size_in_pixels[2] / (roof_apparent_size[2] - 1)
            }

            -- We can only cut the roof sprite on the left/right, not from top/bottom
            -- so we have to have an integer amount of sprites in the y direction
            -- and a possibly fractional amount in the x direction
            -- And we can't have separate scales for x and y...
            local roof_sprite_scale = ideal_num_roof_sprites[2] / math.floor(ideal_num_roof_sprites[2])

            local num_roof_sprites = {
                -- Divided by 2 because it's for one side
                entity_size_in_pixels[1] / (roof_apparent_size[1] * roof_sprite_scale) / 2,
                math.floor(ideal_num_roof_sprites[2])
            }

            local xmax = math.floor(num_roof_sprites[1])
            local ymax = num_roof_sprites[2]-1
            for y=0,ymax do
                -- -x/y for padding (we overlap by 1 pixel)
                table.insert(layers, make_shadow_sprite{
                    shift = util.by_pixel(
                        size * tile_size_in_pixels - front_inset_pixels,
                        -y*roof_apparent_size[2]*roof_sprite_scale + y
                    ),
                    scale = roof_sprite_scale,
                    draw_as_shadow = true
                })
            end
        end

        make_front()
        make_roof()
        make_shadow()

        return { layers = layers }
    end

    -- The container used for material exchange.
    local function add_container(args)
        local full_name = cflib.make_container_name(args.name)

        local sprite_size = { 248, 312 }
        local shadow_sprite_size = { 48, 248 }

        local half_size = args.size / 2
        local base_apparent_sprite_size_pixels = sprite_size[1]
        local base_apparent_sprite_size = base_apparent_sprite_size_pixels / 32

        local scale = args.size / base_apparent_sprite_size

        local container_recipe_enabled = args.unlocked_by == nil

        -- Container item
        data:extend({{
            type = "item",
            name = full_name,
            icon = "__composite_factories_base__/graphics/icons/material_exchange_container.png",
            icon_size = 64,
            subgroup = container_item_subgroup,
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
            icon = "__composite_factories_base__/graphics/icons/material_exchange_container.png",
            icon_size = 64,
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
                        filename = "__composite_factories_base__/graphics/entity/material_exchange_container.png",
                        priority = "high",
                        size = sprite_size,
                        shift = util.by_pixel(0, -(sprite_size[2] - shadow_sprite_size[2]) / 2 * scale),
                        scale = scale
                    },
                    {
                        filename = "__composite_factories_base__/graphics/entity/material_exchange_container_shadow.png",
                        priority = "high",
                        size = shadow_sprite_size,
                        shift = util.by_pixel(
                            (base_apparent_sprite_size_pixels + shadow_sprite_size[1]) / 2 * scale - 2,
                            (base_apparent_sprite_size_pixels - shadow_sprite_size[2]) / 2 * scale
                        ),
                        draw_as_shadow = true,
                        scale = scale
                    }
                }
            }
        }})

        return full_name
    end

    cflib.add_technology = function(args)
        local full_name = cflib.make_technology_name(args.name)

        data:extend({{
            type = "technology",
            name = full_name,
            -- placeholder
            icon = "__composite_factories_base__/graphics/icons/composite_factory.png",
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
        num_units = 250,
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
            {"steel-chest", 50},
            {"iron-plate", 200},
            {"stone-brick", 200},
            {"steel-plate", 200}
        },
        energy_required = 600.0,
        unlocked_by = cflib.base_technology
    }

    local function adjust_fluid_box_position(position)
        return {
            math.floor(position[1] + 0.5) + 0.5,
            position[2]
        }
    end

    cflib.add_composite_factory = function(args)
        local factory_full_name = cflib.make_composite_factory_name(args.name)
        local processing_full_name = cflib.make_processing_recipe_name(args.name)

        local base_sprite_size = 3
        local base_hr_sprite_size = 6
        local half_size = args.size / 2

        local num_fluid_inputs = count_fluids(args.ingredients)
        local num_fluid_outputs = count_fluids(args.results)

        local composite_factory_recipe_enabled = args.unlocked_by == nil

        local area = math.floor(args.size * args.size)
        local perimeter = math.floor(args.size * 4)
        table.insert(args.constituent_buildings, { "steel-plate", area })
        table.insert(args.constituent_buildings, { "stone-brick", perimeter })

        local fluid_boxes = {
            off_when_no_fluid_recipe = true
        }

        local fluid_input_spacing = args.size / (num_fluid_inputs+1)
        for i=1, num_fluid_inputs do
            local position = adjust_fluid_box_position({-half_size + i * fluid_input_spacing, -half_size-0.5})

            table.insert(fluid_boxes, {
                production_type = "input",
                pipe_picture = assembler2pipepictures(),
                pipe_covers = pipecoverspictures(),
                base_area = 10,
                base_level = -1,
                pipe_connections = {{ type="input", position = position }},
                secondary_draw_orders = { north = -1 }
            })
        end

        local fluid_output_spacing = args.size / (num_fluid_outputs+1)
        for i=1, num_fluid_outputs do
            local position = adjust_fluid_box_position({-half_size + i * fluid_output_spacing, half_size+0.5})

            table.insert(fluid_boxes, {
                production_type = "output",
                pipe_picture = assembler2pipepictures(),
                pipe_covers = pipecoverspictures(),
                base_area = 10,
                base_level = -1,
                pipe_connections = {{ type="output", position = position }},
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
                category = cflib.processing_recipe_category_name,
                subgroup = cflib.processing_recipe_group_name,
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
                category = cflib.processing_recipe_category_name,
                subgroup = cflib.processing_recipe_group_name,
                -- TODO: generate an icon from products
                icon = "__composite_factories_base__/graphics/icons/composite_factory.png",
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
            icon = "__composite_factories_base__/graphics/icons/composite_factory.png",
            icon_size = 64,
            flags = {},
            subgroup = args.subgroup,
            order = "b",
            place_result = factory_full_name,
            stack_size = 1
        }})

        -- Composite factory entity
        data:extend({{
            type = "assembling-machine",
            name = factory_full_name,
            fixed_recipe = processing_full_name,
            icon = "__composite_factories_base__/graphics/icons/composite_factory.png",
            icon_size = 64,
            flags = {"placeable-neutral", "player-creation"},
            minable = {mining_time = 1, result = factory_full_name},
            max_health = 10000,
            corpse = "medium-remnants",
            dying_explosion = "medium-explosion",
            collision_box = {{-half_size+0.1, -half_size+0.1}, {half_size-0.1, half_size-0.1}},
            selection_box = {{-half_size, -half_size}, {half_size, half_size}},
            match_animation_speed_to_activity = false,
            crafting_categories = {cflib.processing_recipe_category_name},
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
            animation = generate_composite_factory_picture(args.size),
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
        if args.ingredients and #args.ingredients ~= 0 then
            error("Only generators without ingredients are supported right now.")
        end

        local full_name = cflib.make_generator_name(args.name)

        local base_sprite_size = 3
        local base_hr_sprite_size = 6
        local half_size = args.size / 2

        local enabled = args.unlocked_by == nil

        local area = math.floor(args.size * args.size)
        local perimeter = math.floor(args.size * 4)
        table.insert(args.constituent_buildings, { "steel-plate", area })
        table.insert(args.constituent_buildings, { "stone-brick", perimeter })

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
            icon = "__composite_factories_base__/graphics/icons/composite_generator.png",
            icon_size = 64,
            flags = {},
            subgroup = args.subgroup,
            order = "b",
            place_result = full_name,
            stack_size = 1
        }})

        data:extend({{
            type = "electric-energy-interface",
            name = full_name,
            icon = "__composite_factories_base__/graphics/icons/composite_generator.png",
            icon_size = 64,
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
            picture = generate_composite_factory_picture(args.size),
            vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65}
        }})
    end
end