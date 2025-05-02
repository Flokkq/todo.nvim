local M = {}
local uv = vim.loop
local fn = vim.fn


local function normalize(path)
  path = fn.fnamemodify(path, ':p')
  path = path:gsub('/+$', '')
  path = path:gsub('//+', '/')
  return path
end

local function current_dir()
  local bufname = vim.api.nvim_buf_get_name(0)

  if bufname:match('^oil://') then
    local p = fn.fnamemodify(bufname:gsub('^oil://', ''), ':p')
    if fn.isdirectory(p) == 1 then
      return normalize(p)
    else
      return normalize(fn.fnamemodify(p, ':h'))
    end
  end

  if bufname ~= '' then
    return normalize(fn.fnamemodify(bufname, ':p:h'))
  end

  return normalize(uv.cwd())
end

local function open_markdown(path)
  local buf = vim.fn.bufnr(path, true)
  vim.fn.bufload(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn.readfile(path))
  vim.api.nvim_buf_set_option(buf, 'modified',  false)
  vim.api.nvim_buf_set_option(buf, 'filetype',  'markdown')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'buflisted', false)

  local w  = math.floor(vim.o.columns * 0.75)
  local h  = math.floor(vim.o.lines   * 0.75)
  local row = math.floor((vim.o.lines   - h) / 2)
  local col = math.floor((vim.o.columns - w) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    style    = 'minimal',
    border   = 'rounded',
    width    = w,
    height   = h,
    row      = row,
    col      = col,
  })
end

local function show_picker(list, opener)
  local buf = vim.api.nvim_create_buf(false, true)

  local rel = {}
  for _, p in ipairs(list) do
    table.insert(rel, fn.fnamemodify(p, ':~:.'))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, rel)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  local w  = math.max(20, math.floor(vim.o.columns * 0.30))
  local h  = #list
  local row = math.floor((vim.o.lines - h) / 2)
  local col = math.floor((vim.o.columns - w) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    style    = 'minimal',
    border   = 'rounded',
    width    = w,
    height   = h,
    row      = row,
    col      = col,
  })

  local function map(lhs, rhs)
    vim.keymap.set('n', lhs, rhs, { buffer = buf, nowait = true, silent = true })
  end
  map('<Esc>', function() vim.api.nvim_win_close(win, true) end)
  map('<CR>', function()
    local lnum = vim.fn.line('.')
    vim.api.nvim_win_close(win, true)
    opener(list[lnum])
  end)
end

local function find_downwards()
  local base  = current_dir()
  local found, seen = {}, {}

  local function add(p)
    p = normalize(p)
    if fn.filereadable(p) == 1 and not seen[p] then
      table.insert(found, p)
      seen[p] = true
    end
  end

  add(base .. '/TODO.md')

  if vim.fs and vim.fs.find then
    for _, p in ipairs(vim.fs.find('TODO.md', { path = base, type = 'file', limit = 0 })) do
      add(p)
    end
  else
    for _, p in ipairs(fn.globpath(base, '**/TODO.md', true, true)) do
      add(p)
    end
  end
  return found
end

local function find_upwards()
  local res, seen = {}, {}
  local dir = current_dir()

  while dir ~= '' do
    local p = normalize(dir .. '/TODO.md')
    if fn.filereadable(p) == 1 and not seen[p] then
      table.insert(res, p)
      seen[p] = true
    end
    local parent = normalize(fn.fnamemodify(dir, ':h'))
    if parent == dir then break end
    dir = parent
  end
  return res
end

function M.open()
  local list = find_downwards()
  if #list > 0 then
    if #list == 1 then
      return open_markdown(list[1])
    end
    return show_picker(list, open_markdown)
  end

  list = find_upwards()
  if #list == 0 then
    return vim.notify('No TODO.md found (downwards or upwards)', vim.log.levels.ERROR)
  end
  if #list == 1 then
    return open_markdown(list[1])
  end
  show_picker(list, open_markdown)
end

return M
