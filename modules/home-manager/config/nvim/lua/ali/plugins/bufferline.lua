return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("bufferline").setup({
       options = {
        -- mode = "buffers",
        -- mode = "tabs",
        separator_style = "slant",
        offsets = {
          {
            filetype = "NvimTree",
            text = "File Explorer",
            highlight = "Directory",
            separator = true,
          }
        },
        -- show_close_icon = true,
        -- show_buffer_close_icons = false,
      },
    })
 end
}
