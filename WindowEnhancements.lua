ComfyMaps = ComfyMaps or {}
local A = ComfyMaps

A.version = "0.4"
A.buildDate = "04.10.2026"

local PIN_ICONS={
    Herbalism="Interface\\Icons\\INV_Misc_Herb_07",
    Mining="Interface\\Icons\\INV_Ore_Copper_01",
    Skinning="Interface\\Icons\\INV_Misc_LeatherScrap_02",
    Other="Interface\\Icons\\INV_Misc_Map_01",
}

local function Epoch() return type(time)=="function" and time() or 0 end
local function Clamp(v,lo,hi) v=tonumber(v) or lo; if v<lo then return lo elseif v>hi then return hi end; return v end

local function EnsureDefaults()
    if not A.db then return end
    A.db.map=A.db.map or {}
    local c=A.db.map
    local defaults={
        replaceBlizzardMap=false,
        sizeLocked=false,
        windowWidth=860,
        windowHeight=620,
        comfyMaximized=false,
        showHerbalismPins=true,
        showMiningPins=true,
        showSkinningPins=true,
        showOtherPins=false,
        gatherLastSeenDays=0,
        showUserMarkers=true,
        userMarkers={},
    }
    for k,v in pairs(defaults) do if c[k]==nil then c[k]=v end end
end

local originalInitializeDB=A.InitializeDB
function A:InitializeDB(...)
    local result
    if originalInitializeDB then result=originalInitializeDB(self,...) end
    EnsureDefaults()
    return result
end

local function SaveWindowRect(map)
    if not A.db or not map or A.db.map.comfyMaximized then return end
    local c=A.db.map
    local w,h=map:GetWidth(),map:GetHeight()
    if tonumber(w) and tonumber(h) then c.windowWidth=math.floor(w+0.5); c.windowHeight=math.floor(h+0.5) end
    local point,_,relativePoint,x,y=map:GetPoint(1)
    if point then c.point=point; c.relativePoint=relativePoint or point; c.x=x or 0; c.y=y or 0 end
end

function A:SetMapMaximized(maximized)
    EnsureDefaults()
    local map=self:GetWorldMap(); if not map then return end
    local c=self.db.map
    maximized=maximized and true or false
    if maximized==c.comfyMaximized then return end

    if maximized then
        local p,_,rp,x,y=map:GetPoint(1)
        c.restoreWindow={point=p or c.point or "CENTER",relativePoint=rp or c.relativePoint or "CENTER",x=x or c.x or 0,y=y or c.y or 0,width=map:GetWidth(),height=map:GetHeight()}
        c.comfyMaximized=true
        map:ClearAllPoints(); map:SetPoint("CENTER",UIParent,"CENTER",0,0)
        map:SetSize(math.max(620,(UIParent:GetWidth() or 1280)*0.94),math.max(430,(UIParent:GetHeight() or 720)*0.90))
    else
        c.comfyMaximized=false
        local r=c.restoreWindow or {}
        map:ClearAllPoints(); map:SetPoint(r.point or c.point or "CENTER",UIParent,r.relativePoint or c.relativePoint or "CENTER",r.x or c.x or 0,r.y or c.y or 0)
        map:SetSize(tonumber(r.width) or tonumber(c.windowWidth) or 860,tonumber(r.height) or tonumber(c.windowHeight) or 620)
        SaveWindowRect(map)
    end
    self:UpdateMaximizeButton()
    self:RefreshGathererPins()
    self:RefreshUserMarkers()
end

function A:ToggleMapMaximized() self:SetMapMaximized(not (self.db and self.db.map and self.db.map.comfyMaximized)) end

function A:UpdateMaximizeButton()
    if self.maximizeButton and self.db then self.maximizeButton:SetText(self.db.map.comfyMaximized and "▣" or "□") end
end

