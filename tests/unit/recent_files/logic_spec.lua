local logic = require("mzawisa.recent_files.logic")

describe("recent_files.logic", function()
    describe("relative_to_root", function()
        it("returns a relative path inside the root", function()
            local relative = logic.relative_to_root(
                "/tmp/project/lua/file.lua",
                "/tmp/project",
                function(path)
                    return path
                end
            )

            assert.are.equal("lua/file.lua", relative)
        end)

        it("returns dot for the root itself", function()
            local relative = logic.relative_to_root(
                "/tmp/project",
                "/tmp/project",
                function(path)
                    return path
                end
            )

            assert.are.equal(".", relative)
        end)

        it("returns nil for paths outside the root", function()
            local relative = logic.relative_to_root(
                "/tmp/other/file.lua",
                "/tmp/project",
                function(path)
                    return path
                end
            )

            assert.is_nil(relative)
        end)
    end)

    describe("branch_from_ref", function()
        it("strips refs heads prefix", function()
            assert.are.equal("main", logic.branch_from_ref("refs/heads/main"))
        end)

        it("returns branch names unchanged", function()
            assert.are.equal("develop", logic.branch_from_ref("develop"))
        end)
    end)

    describe("get_target_branch", function()
        it("prefers per repo overrides", function()
            local branch = logic.get_target_branch({
                default_branch = "main",
                repo_overrides = {
                    ["/repo/.git"] = "develop",
                },
            }, "/repo/.git")

            assert.are.equal("develop", branch)
        end)

        it("falls back to the configured default branch", function()
            local branch = logic.get_target_branch({
                default_branch = "trunk",
                repo_overrides = {},
            }, "/repo/.git")

            assert.are.equal("trunk", branch)
        end)

        it("falls back to main", function()
            assert.are.equal("main", logic.get_target_branch({}, "/repo/.git"))
        end)
    end)

    describe("dedupe_key", function()
        it("uses repo family and relative path for git records", function()
            local key = logic.dedupe_key({
                file = "/tmp/worktree-a/lua/file.lua",
                git_common_dir = "/tmp/repo/.git",
                relative_path = "lua/file.lua",
            })

            assert.are.equal("git:/tmp/repo/.git:lua/file.lua", key)
        end)

        it("uses the absolute file path for non-git records", function()
            local key = logic.dedupe_key({
                file = "/tmp/notes.md",
            })

            assert.are.equal("file:/tmp/notes.md", key)
        end)
    end)

    describe("sort_records", function()
        it("sorts records by most recent first", function()
            local records = logic.sort_records({
                { file = "b", last_accessed = 20 },
                { file = "c", last_accessed = 10 },
                { file = "a", last_accessed = 30 },
            })

            assert.are.same({ "a", "b", "c" }, vim.tbl_map(function(record)
                return record.file
            end, records))
        end)
    end)

    describe("trim_records", function()
        it("keeps only the newest configured number of records", function()
            local records = logic.trim_records({
                { file = "a" },
                { file = "b" },
                { file = "c" },
            }, 2)

            assert.are.same({ "a", "b" }, vim.tbl_map(function(record)
                return record.file
            end, records))
        end)
    end)

    describe("pick_representatives", function()
        it("dedupes git records by repo family and relative path", function()
            local records = {
                {
                    file = "/tmp/worktree-b/lua/file.lua",
                    git_common_dir = "/tmp/repo/.git",
                    relative_path = "lua/file.lua",
                    last_accessed = 20,
                },
                {
                    file = "/tmp/worktree-a/lua/file.lua",
                    git_common_dir = "/tmp/repo/.git",
                    relative_path = "lua/file.lua",
                    last_accessed = 10,
                },
                {
                    file = "/tmp/worktree-a/lua/other.lua",
                    git_common_dir = "/tmp/repo/.git",
                    relative_path = "lua/other.lua",
                    last_accessed = 5,
                },
            }

            local representatives = logic.pick_representatives(records)
            assert.are.same({
                "/tmp/worktree-b/lua/file.lua",
                "/tmp/worktree-a/lua/other.lua",
            }, vim.tbl_map(function(record)
                return record.file
            end, representatives))
        end)

        it("supports filtering before deduping", function()
            local representatives = logic.pick_representatives({
                {
                    file = "/tmp/worktree-b/lua/file.lua",
                    git_common_dir = "/tmp/repo/.git",
                    relative_path = "lua/file.lua",
                },
                {
                    file = "/tmp/notes.md",
                },
            }, function(record)
                return record.git_common_dir ~= nil
            end)

            assert.are.same({ "/tmp/worktree-b/lua/file.lua" }, vim.tbl_map(function(record)
                return record.file
            end, representatives))
        end)

        it("does not dedupe same relative path across different repos", function()
            local representatives = logic.pick_representatives({
                {
                    file = "/tmp/repo-a/lua/file.lua",
                    git_common_dir = "/tmp/repo-a/.git",
                    relative_path = "lua/file.lua",
                    last_accessed = 20,
                },
                {
                    file = "/tmp/repo-b/lua/file.lua",
                    git_common_dir = "/tmp/repo-b/.git",
                    relative_path = "lua/file.lua",
                    last_accessed = 10,
                },
            })

            assert.are.same({
                "/tmp/repo-a/lua/file.lua",
                "/tmp/repo-b/lua/file.lua",
            }, vim.tbl_map(function(record)
                return record.file
            end, representatives))
        end)
    end)
end)
