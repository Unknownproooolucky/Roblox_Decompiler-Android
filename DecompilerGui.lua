local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

_G.Debug = false

if not _G.Debug then
    _G.Window = OrionLib:MakeWindow({Name = "Decompiler Mode", HidePremium = false, SaveConfig = true, ConfigFolder = "OrionTest"})
elseif _G.Debug then
	_G.Window = OrionLib:MakeWindow({Name = "DebugMode", HidePremium = false, SaveConfig = true, ConfigFolder = "OrionTest"})
end

local Tab = _G.Window:MakeTab({
	Name = "Tab 1",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local Libraries = {"task","os","utf8","table","string","math","debug","coroutine","buffer","bit32"}
function startswith(str, thing)
if str:sub(1, #thing) == thing then return true else return false end
end
function pKey(key)
  if startswith(tostring(key), "__") then
   return tostring(key)
  end
  if type(key) == "number" then
      return "["..tostring(key).."]"
  else
      return "[\"" .. tostring(key) .. "\"]"
  end
end
function GetMetaMethods(regularTable)
 local meta = getmetatable(regularTable)
 if not meta then return {} end
 setreadonly(meta, false);
 local mms = {}
 for i, v in meta do
  if startswith(tostring(i), "__") then
   table.insert(mms, {Name=i, Value=v})
  end
 end
 return mms
end
function GetFullName(instance)
 local p = instance
 local lo = {}
 while (p ~= game and p.Parent ~= nil) do
  table.insert(lo, p)
  p = p.Parent
 end
 local fullName;
 if #lo == 0 then return "nil -- Instance parented to nil" end
 if lo[#lo].ClassName ~= "Workspace" then
  fullName = "game:GetService(\"" .. lo[#lo].ClassName.."\")"
 else
  fullName = "workspace"
 end
 for i = #lo - 1, 1, -1 do
  fullName = fullName .. ":FindFirstChild(\"" .. lo[i].Name .. "\")"
 end
 return fullName
end
function processTableDescendants(tbl, indent, tblname)
  indent = indent or 0
  tblname = tblname or "{}"
  local metacount1 = 1
  local result = ""
  local count = 1
  for key, value in pairs(tbl) do
      if type(value) == "table" and not startswith(tostring(key), "__") then
          result = result .. string.rep("  ", indent) .. pKey(key) .. " = {"
          if #value == 0 then result = result .. "}" else
          result = result .. "\n" .. processTableDescendants(value, indent + 1)
          result = result .. string.rep("  ", indent) .. "}\n" end
          if getrawmetatable(value) ~= nil then
           result = result .. string.rep("  ", indent) .. "local meta" .. tostring(metacount1) .. " = setmetatable(" .. tostring(tblname) .. ", {})\n"
           count+=1
           for _, v in GetMetaMethods(value) do
            result = result .. string.rep("  ", indent) .. "meta" .. tostring(metacount1).."."..tostring(v.Name) .. " = "
            if typeof(v.Value) == "table" then
             result = result .. string.rep("  ", indent) .. "{" .. processTableDescendants(v.Value, indent + 1) .. "\n" .. string.rep("  ", indent) .. "}"
          elseif typeof(v.Value) == "function" then result = result .. string.rep("  ", indent) .. "function() --[[ Function Source ]] end" else result = result .. string.rep("  ", indent) .. tostring(v.Value) end
            result = result .. ";\n"
           end
          end
      elseif type(value) == "function" and not startswith(tostring(key), "__") then
          result = result .. string.rep("  ", indent) .. pKey(key) .. " = function() --[[Function Source]] end" .. string.rep("  ", indent + 1)
      elseif typeof(value):lower() == "vector3" and not startswith(tostring(key), "__") then
          result = result .. string.rep("  ", indent) .. pKey(key) .. " = Vector3.new(" .. tostring(value.X) .. ", " .. tostring(value.Y) .. ", " .. tostring(value.Z) .. ");\n"
      elseif typeof(value):lower() == "vector2" and not startswith(tostring(key), "__") then
          result = result .. string.rep("  ", indent) .. pKey(key) .. " = Vector2.new(" .. tostring(value.X) .. ", " .. tostring(value.Y) .. ");\n"
      elseif typeof(value):lower() == "udim" and not startswith(tostring(key), "__") then
          result = result .. string.rep("  ", indent) .. pKey(key) .. " = UDim.new(" .. tostring(value.Scale) .. ", " .. tostring(value.Offset) .. ");\n"
      elseif typeof(value):lower() == "udim2" and not startswith(tostring(key), "__") then
          result = result .. string.rep("  ", indent) .. pKey(key) .. " = UDim2.new(" .. tostring(value.X.Scale) .. ", " .. tostring(value.X.Offset) .. ", " .. tostring(value.Y.Scale) .. ", " .. tostring(value.Y.Offset) .. ");\n"
      elseif typeof(value):lower() == "instance" and not startswith(tostring(key), "__") then
        result = result .. string.rep("  ", indent) .. pKey(key) .. " = " .. GetFullName(value) .. ";\n"
    elseif typeof(value) == 'string' and not startswith(tostring(key), "__") then
      result = result .. string.rep("  ", indent) .. pKey(key) .. " = \"" .. tostring(value) .. "\";\n"
    elseif typeof(value) == 'number' and not startswith(tostring(key), "__") then
      result = result .. string.rep("  ", indent) .. pKey(key) .. " = " .. tostring(value) .. ";\n"
    elseif typeof(value) == "nil" and not startswith(tostring(key), "__") then -- nil value
      result = result .. string.rep("  ", indent) .. pKey(key) .. " = " .. tostring(value) .. ";\n"
    elseif typeof(value):lower() == "cframe" and not startswith(tostring(key), "__") then -- Enum/Other value
      result = result .. string.rep("  ", indent) .. pKey(key) .. " = CFrame.new(" .. tostring(value) .. ");\n"
    elseif typeof(value):lower() == 'color3' and not startswith(tostring(key), "__") then
      result = result .. string.rep("  ", indent) .. pKey(key) .. " = Color3.fromRGB(" .. tostring(value.R * 255) .. ", " .. tostring(value.G * 255) .. ", " .. tostring(value.B * 255) .. ");\n"
    end
  end
  if #tbl == 0 then return result else
  return "\n" ..result end
end
function DecompileFunction(func, excludename, indent)
 if not indent then indent = 1 end
 local count = 1
 local metacount = 1
 local inf, String = debug.getinfo(func), "function " .. tostring(debug.getinfo(func).name) .. "("
 if excludename then String = "function(" end
 if tostring(inf.is_vararg) == "1" then
  String = String .. "...)\n"
 else
  local ab = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}
  if inf.numparams > 0 then
  if inf.numparams > #ab then
    for i = 1, #ab do
      String = String .. ab[i] .. ", "
    end
    String = String .. "...)"
  else
  for i = 1, inf.numparams, 1 do
    String = String .. ab[i]
    if i < inf.numparams then String = String .. ", " else String = String .. ")\n" end
  end
  end
  elseif inf.numparams == 0 then
    String = String .. ")\n"
  end
  end
 StringHolder = String
 String = ""
 for i, v in getupvalues(func) do
  if type(v) == "table" then
   String = String .. string.format("\nv%s = {%s}\n", tostring(count), processTableDescendants(v, 1, tostring(i)))
   if getmetatable(v) ~= nil then
    String = String .. "meta"..tostring(metacount) .." = setmetatable(v" .. tostring(count) ..", {});\n"
    for _, thing in GetMetaMethods(v) do
      if type(thing.Value) == "table" then
          String = String .. ("meta%d.%s = {\n%s}\n"):format(metacount, tostring(thing.Name), processTableDescendants(thing.Value, 0))
          metacount+=1
        elseif type(thing.Value) == "function" then
          String = String .. ("meta%d.%s = %s"):format(metacount, tostring(thing.Name), DecompileFunction(thing.Value, true, indent))
         end
    end
   end
  elseif typeof(v):lower() == "vector2" then String = String.. ("\v%s = Vector2.new(%d, %d)"):format(tostring(count), v.X, v.Y) elseif typeof(v):lower() == "vector3" then String = String .. ("\nv%s = Vector3.new(%d, %d, %d)"):format(tostring(count), v.X, v.Y, v.Z) elseif typeof(v):lower() == "udim" then String = String .. ("\nv%s = UDim.new(%d, %d)"):format(tostring(count), v.Scale, v.Offset) elseif typeof(v):lower() == "udim2" then String = String .. ("\nlocal v%s = UDim2.new(%d, %d, %d, %d)"):format(tostring(count), v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset) elseif typeof(v):lower() == "number" then String = String .. ("\nv%s = %s"):format(tostring(count), tostring(v)) if v == os.time() then String = String .." -- os.time()" elseif v == tick() then String = String .. " -- tick()" end elseif typeof(v):lower() == 'instance' then String = String .. ("\nv%s = game.%s"):format(tostring(count), v:GetFullName()) elseif typeof(v):lower() == 'color3' then String = String .. ("\nv%d = Color3.fromRGB(%d, %d, %d"):format(count, v.R * 255, v.G * 255, v.B * 255) elseif typeof(v):lower() == 'string' then String = String .. ("\nv%s = \"%s\""):format(tostring(count), v) elseif typeof(v):lower() == 'boolean' then String = String .. ("\nv%d = %s"):format(count, tostring(v)) elseif typeof(v):lower() == "cframe" then String = String .. ("\nv%s = CFrame.new(%s)"):format(tostring(count), tostring(v))
    end
    count+=1
  end
 if #getupvalues(func) == 0 then
  String = StringHolder
 else
  String = StringHolder .. "--upvalues:" .. String
 end
 local robloxfunctions = ""
 local found = 0
 String = String .. "\n--constants:\n"
 for i, v in getconstants(func) do
  for _, hgwE2 in getrenv() do
    if v == _ and type(hgwE2) == "function" then
      if table.find(Libraries, getconstants(func)[i - 1]) then
       robloxfunctions = robloxfunctions .. string.rep(" ", indent + 1) .. getconstants(func)[i - 1] .. "." .. v .. "()" .. " -- local v" .. tostring(count - 1) .. " and v" .. tostring(count) .. "\n"
      else
       robloxfunctions = robloxfunctions .. string.rep(" ", indent + 1) .. v .. "()" .. " -- local v" .. tostring(count) .. "\n"
      end
      found+=1
      end
    end
  if typeof(v) == "table" then
    String = String .. string.format(" local v%s = {\n%s}\n", tostring(count), processTableDescendants(v, 1))
    elseif typeof(v) == "string" then String = String .. string.format(" local v%s = '%s'\n", tostring(count), tostring(v)) else String = String .. string.format(" local v%s = %s\n", tostring(count), tostring(v)) end
   count+=1
 end
  String = String .. ("%s--[[\n%sFound %d roblox functions in the constants."):format(string.rep("  ", indent),string.rep(" ", indent), found)
  if found > 0 then
   String = String .. "\n" .. robloxfunctions
  end
  String = String .. ("%s]]"):format(string.rep(" ", indent))
 for i, v in getprotos(func) do
  String = String .. ("\n local %s\n"):format(DecompileFunction(v, false, indent + 1))
 end
 return String .. "\n" .. string.rep(" ", indent) .. "end"
end
function DecompileScript(Script)
 local Decompiled = ""
 if typeof(Script) == "Instance" and Script.ClassName == "ModuleScript" then
  local s, e = pcall(function()
   for i, v in require(Script) do
    if type(v) == "table" then
     if #v == 0 then Decompiled = Decompiled .. ("local %s = {} --[[EMPTY TABLE]]\n"):format(tostring(i)) else 
     Decompiled = Decompiled .. ("local %s = {%s}\n"):format(tostring(i), processTableDescendants(v, 1)) end
     elseif type(v) == "function" then 
      Decompiled = Decompiled .. ("local %s = %s\n"):format(tostring(debug.getinfo(v).name), DecompileFunction(v, true, 0)) 
     end
   end
 end)
 if not s then return "-- Error occured when trying to iterate over ModuleScript, Message: " .. e end
 return Decompiled
 end
 local s, e = pcall(function()
 for i, v in getsenv(Script) do
  if type(v) == "table" then
   if #v == 0 then Decompiled = Decompiled .. ("local %s = {}\n"):format(tostring(i)) else
    Decompiled = Decompiled .. ("local %s = {%s}\n"):format(tostring(i), processTableDescendants(v, 1)) end
   elseif type(v) == "function" then Decompiled = Decompiled .. ("local %s = %s\n"):format(tostring(debug.getinfo(v).name), DecompileFunction(v, true, 0)) end
 end
 end)
 if not s then return " --An error occured while attempting to iterate over Script's enviroment!\nMessage: " .. e end
 return Decompiled
end

local Decompile, Libraries = {
  WaitDecompile = false,
  getupvalues = true,
  getconstants = true,
  setclipboard = false
}, {
  "bit32",
  "buffer",
  "coroutine",
  "debug",
  "math",
  "os",
  "string",
  "table",
  "task",
  "utf8"
}

local Variaveis = {}
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local function Wait()
  if Decompile.WaitDecompile then
    task.wait()
  end
end

local function IsInvalid(str)
  if str:find(" ")
  or str:find("0")
  or str:find("1")
  or str:find("2")
  or str:find("3")
  or str:find("4")
  or str:find("5")
  or str:find("6")
  or str:find("7")
  or str:find("8")
  or str:find("9")
  or str:find("-")
  or str:find("+")
  or str:find("/")
  or str:find("|") then
    return true
  end
end

local function GetParams(func)
  local Info, Vals = getinfo(func), {}
  for ind = 1, Info.numparams do
    table.insert(Vals, "Val" .. tostring(ind))
  end
  if Info.is_vararg > 0 then
    table.insert(Vals, "...")
  end
  return table.concat(Vals, ", ")
end

local function GetColorRGB(Color)
  local R, G, B
  local split = tostring(Color):gsub(" ", ""):split(",")
  R = math.floor(tonumber(split[1]) * 255)
  G = math.floor(tonumber(split[2]) * 255)
  B = math.floor(tonumber(split[3]) * 255)
  return (tostring(R) .. ", " .. tostring(G) .. ", " .. tostring(B))
end

local function GetIndex(Index)
  if tostring(Index):len() < 1 then
    return "[\"" .. tostring(Index) .. "\"]"
  elseif tonumber(Index) then
    return "[" .. tostring(Index) .. "]"
  elseif IsInvalid(tostring(Index)) then
    return "[\"" .. tostring(Index) .. "\"]"
  else
    return tostring(Index)
  end
end

function Decompile:Type(part, Lines)Wait()
  local type = typeof(part)
  local Script = "", ""
  
  if type == "boolean" then
    Script = Script .. tostring(part)
  elseif type == "nil" then
    Script = Script .. "nil"
  elseif type == "table" then
    Script, IsFirst = Script .. "{", false
    
    for a,b in pairs(part) do
      if IsFirst then Script = Script .. ","end
      Script = Script .. "\n"
      Script = Script .. Lines .. "  " .. GetIndex(a) .. " = "
      Script = Script .. Decompile:Type(b, Lines .. "  ")
      IsFirst = true
    end
    
    local An = IsFirst and "\n" .. Lines or ""
    Script = Script .. An .. "}"
  elseif type == "string" then
    Script = Script .. '"' .. part .. '"'
  elseif type == "Instance" then
    local first, firstName, Variavel2 = false, "", ""
    local Separator = part:GetFullName():split(".")
    for a,b in pairs(Separator) do
      if not first then
        if not table.find(Variaveis, b) then
          b = b:gsub(" ", "")
          if not game:FindFirstChild(b) then
            return b .. " --[[ nil Instance ]]"
          elseif b == "Workspace" then
            firstName = "workspace"
          else
            firstName = b
            table.insert(Variaveis, b)
          end
        else
          firstName = b
        end
      else
        if b == Player.Name and firstName == "Players" then
          Variavel2 = Variavel2 .. ".LocalPlayer"
        elseif b == Player.Name and firstName == "workspace" then
          table.insert(Variaveis, "Players")
          Variavel2, firstName = "Players.LocalPlayer.Character", ""
        elseif b == "Camera" and firstName == "workspace" then
          Variavel2 = Variavel2 .. ".CurrentCamera"
        elseif IsInvalid(b) then
          Variavel2 = Variavel2 .. '["' .. b .. '"]'
        else
          Variavel2 = Variavel2 .. "." .. b
        end
      end
      first = true
    end
    Script = Script .. firstName .. Variavel2
  elseif type == "function" then
    Script = Script .. "function(" .. GetParams(part) .. ")"
    local HaveVal, constants, upvalues = false, "", ""
    
    if Decompile.getupvalues then
      local uptable = getupvalues and getupvalues(part)
      
      if uptable and typeof(uptable) == "table" and #uptable > 0 then
        upvalues, HaveVal = upvalues .. "\n" .. Lines .. "  local upvalues = {", true
        local FirstVal
        for ind, val in pairs(uptable) do
          if FirstVal then upvalues = upvalues .. ","end
          upvalues = upvalues .. "\n" .. Lines .. "    [" .. tostring(ind) .. "] = " .. Decompile:Type(val, Lines .. "    ")
          FirstVal = true
        end
        upvalues = upvalues .. "\n" .. Lines .. "  }"
      end
    end
    if Decompile.getconstants then
      local uptable = getconstants and getconstants(part)
      
      if uptable and typeof(uptable) == "table" and #uptable > 0 then
        constants, HaveVal = constants .. "\n" .. Lines .. "  local constants = {", true
        local FirstVal
        for ind, val in pairs(uptable) do
          if FirstVal then constants = constants .. ","end
          constants = constants .. "\n" .. Lines .. "    [" .. tostring(ind) .. "] = " .. Decompile:Type(val, Lines .. "    ")
          FirstVal = true
        end
        constants = constants .. "\n" .. Lines .. "  }"
      end
    end
    
    local endType = HaveVal and "\n" .. Lines .. "end" or "end"
    Script = Script .. upvalues .. constants .. endType
  elseif type == "CFrame" then
    Script = Script .. "CFrame.new(" .. tostring(part) .. ")"
  elseif type == "Color3" then
    Script = Script .. "Color3.fromRGB(" .. GetColorRGB(part) .. ")"
  elseif type == "BrickColor" then
    Script = Script .. 'BrickColor.new("' .. tostring(part) .. '")'
  elseif type == "Vector2" then
    Script = Script .. "Vector2.new(" .. tostring(part) .. ")"
  elseif type == "Vector3" then
    Script = Script .. "Vector3.new(" .. tostring(part) .. ")"
  elseif type == "UDim" then
    Script = Script .. "UDim.new(" .. tostring(part) .. ")"
  elseif type == "UDim2" then
    Script = Script .. "UDim2.new(" .. tostring(part) .. ")"
  elseif type == "TweenInfo" then
    Script = Script .. "TweenInfo.new(" .. tostring(part) .. ")"
  elseif type == "Axes" then
    Script = Script .. "Axes.new(" .. tostring(part) .. ")"
  else
    if tostring(part):find("inf") then
      Script = Script .. "math.huge"
    else
      Script = Script .. tostring(part)
    end
  end
  return Script
end

function Decompile.new(part)
  local Metodo;Variaveis = {}
  local function GetClass(partGet)
    if typeof(partGet) == "Instance" then
      if partGet:IsA("LocalScript") then
        Metodo = "getsenv"
        return getsenv(partGet)
      elseif partGet:IsA("ModuleScript") then
        local Script = require(partGet)
        Metodo = "require"
        if typeof(Script) == "function" then
          Metodo = Metodo .. ", getupvalues"
          return getupvalues(Script)
        end
        return Script
      end
    end
    return partGet
  end
  
  local Script, Lines, IsFirst = typeof(part) == "Instance" and "%slocal Script = " .. Decompile:Type(part) .. "\n\n" or "", "  "
  Script = Script .. "local Decompile = {"
  
  local PartClass = GetClass(part)
  if typeof(PartClass) == "table" then
    for a,b in pairs(PartClass) do
      if IsFirst then Script = Script .. ","end
      Script = Script .. "\n"
      Script = Script .. Lines .. GetIndex(a) .. ' = '
      Script = Script .. Decompile:Type(b, Lines)
      IsFirst = true
    end
  else
    Script = Script .. "\n" .. Lines .. "[\"1\"] = " .. Decompile:Type(PartClass, Lines)
  end
  
  if Metodo then
    Script = Script:format("local Method = " .. Metodo .. "\n")
  else
    Script = Script:format("")
  end
  
  local Var, list = "", {}
  table.foreach(Variaveis, function(_,Val)
    if table.find(list, Val) then return end
    Var = Var .. "local " .. Val .. "\ = game:GetService(\"" .. Val .. "\")\n"
    table.insert(list, Val)
  end)
  
  if Decompile.setclipboard then
    setclipboard(Var .. "\n" .. Script .. "\n}")
  end
  return (Var .. "\n" .. Script .. "\n}")
end

function SimpleDecompile(module)
    local Module = require(module)
    local DecompiledModule = ""

    local function processTable(tab, indent)

