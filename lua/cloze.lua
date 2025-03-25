local curl = require("plenary.curl")
local M = {}

local function send_note_to_anki(note)
  local payload = {
    action = "addNote",
    version = 6,
    params = {
      note = note
    }
  }

  local response = curl.post("http://windowshost:8765", {
    body = vim.fn.json_encode(payload),
    headers = {
      ["Content-Type"] = "application/json"
    }
  })

  return response
end

function M.send_cards_from_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cards = {}
  local i = 1

  while i <= #lines do
    local line = vim.trim(lines[i])

    -- Basic card: Q: ... A: ...
    if vim.startswith(line, "Q:") then
      local question = line:sub(3):match("^%s*(.-)%s*$")
      local answer = ""
      i = i + 1
      while i <= #lines do
        local next_line = vim.trim(lines[i])
        if vim.startswith(next_line, "A:") then
          answer = next_line:sub(3):match("^%s*(.-)%s*$")
          break
        end
        i = i + 1
      end

      if question ~= "" and answer ~= "" then
        table.insert(cards, {
          deckName = "Default",
          modelName = "Basic",
          fields = {
            Front = question,
            Back = answer
          },
          tags = { "from_nvim" }
        })
      end
    elseif line:find("{{c%d+::") then
      -- Cloze card
      table.insert(cards, {
        deckName = "Default",
        modelName = "Cloze",
        fields = {
          Text = line,
          Extra = ""
        },
        tags = { "from_nvim" }
      })
    end
    i = i + 1
  end

  for _, card in ipairs(cards) do
    local res = send_note_to_anki(card)
    print("Anki response: " .. res.status .. " → " .. res.body)
  end
end

-- Register the :SendToAnki command
vim.api.nvim_create_user_command("Sendtoanki", function()
  M.send_cards_from_buffer()
end, {})

return M

