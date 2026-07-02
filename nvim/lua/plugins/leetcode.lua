local function current_python_question()
    local ok, utils = pcall(require, "leetcode.utils")
    if not ok then
        vim.notify("leetcode.nvim is not available", vim.log.levels.ERROR)
        return
    end

    local question = utils.curr_question()
    if not question then
        return
    end

    if question.lang ~= "python3" then
        vim.notify("LeetCode test files are only supported for Python3 questions", vim.log.levels.WARN)
        return
    end

    return question
end

local function solution_path(question)
    if question.file then
        return question.file:absolute()
    end

    local path = question:path()
    return path
end

local function test_path(question)
    local path = solution_path(question)
    return path:gsub("%.py$", ".test.py")
end

local function example_args(raw)
    local lines = vim.split(raw or "", "\n", { trimempty = true })
    return table.concat(lines, ", ")
end

local function solution_signature(question)
    local path = solution_path(question)
    local lines = vim.fn.readfile(path)

    for _, line in ipairs(lines) do
        local method_name, args, return_type = line:match("^%s*def%s+([%w_]+)%((.*)%)%s*%->%s*([^:]+):")
        if method_name and args and return_type then
            return {
                method_name = method_name,
                args = args,
                return_type = vim.trim(return_type),
            }
        end
    end

    local fallback_name = question.q.meta_data and question.q.meta_data.name or "method_name"
    return {
        method_name = fallback_name,
        args = "*args: Any, **kwargs: Any",
        return_type = "Any",
    }
end

