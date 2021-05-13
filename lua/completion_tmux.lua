local luv = vim.loop
local completion = require "completion"
local match = require "completion.matching"

local M = {}
local cache = {}

local function capturePane(pane)
  local words = {}
  local ioHandle = io.popen("tmux capture-pane -p -t " .. pane)
  for word in string.gmatch(ioHandle:read("*all"), "[%w_]+") do
    table.insert(words, word)
  end
  ioHandle:close()
  return words
end

local function getOtherPaneWords()
  local current_pane = os.getenv("TMUX_PANE")
  if current_pane == nil then return {} end
  local ioHandle = io.popen("tmux list-panes -a -F '#{pane_id}'")
  local words = {}
  for pane in ioHandle:lines() do
    if current_pane ~= pane then
      words = vim.list_extend(words, capturePane(pane))
    end
  end
  ioHandle:close()
  return words
end

local function getCompletionItems(prefix)
  local complete_items = {}
  local items = getOtherPaneWords()
  local label = vim.g.completion_customize_lsp_label["tmux"] or "tmux"
  for _, word in ipairs(items) do
    if vim.startswith(word:lower(), prefix:lower()) then
      match.matching(complete_items, prefix, {
          word = word,
          dup = 0,
          empty = 0,
          icase = 1,
          kind = label,
          user_data = vim.fn.json_encode({ hover = "tmux completion" })
        })
    end
  end
  return complete_items
end

function M.add_sources()
  completion.addCompletionSource('tmux', { item = getCompletionItems });
  -- Cache on init
end

return M
