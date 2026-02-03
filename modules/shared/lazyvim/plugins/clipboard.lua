-- Custom OSC 52 clipboard - runs AFTER LazyVim init

local function setup_clipboard()
  local function osc52_copy(text)
    local encoded = vim.base64.encode(text)
    local osc = string.format("\027]52;c;%s\027\\", encoded)
    io.stderr:write(osc)
    io.stderr:flush()
  end

  local function copy(lines, _)
    osc52_copy(table.concat(lines, "\n"))
  end

  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end

  vim.g.clipboard = {
    name = "OSC 52 (tmux)",
    copy = { ["+"] = copy, ["*"] = copy },
    paste = { ["+"] = paste, ["*"] = paste },
  }

  vim.opt.clipboard = "unnamedplus"
end

-- Run after everything with defer
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(setup_clipboard, 100)
  end,
})

return {}
