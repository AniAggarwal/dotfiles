return {

{
  "chipsenkbeil/distant.nvim",
  branch = "v0.3",
  cmd = { "DistantLaunch", "DistantConnect", "DistantInstall" },
  config = function()
    require("distant").setup()
  end,
}

-- previously used vim-arysnc
}
