local ADDON_NAME = ...

ComfyMaps = ComfyMaps or {}
local A = ComfyMaps

A.name = ADDON_NAME or "ComfyMaps"
A.version = "0.2"
A.buildDate = "28.09.2026"
A.status = "Beta"
A.gameVersion = "WoW Forever 1.60.1"
A.targetBuild = "70009"
A.interface = 16001
A.author = "TheRealDoubleG"
A.discord = "the.real.double.g"
A.github = "https://github.com/TheRealDoubleG/ComfyMaps"

local defaults = {
    enabled = true,
    map = {
        category = "map",

        scale = 100,
        opacity = 100,
        fadeWhileMoving = false,
        movingOpacity = 60,
        hideBorder = false,

        unlockMap = false,
        rememberPosition = true,
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,

        showPlayerCoords = true,
        showCursorCoords = true,

        showGathererPins = true,
        gathererPinSize = 14,
        maxGathererPins = 250,
    },
    optionsWindow = {point="CENTER",relativePoint="CENTER",x=0,y=20},
    ui = {windowLocked=false,windowOpacity=100,showWindowBorder=true,backgroundAlpha=92},
}

function A:Print(msg)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffd200ComfyMaps:|r "..tostring(msg)) end
end

function A:GetClientBuildInfo()
    if type(GetBuildInfo)~="function" then return "?","?","?",nil end
    local v,b,d,i=GetBuildInfo()
    return tostring(v or "?"),tostring(b or "?"),tostring(d or "?"),tonumber(i)
end

function A:GetCompatibilityStatus()
    local _,_,_,i=self:GetClientBuildInfo()
    if i and tonumber(i)==tonumber(self.interface) then return true,self:T("COMPAT_MATCH") end
    return false,self:T("COMPAT_UPDATE_REQUIRED")
end

function A:InitializeDB()
    self:InitializeProfileStorage(defaults,"ComfyMapsDB")
end

function A:SetEnabled(v)
    if not self.db then return false end
    self.db.enabled=v and true or false
    if self.ApplyAll then self:ApplyAll() end
    if self.RefreshOptions then self:RefreshOptions() end
    return true
end

function A:GetComfyProfileProvider() return self end
function A:OpenOptions() if self.ShowOptions then self:ShowOptions() end end

SLASH_COMFYMAPS1="/comfymaps"
SLASH_COMFYMAPS2="/cmaps"
SlashCmdList.COMFYMAPS=function() A:OpenOptions() end

local e=CreateFrame("Frame")
e:RegisterEvent("ADDON_LOADED")
e:RegisterEvent("PLAYER_LOGIN")
e:SetScript("OnEvent",function(_,ev,arg1)
    if ev=="ADDON_LOADED" and arg1==A.name then
        A:InitializeDB()
        if A.InitializeFeature then A:InitializeFeature() end
        if A.InitializeOptions then A:InitializeOptions() end
    elseif ev=="PLAYER_LOGIN" and A.ApplyAll then
        A:ApplyAll()
    end
end)