local function test_template(question)
    local solution_name = vim.fn.fnamemodify(solution_path(question), ":t")
    local signature = solution_signature(question)
    local tests = {}

    for i, raw in ipairs(question.q.testcase_list or {}) do
        table.insert(
            tests,
            string.format(
                [[def test_example_%d():
    solution = load_solution()
    result = solution.%s(%s)
    expected = None  # TODO: replace with the expected value
    assert expected is not None, "Fill in expected value for example %d"
    assert result == expected
            ]],
                i,
                signature.method_name,
                example_args(raw),
                i
            )
        )
    end

    if #tests == 0 then
        tests = {
            [[def test_example_1():
    solution = load_solution()
    # TODO: call the solution method and add assertions.
    _ = solution
    assert False, "Add a test case"
]],
        }
    end

    return string.format(
        [[from __future__ import annotations

from pathlib import Path
import importlib.util
import signal
import traceback
from typing import *

# For in-place problems, assert on the mutated inputs instead of `result`.

# Increase or decrease this per problem.
TIMEOUT_SECONDS = 2


class TestTimeoutError(Exception):
    pass


class SolutionProtocol(Protocol):
    def %s(%s) -> %s: ...


def _timeout_handler(_signum: int, _frame: object | None) -> None:
    raise TestTimeoutError(f"Timed out after {TIMEOUT_SECONDS} seconds")


def load_solution() -> SolutionProtocol:
    solution_path = Path(__file__).with_name(%q)
    spec = importlib.util.spec_from_file_location("leetcode_solution", solution_path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    solution_class = getattr(module, "Solution")
    return cast(SolutionProtocol, solution_class())


def format_assertion_error(err: AssertionError) -> str:
    message = str(err)
    tb = traceback.extract_tb(err.__traceback__)
    frame = err.__traceback__

    while frame and frame.tb_next:
        frame = frame.tb_next

    if frame:
        locals_ = frame.tb_frame.f_locals
        expected = locals_.get("expected")
        actual = locals_.get("actual", locals_.get("result"))
        if "expected" in locals_ and ("actual" in locals_ or "result" in locals_):
            details = f"expected={expected!r}, actual={actual!r}"
            return f"{message} ({details})" if message else details

    if tb:
        return message or tb[-1].line or "Assertion failed"

    return message or "Assertion failed"


# BEGIN_TESTS
%s
# END_TESTS

def run_tests():
    tests = sorted((name, fn) for name, fn in globals().items() if name.startswith("test_") and callable(fn))
    failures = 0
    previous_handler = signal.getsignal(signal.SIGALRM)

    for name, fn in tests:
        try:
            signal.signal(signal.SIGALRM, _timeout_handler)
            signal.setitimer(signal.ITIMER_REAL, TIMEOUT_SECONDS)
            fn()
            signal.setitimer(signal.ITIMER_REAL, 0)
            print(f"PASS {name}")
        except TestTimeoutError as err:
            failures += 1
            print(f"TIMEOUT {name}: {err}")
        except AssertionError as err:
            failures += 1
            print(f"FAIL {name}: {format_assertion_error(err)}")
        except Exception as err:
            failures += 1
            print(f"ERROR {name}: {err}")
        finally:
            signal.setitimer(signal.ITIMER_REAL, 0)

    signal.signal(signal.SIGALRM, previous_handler)

    if failures:
        raise SystemExit(1)

    print(f"Passed {len(tests)} test(s)")


if __name__ == "__main__":
    run_tests()
]],
        signature.method_name,
        signature.args,
        signature.return_type,
        solution_name,
        table.concat(tests, "\n")
    )
end

local function preserved_test_block(content)
    local block = content:match("# BEGIN_TESTS\n(.-)\n# END_TESTS")
    if block then
        return vim.trim(block)
    end

    block = content:match("\n\n(def test_.-)\n\ndef run_tests%(%)")
    if block then
        return vim.trim(block)
    end
end

local function sync_test_file(question, path)
    local template = test_template(question)

    if vim.fn.filereadable(path) == 0 then
        vim.fn.writefile(vim.split(template, "\n"), path)
        return
    end

    local existing = table.concat(vim.fn.readfile(path), "\n")
    local block = preserved_test_block(existing)
    if not block then
        return
    end

    local updated = template:gsub("# BEGIN_TESTS\n.-\n# END_TESTS", "# BEGIN_TESTS\n" .. block .. "\n# END_TESTS", 1)
    if updated ~= existing then
        vim.fn.writefile(vim.split(updated, "\n"), path)
    end
end

local function ensure_test_file(question)
    local path = test_path(question)
    sync_test_file(question, path)

    return path
end

local function focus_window_for_path(path)
    local normalized = vim.fn.fnamemodify(path, ":p")

    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if vim.fn.fnamemodify(buf_name, ":p") == normalized then
            vim.api.nvim_set_current_win(win)
            return true
        end
    end

    return false
end

local function close_existing_test_runner()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local ok, is_test_runner = pcall(vim.api.nvim_win_get_var, win, "leetcode_test_runner")
        if ok and is_test_runner then
            vim.api.nvim_win_close(win, true)
        end
    end
end

local function open_test_file()
    local question = current_python_question()
    if not question then
        return
    end

    local path = ensure_test_file(question)
    if focus_window_for_path(path) then
        return
    end

    vim.cmd("botright vsplit " .. vim.fn.fnameescape(path))
end

local function run_test_file()
    local question = current_python_question()
    if not question then
        return
    end

    local path = ensure_test_file(question)
    vim.cmd("silent update")
    close_existing_test_runner()
    vim.cmd("botright split")
    vim.cmd("resize 12")
    vim.cmd("terminal python3 " .. vim.fn.shellescape(path))
    vim.w.leetcode_test_runner = true
end

return {
    {
        "kawre/leetcode.nvim",
        cmd = { "Leet", "LeetTestFile", "LeetTestRun" },
        cond = not vim.g.vscode,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-treesitter/nvim-treesitter",
            "nvim-telescope/telescope.nvim",
        },
        keys = {
            {
                "<leader>lc",
                "<cmd>Leet<cr>",
                desc = "LeetCode",
            },
        },
        opts = {
            lang = "python3",
            picker = {
                provider = "telescope",
            },
            plugins = {
                non_standalone = true,
            },
            hooks = {
                enter = {
                    function()
                        vim.cmd("lsp enable basedpyright")
                        local ok, command = pcall(require, "copilot.command")
                        if ok then
                            command.disable()
                        end
                    end,
                },
                leave = {
                    function()
                        local ok, command = pcall(require, "copilot.command")
                        if ok then
                            command.enable()
                        end
                    end,
                },
            },
        },
        config = function(_, opts)
            require("leetcode").setup(opts)

            vim.api.nvim_create_user_command("LeetTestFile", open_test_file, {
                desc = "Open the current LeetCode Python test file",
            })
            vim.api.nvim_create_user_command("LeetTestRun", run_test_file, {
                desc = "Run the current LeetCode Python test file",
            })
        end,
    },
}
