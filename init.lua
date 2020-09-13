local environment = assert(getgenv, "<OH> ~ Your exploit is not supported")()

if oh then
    oh.Exit()
end

local web = true
local importCache = {}

-- local read, result = pcall(readfile, "ohaux.lua")
-- if web and read and readfile then
--     local webAux = game:HttpGetAsync('https://raw.githubusercontent.com/Upbolt/Hydroxide/revision/ohaux.lua')

--     if not read or webAux ~= result then
--         writefile("ohaux.lua", webAux)
--     end
-- end

local function import(asset)
    if importCache[asset] then
        return unpack(importCache[asset])
    end
    
    local assets 

    if asset:find("rbxassetid://") then
        assets = { game:GetObjects(asset)[1] }
    elseif web then
        assets = { webImport(asset) }
    else
        assets = { loadstring(readfile("hydroxide/" .. asset .. ".lua"), asset .. '.lua')() }
    end
    
    importCache[asset] = assets
    return unpack(assets)
end

local function hasMethods(methods)
    for name in pairs(methods) do
        if not environment[name] then
            return false
        end
    end

    return true
end

local function useMethods(module)
    for name, method in pairs(module) do
        if method then
            environment[name] = method
        end
    end
end

local globalMethods = {
    checkCaller = checkcaller,
    newCClosure = newcclosure,
    hookFunction = hookfunction or detour_function,
    getGc = getgc or get_gc_objects,
    getInfo = debug.getinfo or getinfo,
    getSenv = getsenv,
    getMenv = getmenv or getsenv,
    getContext = getthreadcontext or get_thread_context or (syn and syn.get_thread_identity),
    getConnections = get_signal_cons or getconnections,
    getScriptClosure = get_script_function or (getscriptclosure and not is_sirhurt_closure),
    getNamecallMethod = getnamecallmethod or get_namecall_method,
    getCallingScript = getcallingscript or get_calling_script,
    getLoadedModules = getloadedmodules or get_loaded_modules,
    getConstants = debug.getconstants or getconstants or getconsts,
    getUpvalues = debug.getupvalues or getupvalues or getupvals,
    getProtos = debug.getprotos or getprotos,
    getStack = debug.getstack or getstack,
    getConstant = debug.getconstant or getconstant or getconst,
    getUpvalue = debug.getupvalue or getupvalue or getupval,
    getProto = debug.getproto or getproto,
    getMetatable = getrawmetatable or debug.getmetatable,
    setClipboard = setclipboard or writeclipboard,
    setConstant = debug.setconstant or setconstant or setconst,
    setContext = setthreadcontext or set_thread_context or (syn and syn.set_thread_identity),
    setUpvalue = debug.setupvalue or setupvalue or setupval,
    setStack = debug.setstack or setstack,
    setReadOnly = setreadonly or make_readonly,
    isLClosure = islclosure or is_l_closure or (iscclosure and function(closure) return not iscclosure(closure) end),
    isReadOnly = isreadonly or is_readonly,
    isXClosure = is_synapse_function or issentinelclosure or is_protosmasher_closure or is_sirhurt_closure or checkclosure,
}

if PROTOSMASHER_LOADED ~= nil then
    globalMethods.getConstant = function(closure, index)
        return globalMethods.getConstants(closure)[index]
    end
end

environment.import = import
environment.hasMethods = hasMethods
environment.oh = {
    Events = {},
    Hooks = {},
    Methods = globalMethods,
    Constants = {
        Types = {
            ["nil"] = "rbxassetid://4800232219",
            table = "rbxassetid://4666594276",
            string = "rbxassetid://4666593882",
            number = "rbxassetid://4666593882",
            boolean = "rbxassetid://4666593882",
            userdata = "rbxassetid://4666594723",
            ["function"] = "rbxassetid://4666593447",

            ["integral"] = "rbxassetid://4666593882"
        },
        Syntax = {
            ["nil"] = Color3.fromRGB(244, 135, 113),
            table = Color3.fromRGB(225, 225, 225),
            string = Color3.fromRGB(225, 150, 85),
            number = Color3.fromRGB(170, 225, 127),
            boolean = Color3.fromRGB(127, 200, 255),
            userdata = Color3.fromRGB(225, 225, 225),
            ["function"] = Color3.fromRGB(225, 225, 225),
            ["unnamed_function"] = Color3.fromRGB(175, 175, 175)
        }
    },
    Exit = function()
        for _i, event in pairs(oh.Events) do
            event:Disconnect()
        end

        for original, hook in pairs(oh.Hooks) do
            local hookType = type(hook)
            if hookType == "function" then
                hookFunction(hook, original)
            elseif hookType == "table" then
                hookFunction(hook.Closure.Data, hook.Original)
            end
        end

        local gmt = getrawmetatable(game)

        if isReadOnly(gmt) then
            setReadOnly(gmt, false) 
        end

        if oh.Namecall then
            gmt.__namecall = oh.Namecall
        end

        local ui = importCache["rbxassetid://5042109928"]
        local assets = importCache["rbxassetid://5042114982"]

        if ui then
            unpack(ui):Destroy()
        end

        if assets then
            unpack(assets):Destroy()
        end
    end
}

if getConnections then
    for __, connection in pairs(getConnections(game:GetService("ScriptContext").Error)) do
        if PROTOSMASHER_LOADED ~= nil then
            connection:Disconnect()
        else
            connection:Disable()
        end
    end
end

useMethods(globalMethods)
useMethods(import("methods/string"))
useMethods(import("methods/table"))
useMethods(import("methods/userdata"))
useMethods(import("methods/environment"))
