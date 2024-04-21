local utils = {}

---@enum popup_type
utils.POPUP_TYPE = {
	output = "output",
	input = "input",
	textbox = "textbox",
	select = "select",
}

---@enum popup_level
utils.POPUP_LEVEL = {
	none = "none",
	info = "info",
	question = "question",
	warning = "warning",
	error = "error",
	cat = "cat",
}

---@enum popup_level_icons
utils.POPUP_LEVEL_ICONS = {
	none = "",
	info = "",
	question = "",
	warning = "",
	error = "",
	cat = "󰄛",
}

---comment
---@param content_width integer
---@param content_height integer
---@param popup_type popup_type
---@return integer, integer /width height
utils.getPopupSize = function(content_width, content_height, title_width, popup_type)
	local editor_margin = 10
	local height = 1

	if popup_type == "input" then
		height = 1
	else
		height = vim.fn.min({
			vim.api.nvim_list_uis()[1].height - 2 * editor_margin,
			vim.fn.max({ content_height, 1 }),
		})
	end

	return vim.fn.min({
		vim.api.nvim_list_uis()[1].width - 2 * editor_margin,
		vim.fn.max({ content_width + 2, title_width }),
	}),
		height
end

---comment
--- @param win_width integer
--- @param win_height integer
---@return integer, integer
utils.getPopupPosition = function(win_width, win_height)
	return vim.fn.floor((vim.api.nvim_list_uis()[1].height - win_height) * 0.5),
		vim.fn.floor((vim.api.nvim_list_uis()[1].width - win_width) * 0.5)
end

---comment
---@param content string[]
---@return number
utils.getContentMaxLine = function(content)
	local longest_line = 0

	for _, line in pairs(content) do
		longest_line = vim.fn.max({ longest_line, #line })
	end

	return longest_line
end

return utils
