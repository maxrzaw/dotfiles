PLENARY_PATH := $(HOME)/.local/share/nvim/lazy/plenary.nvim

.PHONY: test-recent-files-unit

test-recent-files-unit:
	nvim --headless -u tests/minimal_init.lua -c "set rtp+=$(PLENARY_PATH) | runtime plugin/plenary.vim | PlenaryBustedDirectory tests/unit/recent_files { minimal_init = 'tests/minimal_init.lua' }"
