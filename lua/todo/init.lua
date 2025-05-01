local M = {}
local uv = vim.loop
local fn = vim.fn

function M.find_todo()
  local bufname = vim.api.nvim_buf_get_name(0)
  local dir

  if bufname:match("^oil://") then
    local path = bufname:gsub("^oil://", "")
    path = fn.fnamemodify(path, ":p")
    if fn.isdirectory(path) == 1 then
      dir = path
    else
      dir = fn.fnamemodify(path, ":p:h")
    end

  elseif bufname ~= "" then
    dir = fn.fnamemodify(bufname, ":p:h")

  else
    dir = uv.cwd()
  end

  dir = fn.fnamemodify(dir, ":p")

  while dir and dir ~= "" do
    local todo = dir .. "/TODO.md"
    if fn.filereadable(todo) == 1 then
      return todo
    end
    local parent = fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  return nil
end

function M.open()
  local file = M.find_todo()
  if not file then
    return vim.notify('No TODO.md found in parent directories', vim.log.levels.ERROR)
  end

  local buf = vim.fn.bufnr(file, true)
  vim.fn.bufload(buf)

  vim.api.nvim_buf_set_lines(
    buf, 0, -1, false,
    vim.fn.readfile(file)
  )
  vim.api.nvim_buf_set_option(buf, 'modified', false)

  vim.api.nvim_buf_set_option(buf, 'filetype',  'markdown')
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'buflisted', false)

  local width  = math.floor(vim.o.columns * 0.75)
  local height = math.floor(vim.o.lines   * 0.75)
  local row    = math.floor((vim.o.lines   - height) / 2)
  local col    = math.floor((vim.o.columns - width ) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width    = width,
    height   = height,
    row      = row,
    col      = col,
    style    = 'minimal',
    border   = 'rounded',
  })
end

return M
