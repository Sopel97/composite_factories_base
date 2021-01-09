if not cflib then
    cflib = {}
end

do
    cflib.name_prefix = "composite-factory-"
    cflib.item_group_name = cflib.name_prefix .. "items"
    cflib.processing_recipe_group_name = cflib.name_prefix .. "processing"
    cflib.processing_recipe_category_name = cflib.name_prefix .. "processing"
    cflib.time_duration_indicator_sprite_name = cflib.name_prefix .. "time-duration-indicator"
    cflib.energy_indicator_sprite_name = cflib.name_prefix .. "energy-indicator"
    cflib.info_sprite_name = cflib.name_prefix .. "info"

    cflib.make_item_subgroup_name = function(name)
        return cflib.item_group_name .. "-" .. name
    end

    cflib.make_container_name = function(name)
        return cflib.name_prefix .. name
    end

    cflib.make_technology_name = function(name)
        return cflib.name_prefix .. name
    end

    cflib.make_composite_factory_name = function(name)
        return cflib.name_prefix .. name .. "-factory"
    end

    cflib.unmake_composite_factory_name = function(name)
        return string.sub(name, string.len(cflib.name_prefix) + 1, -string.len("-factory") - 1)
    end

    cflib.make_processing_recipe_name = function(name)
        return cflib.name_prefix .. name .. "-processing"
    end

    cflib.make_generator_name = function(name)
        return cflib.name_prefix .. name .. "-generator"
    end

    cflib.unmake_generator_name = function(name)
        return string.sub(name, string.len(cflib.name_prefix) + 1, -string.len("-generator") - 1)
    end

    cflib.make_gui_element_name = function(name)
        return cflib.name_prefix .. name
    end

    cflib.get_unprefixed_name = function(name)
        return string.sub(name, string.len(cflib.name_prefix) + 1, -1)
    end

    cflib.is_mod_prefixed_name = function(name)
        local found = string.find(name, cflib.name_prefix, 1, true)
        return found and found == 1
    end

    cflib.make_gui_style_name = function(name)
        return cflib.name_prefix .. name
    end

    return cflib
end