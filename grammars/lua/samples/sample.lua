-- Idiomatic Lua exercising the constructs this profile claims to understand.
--
-- Authored for this repo. Construct coverage was cross-checked against
-- tree-sitter-lua's own test/corpus node kinds (chunk, statements, expressions)
-- — read as a checklist, not copied.
--
-- Lua has no class or module construct: a "class" is a table with a metatable,
-- and a "module" is a table you return. So the only kind that can ever be a
-- container is `function_declaration`, and the deepest breadcrumb this language
-- produces is `function > statement`. What this sample must prove is that every
-- statement kind is labelled, that none is wrongly promoted to a landmark, and
-- that both function spellings — `function M.f()` and `local f = function()` —
-- are recognised.

local Invoice = {}
Invoice.__index = Invoice

local DEFAULT_TAX_RATE <const> = 1.2
local MAX_RETRIES = 3

local statuses = {
  draft = "draft",
  paid = "paid",
}

-- The metatable constructor idiom: a named function returning a table with a
-- metatable attached. Holds a conditional and an assignment.
function Invoice.new(lines, state)
  local self = setmetatable({}, Invoice)

  if type(lines) ~= "table" then
    error("Invoice.new expects a table of lines", 2)
  end

  self.lines = lines
  self.state = state or statuses.draft
  self.total = 0.0
  return self
end

-- A method (colon syntax) whose body holds a generic `for` containing an
-- `if`/`elseif`/`else` chain — two statement levels inside one declaration.
function Invoice:compute()
  local sum = 0.0

  for _, line in ipairs(self.lines) do
    if line.void then
      goto continue
    elseif line.taxable then
      sum = sum + line.amount * DEFAULT_TAX_RATE
    else
      sum = sum + line.amount
    end

    ::continue::
  end

  self.total = sum
  return sum
end

-- A numeric `for` and a `while`, the two remaining loop spellings.
function Invoice:retry(send)
  local attempts = 0

  for attempt = 1, MAX_RETRIES do
    local ok, err = pcall(send, self)
    if ok then
      return true
    end
    attempts = attempt
    io.stderr:write(string.format("attempt %d failed: %s\n", attempt, err))
  end

  while attempts < MAX_RETRIES do
    attempts = attempts + 1
  end

  return false
end

-- `repeat ... until` and a bare `do` block, which the old sample never reached.
function Invoice:drain(queue)
  local drained = {}

  repeat
    local item = table.remove(queue)
    if item ~= nil then
      drained[#drained + 1] = item
    end
  until item == nil or #drained >= MAX_RETRIES

  do
    local label = tostring(#drained)
    drained.label = label
  end

  return drained
end

function Invoice:__tostring()
  return string.format("Invoice(%s, %.2f)", self.state, self.total)
end

-- An anonymous function bound to a local: the landmark tier that has no name
-- field of its own, since the name lives on the enclosing declaration.
local formatMoney = function(value)
  return math.floor(value * 100 + 0.5) / 100
end

-- The same anonymous shape, assigned to a table field rather than a local.
Invoice.describe = function(self)
  local money = formatMoney(self.total)
  return "total: " .. money
end

-- A function taking a callback, so a `function_definition` appears as an
-- argument rather than on the right of an assignment.
local function eachLine(invoice, visit)
  for index = 1, #invoice.lines do
    visit(index, invoice.lines[index])
  end
end

return {
  Invoice = Invoice,
  eachLine = eachLine,
  formatMoney = formatMoney,
}
