local ts = vim.treesitter
local tsquery = require('nvim-treesitter.query')
local u = reload('adv360_formatter.formatter_utils')

local M = {}

local borders = {
  horizontal = '─',
  vertical = '│',
  table_header_separator = '┬',
  column_intersection = '┼',
  table_footer_separator = '┴',
  table_left_separator = '├',
  table_right_separator = '┤',
  upper_left_corner = '┌',
  bottom_left_corner = '└',
  upper_right_corner = '┐',
  bottom_right_corner = '┘',
}

---@type { row: number, col: number, node: TSNode | nil, blank: boolean }
local Cell = {
  row = -1,
  col = -1,
  node = nil,
  blank = false,
}

---@param props { row: number, col: number, node: TSNode | nil, blank: boolean | nil }
function Cell:new(props)
  local cell = {
    row = props.row,
    col = props.col,
    node = props.node,
    blank = props.blank or false,
  }
  setmetatable(cell, self)
  self.__index = self
  return cell
end

local Bindings = {}
Bindings.__index = Bindings

function Bindings:new()
  local cells = {
    { Cell:new({ row = 1, col = 1 }), Cell:new({ row = 1, col = 2 }), Cell:new({ row = 1, col = 3 }),
      Cell:new({ row = 1, col = 4 }), Cell:new({ row = 1, col = 5 }), Cell:new({ row = 1, col = 6 }),
      Cell:new({ row = 1, col = 7 }),
      Cell:new({ row = 1, col = 8, blank = true }), Cell:new({ row = 1, col = 9, blank = true }),
      Cell:new({ row = 1, col = 10, blank = true }), Cell:new({ row = 1, col = 11, blank = true }),
      Cell:new({ row = 1, col = 12, blank = true }), Cell:new({ row = 1, col = 13, blank = true }),
      Cell:new({ row = 1, col = 14, blank = true }), Cell:new({ row = 1, col = 15, blank = true }),
      Cell:new({ row = 1, col = 16 }), Cell:new({ row = 1, col = 17 }), Cell:new({ row = 1, col = 18 }),
      Cell:new({ row = 1, col = 19 }), Cell:new({ row = 1, col = 20 }), Cell:new({ row = 1, col = 21 }),
      Cell:new({ row = 1, col = 22 }), },
    { Cell:new({ row = 2, col = 1 }), Cell:new({ row = 2, col = 2 }), Cell:new({ row = 2, col = 3 }),
      Cell:new({ row = 2, col = 4 }), Cell:new({ row = 2, col = 5 }), Cell:new({ row = 2, col = 6 }),
      Cell:new({ row = 2, col = 7 }),
      Cell:new({ row = 2, col = 8, blank = true }), Cell:new({ row = 2, col = 9, blank = true }),
      Cell:new({ row = 2, col = 10, blank = true }), Cell:new({ row = 2, col = 11, blank = true }),
      Cell:new({ row = 2, col = 12, blank = true }), Cell:new({ row = 2, col = 13, blank = true }),
      Cell:new({ row = 2, col = 14, blank = true }), Cell:new({ row = 2, col = 15, blank = true }),
      Cell:new({ row = 2, col = 16 }), Cell:new({ row = 2, col = 17 }), Cell:new({ row = 2, col = 18 }),
      Cell:new({ row = 2, col = 19 }), Cell:new({ row = 2, col = 20 }), Cell:new({ row = 2, col = 21 }),
      Cell:new({ row = 2, col = 22 }), },
    { Cell:new({ row = 3, col = 1 }), Cell:new({ row = 3, col = 2 }), Cell:new({ row = 3, col = 3 }),
      Cell:new({ row = 3, col = 4 }), Cell:new({ row = 3, col = 5 }), Cell:new({ row = 3, col = 6 }),
      Cell:new({ row = 3, col = 7 }),
      Cell:new({ row = 3, col = 8, blank = true }), Cell:new({ row = 3, col = 9 }),
      Cell:new({ row = 3, col = 10 }), Cell:new({ row = 3, col = 11 }), Cell:new({ row = 3, col = 12 }),
      Cell:new({ row = 3, col = 13 }), Cell:new({ row = 3, col = 14 }), Cell:new({ row = 3, col = 15, blank = true }),
      Cell:new({ row = 3, col = 16 }), Cell:new({ row = 3, col = 17 }), Cell:new({ row = 3, col = 18 }),
      Cell:new({ row = 3, col = 19 }), Cell:new({ row = 3, col = 20 }), Cell:new({ row = 3, col = 21 }),
      Cell:new({ row = 3, col = 22 }), },
    { Cell:new({ row = 4, col = 1 }), Cell:new({ row = 4, col = 2 }), Cell:new({ row = 4, col = 3 }),
      Cell:new({ row = 4, col = 4 }), Cell:new({ row = 4, col = 5 }), Cell:new({ row = 4, col = 6 }),
      Cell:new({ row = 4, col = 7, blank = true }),
      Cell:new({ row = 4, col = 8 }), Cell:new({ row = 4, col = 9 }),
      Cell:new({ row = 4, col = 10 }), Cell:new({ row = 4, col = 11 }), Cell:new({ row = 4, col = 12 }),
      Cell:new({ row = 4, col = 13 }), Cell:new({ row = 4, col = 14 }), Cell:new({ row = 4, col = 15 }),
      Cell:new({ row = 4, col = 16, blank = true }), Cell:new({ row = 4, col = 17 }), Cell:new({ row = 4, col = 18 }),
      Cell:new({ row = 4, col = 19 }), Cell:new({ row = 4, col = 20 }), Cell:new({ row = 4, col = 21 }),
      Cell:new({ row = 4, col = 22 }), },
    { Cell:new({ row = 5, col = 1 }), Cell:new({ row = 5, col = 2 }), Cell:new({ row = 5, col = 3 }),
      Cell:new({ row = 5, col = 4 }), Cell:new({ row = 5, col = 5 }), Cell:new({ row = 5, col = 6, blank = true }),
      Cell:new({ row = 5, col = 7, blank = true }),
      Cell:new({ row = 5, col = 8 }), Cell:new({ row = 5, col = 9 }),
      Cell:new({ row = 5, col = 10 }), Cell:new({ row = 5, col = 11, blank = true }),
      Cell:new({ row = 5, col = 12, blank = true }), Cell:new({ row = 5, col = 13 }), Cell:new({ row = 5, col = 14 }),
      Cell:new({ row = 5, col = 15 }),
      Cell:new({ row = 5, col = 16, blank = true }), Cell:new({ row = 5, col = 17, blank = true }),
      Cell:new({ row = 5, col = 18 }),
      Cell:new({ row = 5, col = 19 }), Cell:new({ row = 5, col = 20 }), Cell:new({ row = 5, col = 21 }),
      Cell:new({ row = 5, col = 22 }), },
  }
  setmetatable({}, self)
  self.cells = cells

  self.iter_cells = function()
    return coroutine.wrap(function()
      for _, row in ipairs(self.cells) do
        for _, cell in ipairs(row) do
          coroutine.yield(cell)
        end
      end
    end)
  end

  self.iter_rows = function()
    return coroutine.wrap(function()
      for _, row in ipairs(self.cells) do
        coroutine.yield(row)
      end
    end)
  end

  self.iter_cols = function()
    local col_count = #self.cells[1]
    return coroutine.wrap(function()
      for i = 1, col_count do
        local col = self:get_col(i)
        coroutine.yield(col)
      end
    end)
  end

  return self