function A:CreateWindowControls()
    local map=self:GetWorldMap()
    if not map or self.resizeGrip then return end
    if type(map.SetResizable)=="function" then pcall(map.SetResizable,map,true) end
    if type(map.SetResizeBounds)=="function" then
        pcall(map.SetResizeBounds,map,520,360,math.max(700,(UIParent:GetWidth() or 1600)*0.96),math.max(500,(UIParent:GetHeight() or 900)*0.94))
    end

    local grip=CreateFrame("Button",nil,map)
    grip:SetSize(22,22); grip:SetPoint("BOTTOMRIGHT",map,"BOTTOMRIGHT",-3,3); grip:SetFrameLevel((map:GetFrameLevel() or 1)+60)
    grip.tex=grip:CreateTexture(nil,"OVERLAY"); grip.tex:SetAllPoints(); grip.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:RegisterForDrag("LeftButton")
    grip:SetScript("OnDragStart",function()
        local c=A.db and A.db.map
        if not c or not c.replaceBlizzardMap or c.sizeLocked or c.comfyMaximized then return end
        if map.StartSizing then pcall(map.StartSizing,map,"BOTTOMRIGHT") end
    end)
    grip:SetScript("OnDragStop",function()
        if map.StopMovingOrSizing then pcall(map.StopMovingOrSizing,map) end
        SaveWindowRect(map); A:RefreshGathererPins(); A:RefreshUserMarkers()
    end)
    self.resizeGrip=grip

    local max=CreateFrame("Button",nil,map,"UIPanelButtonTemplate")
    max:SetSize(28,22); max:SetPoint("TOPRIGHT",map,"TOPRIGHT",-36,-4); max:SetFrameLevel((map:GetFrameLevel() or 1)+60); max:SetText("□")
    max:SetScript("OnClick",function() A:ToggleMapMaximized() end)
    max:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:AddLine(A.db.map.comfyMaximized and "Vorherige Größe" or "Maximieren"); GameTooltip:Show() end)
    max:SetScript("OnLeave",function() GameTooltip:Hide() end)
    self.maximizeButton=max
    self:UpdateMaximizeButton()
end

local function SetNineSliceAlpha(nine,alpha)
    if not nine then return end
    local keys={"TopLeftCorner","TopRightCorner","BottomLeftCorner","BottomRightCorner","TopEdge","BottomEdge","LeftEdge","RightEdge"}
    for _,k in ipairs(keys) do if nine[k] and nine[k].SetAlpha then nine[k]:SetAlpha(alpha) end end
end

function A:ApplyWindowComfort()
    EnsureDefaults()
    local map=self:GetWorldMap(); if not map then return end
    self:CreateWindowControls()
    local c=self.db.map
    local custom=self.db.enabled and c.replaceBlizzardMap

    if self.resizeGrip then self.resizeGrip:SetShown(custom and not c.sizeLocked and not c.comfyMaximized) end
    if self.maximizeButton then self.maximizeButton:SetShown(custom) end
    if self.dragHandle then self.dragHandle:SetShown(self.db.enabled and c.unlockMap and not c.comfyMaximized) end

    if custom then
        if map.SetScale then pcall(map.SetScale,map,1) end
        if not c.comfyMaximized then
            local w=Clamp(c.windowWidth,520,math.max(700,(UIParent:GetWidth() or 1600)*.96))
            local h=Clamp(c.windowHeight,360,math.max(500,(UIParent:GetHeight() or 900)*.94))
            pcall(map.SetSize,map,w,h)
        end
        pcall(map.SetAlpha,map,Clamp(c.opacity,0,100)/100)
        if c.hideBorder then SetNineSliceAlpha(map.NineSlice,0); if map.BorderFrame then SetNineSliceAlpha(map.BorderFrame.NineSlice,0) end end
    end

    if self.mapOverlay and self.mapOverlay.coords then self.mapOverlay.coords:SetTextColor(.45,1,.55) end
    self:UpdateMaximizeButton()
end

local originalSaveMapPosition=A.SaveMapPosition
function A:SaveMapPosition(...)
    if self.db and self.db.map and self.db.map.comfyMaximized then return end
    if originalSaveMapPosition then originalSaveMapPosition(self,...) end
    SaveWindowRect(self:GetWorldMap())
end

local originalApplyAll=A.ApplyAll
function A:ApplyAll(...)
    if originalApplyAll then originalApplyAll(self,...) end
    self:ApplyWindowComfort()
    self:RefreshUserMarkers()
end

