local utils = require("simple-popup.utils")

vim.api.nvim_create_user_command("SimplePopupFlush", "lua require('simple-popup').flushAll()", {})
vim.api.nvim_create_user_command("SimplePopupListPopups", "lua print(vim.inspect(require('simple-popup').Popups))", {})
vim.api.nvim_create_user_command("SimplePopupDev", "lua require('simple-popup.dev')", {})

---@class SimplePopupManager
local M = {}

--- comment
---@type table<string, table<integer, fun(input: any): any>>
M.Popups = {}

---comment
---@param app_id string
M.tryRegisterApp = function(app_id)
	if M.Popups[app_id] == nil then
		M.Popups[app_id] = {}
	end
end

---comment
---@param app_id string
M.unregisterApp = function(app_id)
	if M.Popups[app_id] == nil then
		print("no app found with id", app_id)

		return
	end

	M.flush(app_id)
	M.Popups[app_id] = nil
end

---comment
---@param app_id string
---@param popup_type popup_type
M.readUserInput = function(app_id, popup_type)
	if M.Popups[app_id] == nil then
		print("no app found with id", app_id)

		return
	end

	vim.cmd("stopinsert")

	local win_id = vim.api.nvim_get_current_win()

	if M.Popups[app_id][win_id] == nil then
		print("window", win_id, "does not belong to app", app_id)

		return
	end

	local callback = M.Popups[app_id][win_id]
	if callback == nil then
		print("no popup found with id", win_id, "of app", app_id)

		return
	end

	local buf_id = vim.api.nvim_win_get_buf(win_id)
	local cursor = vim.api.nvim_win_get_cursor(win_id)
	local input = {}

	if popup_type == utils.POPUP_TYPE.textbox then
		input = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
	elseif popup_type == utils.POPUP_TYPE.input then
		input = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
	else
		input = vim.api.nvim_buf_get_lines(buf_id, cursor[1] - 1, cursor[1], false)
	end

	local input_string = ""

	for i = 1, #input do
		input_string = input_string .. "\n" .. input[i]
	end

	M.deleteWindow(app_id, win_id)
	callback(vim.fn.trim(input_string))
end

---comment
---@param app_id string
---@param type popup_type
---@param level popup_level
---@param title string
---@param buf_lines string[]
---@param syntax_hl? string
---@param callback? fun(input: any): any
---@return integer
M.createPopup = function(app_id, type, level, title, buf_lines, syntax_hl, callback)
	M.tryRegisterApp(app_id)

	vim.api.nvim_list_wins()
	local buf_id = vim.api.nvim_create_buf(false, true)

	-- enable syntax highlighting
	syntax_hl = syntax_hl or "lua"
	vim.api.nvim_buf_set_option(buf_id, "filetype", syntax_hl)
	vim.api.nvim_buf_set_option(buf_id, "syntax", "enable")

	local win_title = utils.POPUP_LEVEL_ICONS[level]
		.. " "
		.. vim.fn.trim(title)
		.. " "
		.. utils.POPUP_LEVEL_ICONS[level]
	local max_line = utils.getContentMaxLine(buf_lines)
	local win_width, win_heigth = utils.getPopupSize(max_line, #buf_lines, #win_title, type)
	local win_pos_row, win_pos_col = utils.getPopupPosition(win_width, win_heigth)

	if type == utils.POPUP_TYPE.output then
		vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, buf_lines)
		vim.api.nvim_buf_set_option(buf_id, "modifiable", false)
		vim.cmd("stopinsert")
	elseif type == utils.POPUP_TYPE.select then
		vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, buf_lines)
		vim.api.nvim_buf_set_option(buf_id, "modifiable", false)
		vim.cmd("stopinsert")
	elseif type == utils.POPUP_TYPE.input then
		vim.cmd("startinsert")
	elseif type == utils.POPUP_TYPE.textbox then
		vim.cmd("startinsert")
	end

	local win_id = vim.api.nvim_open_win(buf_id, true, {
		relative = "editor",
		width = win_width,
		height = win_heigth,
		row = win_pos_row,
		col = win_pos_col,
		style = "minimal",
		border = "double",
		title = vim.fn.trim(win_title),
		title_pos = "center",
	})

	M.setBufferKeymaps(app_id, win_id, type)

	if type == utils.POPUP_TYPE.select then
		vim.api.nvim_win_set_option(win_id, "cursorline", true)
	end

	M.Popups[app_id][win_id] = callback or function() end

	return win_id
end

--- comment
--- @param app_id string
--- @param win_id integer
M.deleteWindow = function(app_id, win_id)
	if M.Popups[app_id] == nil then
		print("no app found with id", app_id)

		return
	end

	if not vim.api.nvim_win_is_valid(win_id) or M.Popups[app_id][win_id] == nil then
		print("no popup found with id", win_id, "of app", app_id)

		return
	end

	local buf_id = vim.api.nvim_win_get_buf(win_id)
	vim.api.nvim_win_close(win_id, false)
	vim.api.nvim_buf_delete(buf_id, { force = true })
	M.Popups[app_id][win_id] = nil
end

--- Sets q as keymap for quitting the given buffers popup
---@param app_id string
---@param win_id integer
---@param popup_type popup_type
M.setBufferKeymaps = function(app_id, win_id, popup_type)
	if M.Popups[app_id] == nil then
		print("no app found with id", app_id)

		return
	end

	if not vim.api.nvim_win_is_valid(win_id) then
		print("no popup found with id", win_id, "of app", app_id)

		return
	end

	local buf_id = vim.api.nvim_win_get_buf(win_id)
	local delete_win = '<cmd>lua require("simple-popup").deleteWindow("' .. app_id .. '", ' .. win_id .. ")<cr>"

	vim.keymap.set({ "n", "v" }, "q", delete_win, { buffer = buf_id })
	vim.keymap.set({ "n" }, "<ESC>", delete_win, { buffer = buf_id })

	local read_user_input_rhs = "<cmd>lua require('simple-popup').readUserInput('"
		.. app_id
		.. "', '"
		.. popup_type
		.. "')<CR>"

	if popup_type == utils.POPUP_TYPE.input then
		vim.keymap.set({ "n", "v", "i" }, "<CR>", read_user_input_rhs, { buffer = buf_id })
	elseif popup_type == utils.POPUP_TYPE.select then
		vim.keymap.set({ "n", "v", "i" }, "<CR>", read_user_input_rhs, { buffer = buf_id })
		vim.keymap.set({ "n", "v", "i" }, "<space>", read_user_input_rhs, { buffer = buf_id })
	elseif popup_type == utils.POPUP_TYPE.textbox then
		vim.keymap.set({ "n", "v" }, "<CR>", read_user_input_rhs, { buffer = buf_id })
	end
end

---comment
---@param app_id string
M.deleteAllWindows = function(app_id)
	if M.Popups[app_id] == nil then
		print("no app found with id", app_id)

		return
	end

	local num_deleted_windows = 0

	for win_id in pairs(M.Popups[app_id]) do
		M.deleteWindow(app_id, win_id)
		num_deleted_windows = num_deleted_windows + 1
	end

	print("deleted", num_deleted_windows, "windows for app", app_id)
end

---comment
---@param app_id string
M.flush = function(app_id)
	if M.Popups[app_id] == nil then
		print("no app found with id", app_id)

		return
	end

	M.deleteAllWindows(app_id)
	M.Popups[app_id] = nil

	print("deleted app", app_id)
end

---comment
M.flushAll = function()
	for app_id in pairs(M.Popups) do
		M.flush(app_id)
	end
end

return M
