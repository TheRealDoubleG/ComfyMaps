ComfyMaps = ComfyMaps or {}
local A = ComfyMaps

local PIN_ICONS={
    Herbalism="Interface\\Icons\\INV_Misc_Herb_07",
    Mining="Interface\\Icons\\INV_Ore_Copper_01",
    Skinning="Interface\\Icons\\INV_Misc_LeatherScrap_02",
    Other="Interface\\Icons\\INV_Misc_Map_01",
}

local function SetShownSafe(frame,shown)
    if not frame then return end
    if frame.SetShown then frame:SetShown(shown) elseif shown and frame.Show then frame:Show() elseif not shown and frame.Hide then frame:Hide() end
end

local function Clamp(v,lo,hi)
    v=tonumber(v) or lo
    if v<lo then return lo end
    if v>hi then return hi end
    return v
end

function A:GetWorldMap()
    return _G.WorldMapFrame
end

function A:GetDisplayedMapID()
    local map=self:GetWorldMap()
    if map and type(map.GetMapID)=="function" then
        local ok,id=pcall(map.GetMapID,map)
        if ok and tonumber(id) then return tonumber(id) end
    end
    if C_Map and type(C_Map.GetBestMapForUnit)=="function" then
        local ok,id=pcall(C_Map.GetBestMapForUnit,"player")
        if ok then return tonumber(id) end
    end
end

function A:GetPlayerCoords(mapID)
    if not mapID or not C_Map or type(C_Map.GetPlayerMapPosition)~="function" then return nil end
    local ok,pos=pcall(C_Map.GetPlayerMapPosition,mapID,"player")
    if not ok or not pos or type(pos.GetXY)~="function" then return nil end
    local x,y=pos:GetXY()
    x,y=tonumber(x),tonumber(y)
    if not x or not y or (x==0 and y==0) then return nil end
    return x,y
end

function A:GetCursorCoords()
    local map=self:GetWorldMap()
    local scroll=map and map.ScrollContainer
    if scroll and type(scroll.GetNormalizedCursorPosition)=="function" then
        local ok,x,y=pcall(scroll.GetNormalizedCursorPosition,scroll)
        if ok and tonumber(x) and tonumber(y) then
            x,y=tonumber(x),tonumber(y)
            if x>=0 and x<=1 and y>=0 and y<=1 then return x,y end
        end
    end
end

function A:CreateMapOverlay()
    local map=self:GetWorldMap()
    if not map or self.mapOverlay then return end

    local overlay=CreateFrame("Frame",nil,map)
    overlay:SetAllPoints(map)
    overlay:SetFrameLevel((map:GetFrameLevel() or 1)+25)
    overlay:EnableMouse(false)

    overlay.coords=overlay:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    overlay.coords:SetPoint("BOTTOM",map,"BOTTOM",0,12)
    overlay.coords:SetTextColor(1,0.82,0)

    self.mapOverlay=overlay

    local drag=CreateFrame("Button",nil,map,"UIPanelButtonTemplate")
    drag:SetSize(120,22)
    drag:SetPoint("TOP",map,"TOP",0,-5)
    drag:SetText(self:T("DRAG_HANDLE"))
    drag:SetFrameLevel((map:GetFrameLevel() or 1)+40)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart",function()
        if not A.db or not A.db.map.unlockMap then return end
        if map.SetMovable then map:SetMovable(true) end
        if map.SetUserPlaced then pcall(map.SetUserPlaced,map,true) end
        if map.StartMoving then map:StartMoving() end
    end)
    drag:SetScript("OnDragStop",function()
        if map.StopMovingOrSizing then map:StopMovingOrSizing() end
        A:SaveMapPosition()
    end)
    self.dragHandle=drag
end

function A:SaveMapPosition()
    if not self.db or not self.db.map.rememberPosition then return end
    local map=self:GetWorldMap()
    if not map then return end
    local mx,my=map:GetCenter()
    local ux,uy=UIParent:GetCenter()
    if mx and my and ux and uy then
        self.db.map.point="CENTER"
        self.db.map.relativePoint="CENTER"
        self.db.map.x=mx-ux
        self.db.map.y=my-uy
    end
end