-- Filtered, shared ComfyData/ComfyGatherer pin renderer.
function A:RefreshGathererPins()
    local map=self:GetWorldMap(); local c=self.db and self.db.map
    if not map or not map:IsShown() or not self.db.enabled or not c or not c.showGathererPins or type(ComfyData)~="table" then self:HideGatherPins(1); return end
    local scroll=map.ScrollContainer; local child=scroll and scroll.Child
    if not child then self:HideGatherPins(1); return end
    local mapID=self:GetDisplayedMapID(); if not mapID then self:HideGatherPins(1); return end
    local filters={Herbalism=c.showHerbalismPins,Mining=c.showMiningPins,Skinning=c.showSkinningPins,Other=c.showOtherPins,lastSeenDays=c.gatherLastSeenDays}
    local nodes
    if type(ComfyData.GetGatherNodesFiltered)=="function" then nodes=ComfyData:GetGatherNodesFiltered(mapID,filters)
    elseif type(ComfyData.GetGatherNodesForMap)=="function" then nodes=ComfyData:GetGatherNodesForMap(mapID) or {} else nodes={} end
    local maxPins=math.max(10,math.min(500,tonumber(c.maxGathererPins) or 250)); local size=math.max(8,math.min(28,tonumber(c.gathererPinSize) or 14))
    local width,height=child:GetWidth(),child:GetHeight(); if not width or not height or width<=0 or height<=0 then self:HideGatherPins(1); return end
    local count=0
    for _,node in ipairs(nodes) do
        local prof=tostring(node.profession or "Other")
        local show=(prof=="Herbalism" and c.showHerbalismPins) or (prof=="Mining" and c.showMiningPins) or (prof=="Skinning" and c.showSkinningPins) or ((prof~="Herbalism" and prof~="Mining" and prof~="Skinning") and c.showOtherPins)
        local x,y=tonumber(node.x),tonumber(node.y)
        if show and x and y and x>=0 and x<=1 and y>=0 and y<=1 then
            count=count+1; if count>maxPins then break end
            local pin=self:GetGatherPin(count,child); pin.node=node; pin:SetSize(size,size); pin.icon:SetTexture(PIN_ICONS[prof] or PIN_ICONS.Other)
            pin:ClearAllPoints(); pin:SetPoint("CENTER",child,"TOPLEFT",x*width,-y*height); pin:Show()
        end
    end
    self:HideGatherPins(count+1)
end

function A:GetUserMarkerPin(index,parent)
    self.userMarkerPins=self.userMarkerPins or {}; local pin=self.userMarkerPins[index]
    if pin and pin:GetParent()~=parent then pin:SetParent(parent) end
    if pin then return pin end
    pin=CreateFrame("Button",nil,parent,"BackdropTemplate"); pin:SetSize(15,15); pin:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1}); pin:SetBackdropBorderColor(0,0,0,1)
    pin.icon=pin:CreateTexture(nil,"ARTWORK"); pin.icon:SetAllPoints(); pin.icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01"); pin.icon:SetTexCoord(.08,.92,.08,.92)
    pin:SetScript("OnEnter",function(self) if not self.marker then return end; GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine(self.marker.label or "Eigener Marker",1,.82,0); GameTooltip:AddLine(string.format("%.1f, %.1f",(self.marker.x or 0)*100,(self.marker.y or 0)*100),.45,1,.55); GameTooltip:AddLine("Rechtsklick: löschen",.65,.65,.65); GameTooltip:Show() end)
    pin:SetScript("OnLeave",function() GameTooltip:Hide() end)
    pin:SetScript("OnClick",function(self,button) if button=="RightButton" and self.mapID and self.markerIndex then local list=A.db.map.userMarkers[tostring(self.mapID)] or {}; table.remove(list,self.markerIndex); A:RefreshUserMarkers() end end)
    pin:RegisterForClicks("LeftButtonUp","RightButtonUp"); self.userMarkerPins[index]=pin; return pin
end

function A:RefreshUserMarkers()
    if not self.db then return end; EnsureDefaults()
    local map=self:GetWorldMap(); local c=self.db.map
    if not map or not map:IsShown() or not c.showUserMarkers then for _,p in ipairs(self.userMarkerPins or {}) do p:Hide() end; return end
    local child=map.ScrollContainer and map.ScrollContainer.Child; local mapID=self:GetDisplayedMapID()
    if not child or not mapID then for _,p in ipairs(self.userMarkerPins or {}) do p:Hide() end; return end
    local list=c.userMarkers[tostring(mapID)] or {}; local w,h=child:GetWidth(),child:GetHeight(); local count=0
    for i,m in ipairs(list) do if tonumber(m.x) and tonumber(m.y) then count=count+1; local pin=self:GetUserMarkerPin(count,child); pin.marker=m; pin.markerIndex=i; pin.mapID=mapID; pin:ClearAllPoints(); pin:SetPoint("CENTER",child,"TOPLEFT",m.x*w,-m.y*h); pin:Show() end end
    for i=count+1,#(self.userMarkerPins or {}) do self.userMarkerPins[i]:Hide() end
end

