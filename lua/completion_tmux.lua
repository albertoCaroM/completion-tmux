local luv = vim.loop
local completion = require "completion"
local match = require "completion.matching"

local M = {}
local cache = {}

local function extractWords(txt)
  local words = {}
  for word in string.gmatch(txt, "[%w_]+") do
    words[word] = "tmux completion"
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
  local ioHandle = io.popen("tmux list-panes $LISTARGS -F '#{pane_active}#{window_active}-#{session_id} #{pane_id}'")
  local list_panes_txt = ioHandle:read("*all")

  local list_panes = {}
  --[[
  list_panes format is a structured text like:
  11-$0 %7
  01-$0 %3
  we need to get the part of %num
  ]]--
  for pane in string.gmatch(list_panes_txt, "%%%d+") do
    if current_pane ~= pane then
      table.insert(list_panes, pane)
    end
  end

  local list_words = {}
  for _, val in ipairs(list_panes) do
    for k, v in pairs(capturePane(val)) do
      list_words[k] = "tmux completion"
    end
  end
  return list_words
end

local function getCompletionItems(prefix)
  local items = getOtherPaneWords()
  local complete_items = {}
  if prefix == '' then
    return complete_items
  end
  for word, paths in pairs(items) do
    if vim.startswith(word:lower(), prefix:lower()) then
      match.matching(complete_items, prefix, {
          word = word,
          abbr = word,
          dup = 0,
          empty = 0,
          icase = 1,
          menu = '[T]',
          user_data = vim.fn.json_encode({ hover = paths })
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