function A:ApplyMapPosition()
    local map=self:GetWorldMap()
    local c=self.db and self.db.map
    if not map or not c or not c.rememberPosition then return end
    if type(map.IsMaximized)=="function" then
        local ok,maximized=pcall(map.IsMaximized,map)
        if ok and maximized then return end
    end
    map:ClearAllPoints()
    map:SetPoint(c.point or "CENTER",UIParent,c.relativePoint or "CENTER",tonumber(c.x) or 0,tonumber(c.y) or 0)
end

function A:ResetMapPosition()
    if not self.db then return end
    self.db.map.point="CENTER"
    self.db.map.relativePoint="CENTER"
    self.db.map.x=0
    self.db.map.y=0
    self:ApplyMapPosition()
end

function A:ApplyMapAppearance()
    local map=self:GetWorldMap()
    local c=self.db and self.db.map
    if not map or not c then return end

    if self.db.enabled then
        if type(map.SetScale)=="function" then pcall(map.SetScale,map,Clamp(c.scale,60,130)/100) end
        local alpha=Clamp(c.opacity,10,100)/100
        if c.fadeWhileMoving and self.playerMoving then alpha=Clamp(c.movingOpacity,10,100)/100 end
        if type(map.SetAlpha)=="function" then pcall(map.SetAlpha,map,alpha) end
    else
        if type(map.SetScale)=="function" then pcall(map.SetScale,map,1) end
        if type(map.SetAlpha)=="function" then pcall(map.SetAlpha,map,1) end
    end

    local hide=self.db.enabled and c.hideBorder
    SetShownSafe(map.NineSlice,not hide)
    if map.BorderFrame and map.BorderFrame.NineSlice then SetShownSafe(map.BorderFrame.NineSlice,not hide) end

    if self.dragHandle then self.dragHandle:SetShown(self.db.enabled and c.unlockMap) end
end

