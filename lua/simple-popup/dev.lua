print("Simple Popup Dev Mode enabled")

vim.keymap.set("n", "<leader><leader>tp", "<cmd>Lazy reload simple-popup.nvim<CR>", {})
vim.keymap.set("n", "<leader>tpo", "<cmd>lua require('simple-popup.dev').createOutputPopup()<CR>", {})
vim.keymap.set("n", "<leader>tpi", "<cmd>lua require('simple-popup.dev').createInputPopup()<CR>", {})
vim.keymap.set("n", "<leader>tpt", "<cmd>lua require('simple-popup.dev').createTextboxPopup()<CR>", {})
vim.keymap.set("n", "<leader>tps", "<cmd>lua require('simple-popup.dev').createSelectPopup()<CR>", {})

local pm = require("simple-popup")
local app_id = "simple-popup-dev"

local dev = {}

dev.createOutputPopup = function()
  pm.createPopup(app_id, "output", "none", "test output", { "this is a test", "second row" })
end

dev.createInputPopup = function()
  pm.createPopup(app_id, "input", "none", "test input", { "this is a content test with a very long text to see" }, P)
end

dev.createTextboxPopup = function()
  pm.createPopup(app_id, "textbox", "none", "test input", {
    "this is a content test with a very long text to see, if the size will be applied row",
    "",
    "",
    "",
    "",
    "",
    "",
  }, P)
end

dev.createSelectPopup = function()
  pm.createPopup(app_id, "select", "none", "test select", { "option 1", "option 2", "option 3" }, P)
end

return dev