end

---@param col 1 | 2 | 3 | 4 | 5
function Bindings:get_col(col)
  local cells = {}
  for row = 1, #self.cells do
    local cell = self.cells[row][col]
    table.insert(cells, cell)
  end
  return cells
end

---@param row number
function Bindings:get_row(row)
  local cells = {}
  for col = 0, #self.cells[1] do
    local cell = self.cells[row][col]
    table.insert(cells, cell)
  end
  return cells
end

function Bindings:max_length_in_column(col)
  ---@type Cell[]
  local cells = self:get_col(col)
  local max = 0
  for _, cell in ipairs(cells) do
    if cell.behavior then
      max = math.max(#cell.behavior, max)
    end
  end
end

local function get_keymap_layers()
  local match_index = 3
  return u.get_query_results(match_index, [[
    (node
      name: (identifier) @keymap_node (#eq? @keymap_node "keymap")
      (node
        (property
          name: (identifier) @name (#eq? @name "bindings")
          value: (integer_cells
                   (reference)) @cells)))
  ]])
end

---@param layer TSNode
---@return table<integer, TSNode>
local function get_layer_refs(layer)
  return u.get_query_results(1, [[ (reference) @ref ]], layer)
end

---@param parent TSNode
---@return table<integer, { ref: TSNode, siblings: table<integer, TSNode>, text: string }>
local function get_behavior_nodes(parent)
  ---@type table<integer, { ref: TSNode, siblings: table<integer, TSNode>, text: string }>
  local references = {}
  for _, child in ipairs(parent:named_children()) do
    if child:type() == 'reference' then
      ---@type { ref: TSNode, siblings: table<integer, TSNode > }
      local ref = { ref = child, siblings = {} }
      local s = u.gnt(child)
      local sib = child:next_named_sibling()
      while sib and sib:type() == 'identifier' or sib:type() == 'call_expression' do
        s = s .. ' ' .. u.gnt(sib)
        table.insert(ref.siblings, sib)
        sib = sib:next_named_sibling()
      end
      ref.text = s
      table.insert(references, ref)
    end
  end
  return references
end

---@param layer_node TSNode
local format_layer_bindings = function(layer_node)
  local refs = get_behavior_nodes(layer_node)

  local bindings = Bindings:new()
  local i = 1
  for _, row in ipairs(bindings.cells) do
    for _, cell in ipairs(row) do
      if not cell.blank then
        cell.node = refs[i]
        i = i + 1
      end
    end
  end

  for row in bindings.iter_rows() do
    for _, cell in ipairs(row) do
      if cell.node and #cell.node.siblings > -1 then
        local s = u.gnt(cell.node.ref)
        for _, sib in ipairs(cell.node.siblings) do
          s = s .. ' ' .. u.gnt(sib)
        end
        p(s)
      end
    end
    p('----------')
  end
end

-- M.format = function()
local keymaps = get_keymap_layers()
local layer_one = keymaps[1]
-- for _, layer_bindings in ipairs(keymaps) do
format_layer_bindings(layer_one)
-- end
-- end

return M
