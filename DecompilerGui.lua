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

function SimpleDecompile(module)
    local Module = require(module)
    local DecompiledModule = ""

    local function processTable(tab, indent)
        for key, value in pairs(tab) do
            if typeof(value) == "table" then
                DecompiledModule = DecompiledModule .. ("\t"):rep(indent) .. key .. " = {\n"
                processTable(value, indent + 1)
                DecompiledModule = DecompiledModule .. ("\t"):rep(indent) .. "}\n"
            elseif typeof(value) == "function" then
                DecompiledModule = DecompiledModule .. ("\t"):rep(indent) .. key .. " = function()\n\t\t-- function body\n\tend,\n"
            else
                DecompiledModule = DecompiledModule .. ("\t"):rep(indent) .. key .. " = " .. tostring(value) .. ",\n"
            end
        end
    end

    processTable(Module, 0)
    
    return DecompiledModule
end

local DecompilerV1 = false
local DecompilerV2 = false

local Section = Tab:AddSection({
	Name = "Do not active both of them!"
})

Tab:AddToggle({
	Name = "Decompiler V1",
	Default = false,
	Callback = function(v)
		DecompilerV1 = v
	end
})

Tab:AddToggle({
	Name = "Decompiler V2 (BETA)",
	Default = false,
	Callback = function(v)
		DecompilerV2 = v
	end
})

local CopyDecompiled = false
local SaveDecompiled = false

Tab:AddTextbox({
    Name = "Enter Script Path",
    TextDisappearing = true,
    Callback = function(v)
        local a = v
        if DecompilerV1 then
        local b = SimpleDecompile(a)
        end
         if DecompilerV2 then
        local b = DecompileScript(a)
        end
        print(b)
        if CopyDecompiled then
            setclipboard(b)
        end
        if SaveDecompiled then
            writefile("DecompiledScript.txt", b)
        end
    end
})

local Tab2 = _G.Window:MakeTab({
	Name = "Script Locations",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})


Tab2:AddToggle({
	Name = "Copy decompiled script",
	Default = false,
	Callback = function(v)
		CopyDecompiled = v
	end
})

Tab2:AddToggle({
	Name = "Save decompiled script",
	Default = false,
	Callback = function(v)
		SaveDecompiled = v
	end
})

local function Label(text, text2)
	Tab2:AddButton({
    Name = text,
    Callback = function()
        local a = text2
        local a = v
        if DecompilerV1 then
        local b = SimpleDecompile(a)
        end
         if DecompilerV2 then
        local b = DecompileScript(a)
        end
        print(b)
        if CopyDecompiled then
            setclipboard(b)
        end
        if SaveDecompiled then
            writefile("DecompiledScript.txt", b)
        end
    end
})
end

for i,v in pairs(game:GetService("Players"):GetDescendants()) do
	if v:IsA"ModuleScript" or v:IsA"LocalScript" then
		Label(v.Name, v)
	end
end

for i,v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
	if v:IsA"ModuleScript" or v:IsA"LocalScript" then
		Label(v.Name, v)
	end
end

for i,v in pairs(game:GetService("ReplicatedFirst"):GetDescendants()) do
	if v:IsA"ModuleScript" or v:IsA"LocalScript"then
		Label(v.Name, v)
	end
end

for i,v in pairs(game:GetService("Workspace"):GetDescendants()) do
	if v:IsA"ModuleScript" or v:IsA"LocalScript" then
	    Label(v.Name, v)
	end
end
