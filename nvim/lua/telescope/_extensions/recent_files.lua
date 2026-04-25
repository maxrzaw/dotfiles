return require("telescope").register_extension({
    setup = function(ext_config)
        require("mzawisa.recent_files").setup(ext_config)
    end,
    exports = {
        recent_files = function(opts)
            return require("mzawisa.recent_files").open_picker(opts)
        end,
    },
})
