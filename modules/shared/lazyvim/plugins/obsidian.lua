return {
	"epwalsh/obsidian.nvim",
	version = "*",
	lazy = false,
	ft = "markdown",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("obsidian").setup({
			workspaces = {
				{ name = "personal", path = "~/Obsidian" },
			},
			completion = {
				nvim_cmp = false,
				min_chars = 2,
			},
		})
	end,
}