function A:AddUserMarkerAtCursor()
    EnsureDefaults(); local map=self:GetWorldMap(); local scroll=map and map.ScrollContainer; local mapID=self:GetDisplayedMapID()
    if not scroll or not mapID or type(scroll.GetNormalizedCursorPosition)~="function" then return end
    local ok,x,y=pcall(scroll.GetNormalizedCursorPosition,scroll); x,y=ok and tonumber(x) or nil,ok and tonumber(y) or nil
    if not x or not y or x<0 or x>1 or y<0 or y>1 then return end
    local key=tostring(mapID); self.db.map.userMarkers[key]=self.db.map.userMarkers[key] or {}
    self.db.map.userMarkers[key][#self.db.map.userMarkers[key]+1]={x=x,y=y,label="Eigener Marker",createdAt=Epoch()}; self:RefreshUserMarkers()
end

function A:InstallMapComfortHooks()
    if self.__comfortHooksInstalled then return end
    local map=self:GetWorldMap(); local scroll=map and map.ScrollContainer
    if not map or not scroll then return end
    self.__comfortHooksInstalled=true
    if type(scroll.HookScript)=="function" then
        scroll:HookScript("OnMouseUp",function(_,button)
            if button=="RightButton" and type(IsControlKeyDown)=="function" and IsControlKeyDown() and A.db and A.db.map.replaceBlizzardMap then A:AddUserMarkerAtCursor() end
        end)
    end
    if type(map.HookScript)=="function" then
        map:HookScript("OnSizeChanged",function() if A.db and A.db.map.replaceBlizzardMap and not A.db.map.comfyMaximized then SaveWindowRect(map); A:RefreshGathererPins(); A:RefreshUserMarkers() end end)
    end
end

local originalEnsureMapHooks=A.EnsureMapHooks
function A:EnsureMapHooks(...)
    local result=originalEnsureMapHooks and originalEnsureMapHooks(self,...) or false
    self:InstallMapComfortHooks(); self:CreateWindowControls(); self:ApplyWindowComfort(); return result
end

local originalBuildGeneralOptions=A.BuildGeneralOptions
function A:BuildGeneralOptions(page,ui)
    if originalBuildGeneralOptions then originalBuildGeneralOptions(self,page,ui) end
    EnsureDefaults(); if not self.mapCategoryPages or not ui then return end
    local p=self.mapCategoryPages.map
    ui.CreateCheck(p,"Blizzardkarte als ComfyMap verwenden",260,-15,function() return A.db.map.replaceBlizzardMap end,function(v) A.db.map.replaceBlizzardMap=v; A:ApplyAll() end)
    ui.CreateCheck(p,"Fenstergröße sperren",260,-50,function() return A.db.map.sizeLocked end,function(v) A.db.map.sizeLocked=v; A:ApplyWindowComfort() end)
    ui.CreateButton(p,"Maximieren / Wiederherstellen",260,-90,220,function() A:ToggleMapMaximized() end)
    ui.CreateButton(p,"Fenstergröße zurücksetzen",260,-125,220,function() A.db.map.windowWidth=860; A.db.map.windowHeight=620; A.db.map.comfyMaximized=false; A:ApplyWindowComfort() end)
    ui.CreateSlider(p,"Fenster-Deckkraft",0,100,5,300,-335,function() return A.db.map.opacity end,function(v) A.db.map.opacity=math.floor(v+0.5); A:ApplyWindowComfort() end,function(v) return math.floor(v+0.5).."%" end)

    p=self.mapCategoryPages.data
    ui.CreateCheck(p,"Kräuter",10,-50,function() return A.db.map.showHerbalismPins end,function(v) A.db.map.showHerbalismPins=v; A:RefreshGathererPins() end)
    ui.CreateCheck(p,"Erze",130,-50,function() return A.db.map.showMiningPins end,function(v) A.db.map.showMiningPins=v; A:RefreshGathererPins() end)
    ui.CreateCheck(p,"Kürschnerei",240,-50,function() return A.db.map.showSkinningPins end,function(v) A.db.map.showSkinningPins=v; A:RefreshGathererPins() end)
    ui.CreateCheck(p,"Sonstige",380,-50,function() return A.db.map.showOtherPins end,function(v) A.db.map.showOtherPins=v; A:RefreshGathererPins() end)
    ui.CreateSlider(p,"Nur Punkte der letzten Tage (0 = alle)",0,60,1,20,-190,function() return A.db.map.gatherLastSeenDays end,function(v) A.db.map.gatherLastSeenDays=math.floor(v+0.5); A:RefreshGathererPins() end,function(v) return tostring(math.floor(v+0.5)) end)
    ui.CreateCheck(p,"Eigene Marker anzeigen",10,-260,function() return A.db.map.showUserMarkers end,function(v) A.db.map.showUserMarkers=v; A:RefreshUserMarkers() end)
    local hint=p:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); hint:SetPoint("TOPLEFT",10,-300); hint:SetWidth(500); hint:SetJustifyH("LEFT"); hint:SetText("Strg + Rechtsklick auf die Karte: eigenen Marker setzen. Rechtsklick auf Marker: löschen.")
end
