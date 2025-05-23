local gui_events = {}
---@type GuiModuleEventHandlersMap
local handlers = {}
local tag_key = "__"..script.mod_name.."_handler"
---@type WindowStorage[]
local states

---Creates the wrapper for the namespace
---@param namespace string
---@param handler GuiModuleEventHandler
---@param elem LuaGuiElement
---@param e EventData.GuiEvents
local function event_wrapper(namespace, handler, elem, e)
	if not states then
		states = storage.gui_states
	end
	local state = states[namespace]--[[@as WindowStorage]][e.player_index]
	---@cast state modules.WindowState
	if not state then return end

	if not state.root.valid then
		-- Delete the entry of an invalid gui
		states[namespace][e.player_index] = nil
		return
	end

	local new_elem, new_event = handler(state, elem, e)
	if new_elem or new_event then
		new_elem = new_elem or elem
		gui_events.dispatch_specific(new_elem, new_event, e)
	end
end
---Dispatches an event to a specific element
---@param elem LuaGuiElement
---@param event defines.events?
---@param e EventData.GuiEvents
function gui_events.dispatch_specific(elem, event, e)
  local handler_name = elem.tags[tag_key] --[[@as GuiModuleEventHandlerNames?]]
	if type(handler_name) == "table" then
		handler_name = handler_name[tostring(event or e.name)]--[[@as string]]
	end
  if not handler_name then
    return false
  end

	local handler = handlers[handler_name]
	local namespace = handler_name:match("^[^/]+")
	event_wrapper(namespace, handler, elem, e)
end
---Handles all GUI events and passes them to the appropriate wrapper function and handler
---@param e EventData.GuiEvents
function gui_events.dispatch_event(e)
	local elem = e.element
	if not elem then return end -- Can't resolve a handler with no element

  local handler_name = elem.tags[tag_key] --[[@as GuiModuleEventHandlerNames?]]
	if type(handler_name) == "table" then
		handler_name = handler_name[tostring(e.name)]--[[@as string]]
	end
  if not handler_name then
    return false
  end

	local handler = handlers[handler_name]
	local namespace = handler_name:match("^[^/]+")
	event_wrapper(namespace, handler, elem, e)
end

--- Add the given handler functions to the lookup with their given names
--- prepended with the namespace. These functions will be called and wrapped
--- with the wrapper of their namespace
--- @param new_handlers GuiModuleEventHandlers
--- @param namespace namespace
--- @param override_old boolean?
function gui_events.register(new_handlers, namespace, override_old)
  for name, handler in pairs(new_handlers) do
		---@cast name string
		name = namespace.."/"..name

    if type(handler) == "function" then
      if handlers[name] and handlers[name] ~= handler then
				if override_old then
					log{"gui-warnings.override-handler", name}
				else
					error({"gui-errors.handler-already-defined", name})
				end
      end
			handlers[name] = handler
    end
  end
end
---Converts the name of handlers to tags
---@param namespace namespace
---@param handler GuiModuleEventHandlerNames
---@param elem LuaGuiElement.add_param
function gui_events.convert_handler_names(namespace, handler, elem)

	---@type GuiModuleEventHandlerNames
	local handler_name
	if type(handler) == "table" then
		handler_name = {}
		for key, value in pairs(handler) do
			handler_name[tostring(key)] = namespace.."/"..value
		end
	else
		handler_name = namespace.."/"..handler
	end

	local tags = elem.tags or {}
	elem.tags = tags
	if tags[tag_key] then
		error{"gui-errors.unable-to-tag-handler"}
	end
	tags[tag_key] = handler_name
end

---@alias EventData.GuiEvents
---| EventData.on_gui_checked_state_changed
---| EventData.on_gui_click
---| EventData.on_gui_closed
---| EventData.on_gui_confirmed
---| EventData.on_gui_elem_changed
---| EventData.on_gui_hover
---| EventData.on_gui_leave
---| EventData.on_gui_location_changed
---| EventData.on_gui_opened
---| EventData.on_gui_selected_tab_changed
---| EventData.on_gui_selection_state_changed
---| EventData.on_gui_switch_state_changed
---| EventData.on_gui_text_changed
---| EventData.on_gui_value_changed

---@type event_handler.events
gui_events.events = {}
for name, id in pairs(defines.events) do
  if string.find(name, "on_gui_") then
    gui_events.events[id] = gui_events.dispatch_event
  end
end

return gui_events