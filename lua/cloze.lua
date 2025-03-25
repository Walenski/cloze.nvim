local curl = require("plenary.curl")
local M = {}

-- default config
local config = {
  default_deck = "Default",
  model_basic = "Basic",
  model_cloze = "Cloze",
  tags = { "from_nvim" }
}

-- optional setup to override config
function M.setup(user_config)
  config = vim.tbl_deep_extend("force", config, user_config or {})
end

-- detect @deck header
local function get_deck_from_buffer(lines)
  for _, line in ipairs(lines) do
    local match = line:match("^@deck%s+(.+)$")
    if match then return vim.trim(match) end
  end
  return config.default_deck
end

-- send a single note to Anki

local function send_note_to_anki(note)
  local payload = {
    action = "addNote",
    version = 6,
    params = { note = note }
  }

  local res = curl.post("http://windowshost:8765", {
    body = vim.fn.json_encode(payload),
    headers = { ["Content-Type"] = "application/json" }
  })

  local decoded, ok = pcall(vim.fn.json_decode, res.body)

  if not ok then
    print("❌ Failed to decode response from AnkiConnect")
    return
  end

  if decoded.error then
    print("❌ " .. tostring(decoded.error))
  else
    local front = note.fields.Front or note.fields.Text or "?"
    print("✅ Added: " .. front)
  end
end



-- main function: parse and send cards
function M.send_cards_from_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local deck = get_deck_from_buffer(lines)
  local cards = {}

  for _, line in ipairs(lines) do
    line = vim.trim(line)

    -- Skip empty or comment lines
    if line ~= "" and not line:match("^@deck") and not line:match("^%s*#") then
      -- Cloze card
      if line:find("{{c%d+::") then
        table.insert(cards, {
          deckName = deck,
          modelName = config.model_cloze,
          fields = {
            Text = line,
            Extra = ""
          },
          tags = config.tags
        })
      -- Basic card with `//` syntax
      elseif line:find("//") then
        local q, a = line:match("^(.-)//(.-)$")
        if q and a then
          table.insert(cards, {
            deckName = deck,
            modelName = config.model_basic,
            fields = {
              Front = vim.trim(q),
              Back = vim.trim(a)
            },
            tags = config.tags
          })
        end
      end
    end
  end

  for _, card in ipairs(cards) do
    send_note_to_anki(card)
  end
end

-- :SendToAnki command
vim.api.nvim_create_user_command("SendToAnki", function()
  M.send_cards_from_buffer()
end, {})

return M





























-- local curl = require("plenary.curl")
-- local M = {}
--
-- local function send_note_to_anki(note)
--   local payload = {
--     action = "addNote",
--     version = 6,
--     params = {
--       note = note
--     }
--   }
--
--   local response = curl.post("http://windowshost:8765", {
--     body = vim.fn.json_encode(payload),
--     headers = {
--       ["Content-Type"] = "application/json"
--     }
--   })
--
--   return response
-- end
--
-- function M.send_cards_from_buffer()
--   local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
--   local cards = {}
--   local i = 1
--
--   while i <= #lines do
--     local line = vim.trim(lines[i])
--
--     -- Basic card: Q: ... A: ...
--     if vim.startswith(line, "Q:") then
--       local question = line:sub(3):match("^%s*(.-)%s*$")
--       local answer = ""
--       i = i + 1
--       while i <= #lines do
--         local next_line = vim.trim(lines[i])
--         if vim.startswith(next_line, "A:") then
--           answer = next_line:sub(3):match("^%s*(.-)%s*$")
--           break
--         end
--         i = i + 1
--       end
--
--       if question ~= "" and answer ~= "" then
--         table.insert(cards, {
--           deckName = "Default",
--           modelName = "Basic",
--           fields = {
--             Front = question,
--             Back = answer
--           },
--           tags = { "from_nvim" }
--         })
--       end
--     elseif line:find("{{c%d+::") then
--       -- Cloze card
--       table.insert(cards, {
--         deckName = "Default",
--         modelName = "Cloze",
--         fields = {
--           Text = line,
--           Extra = ""
--         },
--         tags = { "from_nvim" }
--       })
--     end
--     i = i + 1
--   end
--
--   for _, card in ipairs(cards) do
--     local res = send_note_to_anki(card)
--     print("Anki response: " .. res.status .. " → " .. res.body)
--   end
-- end
--
-- -- Register the :SendToAnki command
-- vim.api.nvim_create_user_command("Sendtoanki", function()
--   M.send_cards_from_buffer()
-- end, {})
--
-- return M

