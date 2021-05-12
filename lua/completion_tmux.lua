local luv = vim.loop
local completion = require "completion"
local match = require "completion.matching"

local M = {}
local cache = {}

local function extractWords(txt)
  local words = {}
  for word in string.gmatch(txt, "[%w_]+") do
    table.insert(words, word)
  end
  return words
end

local function capturePane(pane)
  local ioHandle = nil
  if nil == io.popen("tmux capture-pane -p") then
    ioHandle = io.popen("tmux capture-pane  -t {} " .. pane .. " && tmux show-buffer && tmux delete-buffer")
  else
    ioHandle = io.popen("tmux capture-pane -p -t " .. pane)
  end
  if ioHandle ~= nil then
    return extractWords(ioHandle:read("*all"))
  else
    return {}
  end
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
  return words
end

local function getCompletionItems(prefix)
  local items = getOtherPaneWords()
  local complete_items = {}
  if prefix == '' then
    return complete_items
  end
  for _, word in ipairs(items) do
    if vim.startswith(word:lower(), prefix:lower()) then
      match.matching(complete_items, prefix, {
          word = word,
          abbr = word,
          dup = 0,
          empty = 0,
          icase = 1,
          menu = '[T]',
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
