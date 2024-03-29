do
    local gui_styles = {}

    local data_gui_styles = data.raw["gui-style"].default

    local item_preview_size = 40
    local cell_spacing = 0
    local cell_padding = 0

    local function calc_item_preview_width(num_columns)
        return (item_preview_size + cell_padding * 2) * num_columns + cell_spacing * (num_columns - 1) + 3 + 3
    end

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-header")] = {
        type = "vertical_flow_style",
        left_padding = 4
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-header-cell")] = {
        type = "label_style",
        parent = "heading_3_label_yellow"
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-craft")] = {
        type = "button_style",
        parent = "green_button",
        size = {item_preview_size, item_preview_size},
        horizontal_align = "center",
        vertical_align = "center"
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-info")] = {
        type = "button_style",
        parent = "slot_button",
        size = item_preview_size
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-building-ingredients-flow")] = {
        type = "flow_style",
        horizontal_spacing = 0,
        vertical_spacing = 0,
        minimal_width = calc_item_preview_width(5)
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-building-ingredients-preview-panel")] = {
        type = "table_style",
        parent = "slot_table",
        minimal_width = calc_item_preview_width(5)
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-building-ingredients-panel")] = {
        type = "table_style",
        parent = "slot_table",
        minimal_width = calc_item_preview_width(5)
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui")] = {
        type = "frame_style",
        manimal_height = 100,
        maximal_height = 2000
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table")] = {
        type = "table_style",
        column_widths = {
            {
                column = 1,
                width = calc_item_preview_width(1)
            },
            {
                column = 2,
                width = calc_item_preview_width(1)
            },
            {
                column = 3,
                width = calc_item_preview_width(1)
            },
            {
                column = 4,
                width = calc_item_preview_width(5)
            },
            {
                column = 5,
                width = calc_item_preview_width(2)
            },
            {
                column = 6,
                width = calc_item_preview_width(1)
            },
            {
                column = 7,
                width = calc_item_preview_width(2)
            }
        }
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-normal")] = {
        type = "button_style",
        parent = "slot",
        size = item_preview_size
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-green")] = {
        type = "button_style",
        parent = "green_slot",
        size = item_preview_size
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-yellow")] = {
        type = "button_style",
        parent = "yellow_slot",
        size = item_preview_size
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-red")] = {
        type = "button_style",
        parent = "red_slot",
        size = item_preview_size
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-dotdotdot")] = {
        type = "label_style",
        parent = "bold_label",
        size = item_preview_size,
        horizontal_align = "center",
        vertical_align = "center"
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-item-preview-expand-collapse")] = {
        type = "button_style",
        size = item_preview_size,
        horizontal_align = "center",
        vertical_align = "center"
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-ingredient-summary-panel")] = {
        type = "table_style",
        parent = "slot_table",
        minimal_width = calc_item_preview_width(2)
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-product-summary-panel")] = {
        type = "table_style",
        parent = "slot_table",
        minimal_width = calc_item_preview_width(2)
    }

    data_gui_styles[cflib.make_gui_style_name("material-exchange-container-gui-exchange-table-energy-required-panel")] = {
        type = "table_style",
        parent = "slot_table",
        minimal_width = calc_item_preview_width(1)
    }

    return gui_styles
end