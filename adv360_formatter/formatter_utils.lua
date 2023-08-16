local parsers = require('nvim-treesitter.parsers')
local ts = vim.treesitter

local M = {}

M.get_bufnr = vim.api.nvim_get_current_buf

function p(value) print(vim.inspect(value)) end

---@param node TSNode
function t(node)
  p(M.gnt(node))
end

---@param node TSNode
---@return string | nil
M.gnt = function(node)
  local bufnr = M.get_bufnr()
  local ok, result = pcall(ts.get_node_text, node, bufnr)
  if ok then
    return result
  end
end

---@return TSNode, integer
M.get_root_node = function()
  local bufnr = M.get_bufnr()
  local lang = parsers.get_buf_lang(bufnr)
  local parser = parsers.get_parser(bufnr, lang)
  ---@type TSTree
  local tree = parser:parse()[1]
  return tree:root(), bufnr
end

---@param node TSNode
---@param key string
---@return TSNode | nil, string | nil
M.get_field = function(node, key)
  ---@type TSNode[] | nil
  local field_node = node:field(key)
  if not field_node then
    return nil, nil
  end

  local field = field_node[1]
  -- local field_text_node = field:type() == 'string' and field:named_child(0) or field
  return field, M.gnt(field)
end

---@return string | nil
M.get_field_text = function(node, key)
  local _, text = M.get_field(node, key)
  return text
end

---@param node TSNode
---@param type string
---@return fun():TSNode, string
M.get_children_by_type = function(node, type)
  return coroutine.wrap(function()
    for _, child in ipairs(node:named_children()) do
      if child:type() == type then
        coroutine.yield(child, gnt(child))
      end
    end
  end)
end

---@param node TSNode
---@param type string
---@return TSNode | nil, string | nil
M.get_first_child_by_type = function(node, type)
  for _, child in ipairs(node:named_children()) do
    if child:type() == type then
      return child, gnt(child)
    end
  end
end

---@param node TSNode
---@param key string
---@return TSNode | nil
M.get_child_pair_by_key = function(node, key)
  for _, child in ipairs(node:named_children()) do
    local _, inner_key = M.get_field(child, 'key')
    if child:type() == 'pair' and key == inner_key then
      return child
    end
  end
end

---@param node TSNode
---@param key string
---@return TSNode | nil, string | nil
M.get_child_value_by_key = function(node, key)
  if node:type() == 'pair' then
    return M.get_field(node, 'value')
  end

  if node:type() == 'object' then
    for _, child in ipairs(node:named_children()) do
      local _, inner_key = M.get_field(child, 'key')
      if child:type() == 'pair' and key == inner_key then
        return M.get_field(child, 'value')
      end
    end
  end
end

---@param node TSNode
---@return string[] | nil
M.parse_string_array = function(node)
  assert(node:type() == 'array', 'node type not "array"')
  local result = {}
  for _, child in ipairs(node:named_children()) do
    local value = child:named_child(0)
    if value then
      table.insert(result, M.gnt(value))
    end
  end
  return result
end

---get the indentation level of `line`
---@param line integer
---@param bufnr integer | nil
---@return string | nil, string | nil
M.get_indent_for_line = function(line, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local indent_count = ts_indent.get_indent(line)
  local tabstop = vim.api.nvim_buf_get_option(bufnr, 'tabstop')
  local expandtab = vim.api.nvim_buf_get_option(bufnr, 'expandtab')
  local ntabs = (indent_count / tabstop)
  local tab = string.rep(" ", tabstop)
  local indent = expandtab and string.rep(" ", tabstop * ntabs) or string.rep("\t", ntabs)
  return indent, tab
end

---@param lines string[]
local sanitize_newlines = function(lines)
  local result = {}
  for _, line in ipairs(lines) do
    for split in string.gmatch(line, '[^\n|\r]+') do
      table.insert(result, split)
    end
  end
  return result
end

---@param node TSNode
---@param bufnr integer | nil
---@param replacement string[]
M.replace_text = function(node, bufnr, replacement)
  bufnr = bufnr or M.get_bufnr()
  replacement = sanitize_newlines(replacement)
  local start_row, start_col, end_row, end_col = node:range()
  vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, replacement)
end

---@param replacements { node: TSNode, replacement: string[] }[]
M.bulk_replace_lines = function(replacements)
  local _, bufnr = M.get_root_node()
  table.sort(replacements, function(a, b)
    local a_start_row, _, _, _ = a.node:range()
    local b_start_row, _, _, _ = b.node:range()
    if a_start_row == b_start_row then
      local _, a_start_col, _, _ = a.node:range()
      local _, b_start_col, _, _ = b.node:range()
      return a_start_col > b_start_col
    else
      return a_start_row > b_start_row
    end
  end)
  for _, item in ipairs(replacements) do
    M.replace_text(item.node, bufnr, item.replacement)
  end
end


---@param match_index integer | nil
---@param querystring string
---@param node TSNode | nil
---@param limit integer | nil
---@return table<integer, TSNode>
M.get_query_results = function(match_index, querystring, node, limit)
  match_index = match_index or 0
  local root, bufnr = M.get_root_node()
  node = node or root
  local lang = parsers.get_buf_lang(bufnr)
  local query = ts.query.parse(lang, querystring)
  local results = {}
  local count = 0
  for _, matches, _ in query:iter_matches(node, bufnr, node:start(), node:end_()) do
    local match = matches[match_index]

    if match then
      table.insert(results, match)
    end

    count = count + 1
    if limit and count >= limit then
      return results
    end
  end
  return results
end

return M
