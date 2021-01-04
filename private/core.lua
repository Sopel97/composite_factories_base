do
    local core = {}

    core.name_prefix = "composite-factory-"
    core.item_group_name = core.name_prefix .. "items"
    core.processing_recipe_group_name = core.name_prefix .. "processing"
    core.processing_recipe_category_name = core.name_prefix .. "processing"
    core.time_duration_indicator_sprite_name = core.name_prefix .. "time-duration-indicator"
    core.energy_indicator_sprite_name = core.name_prefix .. "energy-indicator"

    core.make_container_name = function(name)
        return core.name_prefix .. name
    end

    core.make_technology_name = function(name)
        return core.name_prefix .. name
    end

    core.make_composite_factory_name = function(name)
        return core.name_prefix .. name .. "-factory"
    end

    core.unmake_composite_factory_name = function(name)
        return string.sub(name, string.len(core.name_prefix) + 1, -string.len("-factory") - 1)
    end

    core.make_processing_recipe_name = function(name)
        return core.name_prefix .. name .. "-processing"
    end

    core.make_generator_name = function(name)
        return core.name_prefix .. name .. "-generator"
    end

    core.unmake_generator_name = function(name)
        return string.sub(name, string.len(core.name_prefix) + 1, -string.len("-generator") - 1)
    end

    core.make_gui_element_name = function(name)
        return core.name_prefix .. name
    end

    core.get_unprefixed_name = function(name)
        return string.sub(name, string.len(core.name_prefix) + 1, -1)
    end

    core.is_mod_prefixed_name = function(name)
        local found = string.find(name, core.name_prefix, 1, true)
        return found and found == 1
    end

    core.make_gui_style_name = function(name)
        return core.name_prefix .. name
    end

    return core
end