function A:UpdateCoords()
    if not self.mapOverlay or not self.db then return end
    local map=self:GetWorldMap()
    if not map or not map:IsShown() or not self.db.enabled then
        self.mapOverlay.coords:SetText("")
        return
    end

    local c=self.db.map
    local mapID=self:GetDisplayedMapID()
    local parts={}
    if c.showPlayerCoords then
        local x,y=self:GetPlayerCoords(mapID)
        if x and y then parts[#parts+1]=string.format("Player %.1f, %.1f",x*100,y*100) end
    end
    if c.showCursorCoords then
        local x,y=self:GetCursorCoords()
        if x and y then parts[#parts+1]=string.format("Cursor %.1f, %.1f",x*100,y*100) end
    end
    self.mapOverlay.coords:SetText(table.concat(parts,"   |   "))
end

function A:GetGatherPin(index,parent)
    self.gatherPins=self.gatherPins or {}
    local pin=self.gatherPins[index]
    if pin and pin:GetParent()~=parent then pin:SetParent(parent) end
    if pin then return pin end

    pin=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    pin:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    pin:SetBackdropBorderColor(0,0,0,0.9)
    pin.icon=pin:CreateTexture(nil,"ARTWORK")
    pin.icon:SetAllPoints()
    pin.icon:SetTexCoord(0.08,0.92,0.08,0.92)
    pin:EnableMouse(true)
    pin:SetScript("OnEnter",function(self)
        if not self.node or not GameTooltip then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:AddLine("ComfyGatherer",1,0.82,0)
        GameTooltip:AddLine((self.node.profession or self.node.category or "Gathering").." · "..tostring(self.node.visits or 0).." visits",1,1,1)
        for itemID,amount in pairs(self.node.items or {}) do
            local item=type(ComfyData)=="table" and type(ComfyData.GetGatherItem)=="function" and ComfyData:GetGatherItem(itemID)
            GameTooltip:AddDoubleLine(item and item.name or ("Item "..tostring(itemID)),tostring(amount),1,1,1,0.2,1,0.2)
        end
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    self.gatherPins[index]=pin
    return pin
end

function A:HideGatherPins(from)
    for i=from or 1,#(self.gatherPins or {}) do self.gatherPins[i]:Hide() end
end

function A:RefreshGathererPins()
    local map=self:GetWorldMap()
    local c=self.db and self.db.map
    if not map or not map:IsShown() or not self.db.enabled or not c or not c.showGathererPins or type(ComfyData)~="table" or type(ComfyData.GetGatherNodesForMap)~="function" then
        self:HideGatherPins(1)
        return
    end

    local scroll=map.ScrollContainer
    local child=scroll and scroll.Child
    if not child then self:HideGatherPins(1); return end

    local mapID=self:GetDisplayedMapID()
    if not mapID then self:HideGatherPins(1); return end

    local nodes=ComfyData:GetGatherNodesForMap(mapID) or {}
    local maxPins=math.max(10,math.min(500,tonumber(c.maxGathererPins) or 250))
    local size=math.max(8,math.min(28,tonumber(c.gathererPinSize) or 14))
    local width,height=child:GetWidth(),child:GetHeight()
    if not width or not height or width<=0 or height<=0 then self:HideGatherPins(1); return end

    local count=0
    for _,node in ipairs(nodes) do
        local x,y=tonumber(node.x),tonumber(node.y)
        if x and y and x>=0 and x<=1 and y>=0 and y<=1 then
            count=count+1
            if count>maxPins then break end
            local pin=self:GetGatherPin(count,child)
            pin.node=node
            pin:SetSize(size,size)
            pin.icon:SetTexture(PIN_ICONS[node.profession] or PIN_ICONS.Other)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER",child,"TOPLEFT",x*width,-y*height)
            pin:Show()
        end
    end
    self:HideGatherPins(count+1)
end

function A:EnsureMapHooks()
    local map=self:GetWorldMap()
    if not map or self.mapHooked then return false end
    self.mapHooked=true
    self:CreateMapOverlay()

    if type(map.HookScript)=="function" then
        pcall(map.HookScript,map,"OnShow",function()
            A:ApplyMapPosition()
            A:ApplyMapAppearance()
            A:UpdateCoords()
            A:RefreshGathererPins()
        end)
    end
    return true
end

function A:ApplyAll()
    if not self.db then return end
    self:EnsureMapHooks()
    self:ApplyMapPosition()
    self:ApplyMapAppearance()
    self:UpdateCoords()
    self:RefreshGathererPins()
end

function A:RefreshFeature()
    self:ApplyAll()
end

function A:InitializeFeature()
    local f=CreateFrame("Frame")
    self.eventFrame=f
    for _,ev in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_STARTED_MOVING","PLAYER_STOPPED_MOVING","ZONE_CHANGED_NEW_AREA","ADDON_LOADED"}) do
        pcall(f.RegisterEvent,f,ev)
    end
    f:SetScript("OnEvent",function(_,ev,name)
        if ev=="PLAYER_STARTED_MOVING" then A.playerMoving=true; A:ApplyMapAppearance()
        elseif ev=="PLAYER_STOPPED_MOVING" then A.playerMoving=false; A:ApplyMapAppearance()
        elseif ev=="ADDON_LOADED" and (name=="Blizzard_WorldMap" or name=="Blizzard_MapCanvas") then A:ApplyAll()
        else A:ApplyAll() end
    end)
    f:SetScript("OnUpdate",function(self,elapsed)
        self.t=(self.t or 0)+(tonumber(elapsed) or 0)
        if self.t>=0.15 then
            self.t=0
            if A:EnsureMapHooks() then A:ApplyMapAppearance() end
            A:UpdateCoords()
            self.pinT=(self.pinT or 0)+0.15
            if self.pinT>=0.6 then self.pinT=0; A:RefreshGathererPins() end
        end
    end)
    self:ApplyAll()
end

local function CreateCategoryButton(page,text,x,y,width,onClick)
    local b=CreateFrame("Button",nil,page,"UIPanelButtonTemplate")
    b:SetSize(width or 150,24)
    b:SetPoint("TOPLEFT",x,y)
    b:SetText(text)
    b:SetScript("OnClick",onClick)
    return b
end

function A:ShowMapCategory(category)
    if not self.mapCategoryPages then return end
    self.db.map.category=category
    for key,frame in pairs(self.mapCategoryPages) do frame:SetShown(key==category) end
    for key,button in pairs(self.mapCategoryButtons or {}) do
        if button.LockHighlight then
            if key==category then button:LockHighlight() else button:UnlockHighlight() end
        end
    end
end

function A:BuildGeneralOptions(page,ui)
    local title=page:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
    title:SetPoint("TOPLEFT",20,-18)
    title:SetText(self:T("TAB_GENERAL"))

    self.mapCategoryPages={}
    self.mapCategoryButtons={}
    local categories={{"map",self:T("CAT_MAP")},{"coords",self:T("CAT_COORDS")},{"data",self:T("CAT_DATA")}}
    for i,entry in ipairs(categories) do
        local key,label=entry[1],entry[2]
        local button=CreateCategoryButton(page,label,20,-60-(i-1)*32,160,function() A:ShowMapCategory(key) end)
        self.mapCategoryButtons[key]=button
        local sub=CreateFrame("Frame",nil,page)
        sub:SetPoint("TOPLEFT",200,-55)
        sub:SetPoint("BOTTOMRIGHT",-20,20)
        sub:Hide()
        self.mapCategoryPages[key]=sub
    end

    local p=self.mapCategoryPages.map
    ui.CreateCheck(p,self:T("UNLOCK_MAP"),10,-15,function() return A.db.map.unlockMap end,function(v) A.db.map.unlockMap=v; A:ApplyMapAppearance() end)
    ui.CreateCheck(p,self:T("REMEMBER_POSITION"),10,-50,function() return A.db.map.rememberPosition end,function(v) A.db.map.rememberPosition=v end)
    ui.CreateCheck(p,self:T("HIDE_BORDER"),10,-85,function() return A.db.map.hideBorder end,function(v) A.db.map.hideBorder=v; A:ApplyMapAppearance() end)
    ui.CreateCheck(p,self:T("FADE_MOVING"),10,-120,function() return A.db.map.fadeWhileMoving end,function(v) A.db.map.fadeWhileMoving=v; A:ApplyMapAppearance() end)
    ui.CreateButton(p,self:T("RESET_POSITION"),10,-165,180,function() A:ResetMapPosition() end)
    ui.CreateSlider(p,self:T("MAP_SCALE"),60,130,5,20,-245,function() return A.db.map.scale end,function(v) A.db.map.scale=math.floor(v+0.5); A:ApplyMapAppearance() end,function(v) return math.floor(v+0.5).."%" end)
    ui.CreateSlider(p,self:T("MAP_OPACITY"),10,100,5,300,-245,function() return A.db.map.opacity end,function(v) A.db.map.opacity=math.floor(v+0.5); A:ApplyMapAppearance() end,function(v) return math.floor(v+0.5).."%" end)
    ui.CreateSlider(p,self:T("MOVING_OPACITY"),10,100,5,20,-335,function() return A.db.map.movingOpacity end,function(v) A.db.map.movingOpacity=math.floor(v+0.5); A:ApplyMapAppearance() end,function(v) return math.floor(v+0.5).."%" end)

    p=self.mapCategoryPages.coords
    ui.CreateCheck(p,self:T("PLAYER_COORDS"),10,-15,function() return A.db.map.showPlayerCoords end,function(v) A.db.map.showPlayerCoords=v; A:UpdateCoords() end)
    ui.CreateCheck(p,self:T("CURSOR_COORDS"),10,-50,function() return A.db.map.showCursorCoords end,function(v) A.db.map.showCursorCoords=v; A:UpdateCoords() end)

    p=self.mapCategoryPages.data
    ui.CreateCheck(p,self:T("GATHERER_PINS"),10,-15,function() return A.db.map.showGathererPins end,function(v) A.db.map.showGathererPins=v; A:RefreshGathererPins() end)
    ui.CreateSlider(p,self:T("GATHERER_PIN_SIZE"),8,28,1,20,-105,function() return A.db.map.gathererPinSize end,function(v) A.db.map.gathererPinSize=math.floor(v+0.5); A:RefreshGathererPins() end,function(v) return math.floor(v+0.5).." px" end)
    ui.CreateSlider(p,self:T("MAX_GATHERER_PINS"),25,500,25,300,-105,function() return A.db.map.maxGathererPins end,function(v) A.db.map.maxGathererPins=math.floor(v+0.5); A:RefreshGathererPins() end,function(v) return tostring(math.floor(v+0.5)) end)

    local note=page:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    note:SetPoint("BOTTOMLEFT",200,25)
    note:SetWidth(620)
    note:SetJustifyH("LEFT")
    note:SetText(self:T("FOREVER_NOTE"))

    self:ShowMapCategory(self.db.map.category or "map")
end
