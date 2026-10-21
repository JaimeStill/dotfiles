-- Noctis Obscuro, matching the kitty theme. talha-akram/noctis.nvim ports the Noctis editor theme
-- (syntax colors), so its hues are the same family as the terminal palette rather than identical;
-- the transparency in after/plugin keeps kitty's background.
return {
	{
		"talha-akram/noctis.nvim",
		lazy = false,
		priority = 1000,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "noctis_obscuro",
		},
	},
}
