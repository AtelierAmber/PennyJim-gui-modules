---@type modules.GuiModuleDef
---@diagnostic disable-next-line: missing-fields
local module = {
	module_type = "split_pane",
	handlers = {}
}

---@class WindowState.my_module : modules.WindowState
-- Where custom fields would go

local handler_names = {
	-- A generic place to make sure handler names match
	-- in both handler definitons and in the build_func
}

---@alias (partial) modules.types
---| "split_pane"
---@alias (partial) modules.ModuleElems
---| modules.SplitPaneModuleElem
---@class modules.SplitPaneModuleElem
---@field module_type "split_pane"
---@field args modules.SplitPaneModuleArgs

---@class modules.SplitPaneModuleArgs
-- where LuaLS parameter definitons go
---@field number_of_panes integer
---@field direction "horizontal"|"vertical"
---@field panes modules.GuiElemDef[]
---@field frame_styles string[]|string?
---@field stretch_panes boolean?
---@type ModuleParameterDict
module.parameters = {
	-- Where gui-modules parameter definitons go
	number_of_panes = {is_optional = false, type = {"number"}},
	direction = {is_optional = false, type = {"string"}, enum = {"horizontal", "vertical"}},
	panes = {is_optional = false, type = {"table"}},
	frame_styles = {is_optional = true, type = {"string", "table"}},
	stretch_panes = {is_optional = true, type = {"boolean"}},
}

---Creates the frame for a window with an exit button
---@param params modules.SplitPaneModuleArgs
function module.build_func(params)
	local panes = params.number_of_panes
	local styles = params.frame_styles or "inside_shallow_frame_with_padding"
	---@type string
	local style
	local pane_contents = params.panes
	if type(styles) == "string" then
		style = styles
	elseif #styles < panes then
		error{"module-errors.array-too-short", "frame_styles", panes, #styles}
	elseif #pane_contents < panes then
		error{"module-errors.array-too-short", "children", panes, #pane_contents}
	end

	---@type modules.GuiElemDef[]
	local children = {}
	---@type LuaStyle?
	local child_style_mod
	if params.stretch_panes ~= nil then
---@diagnostic disable-next-line: missing-fields
		child_style_mod = {[params.direction.."ly_stretchable"] = params.stretch_panes}
	end
	for i = 1, panes, 1 do
		children[i] = {
			args = {
				type = "frame", style = style or styles[i],
			},
			style_mods = child_style_mod,
			children = {pane_contents[i]}
		} --[[@as modules.GuiElemDef]]
	end
	return {
		args = {
			type = "flow", direction = params.direction,
			style = "inset_frame_container_"..params.direction.."_flow" --[[@as string]],
		},
		children = children
	}
end

return module