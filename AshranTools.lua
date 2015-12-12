local found = false;
local artifactUptime;
local lastKnownTime = 0;
local carrierName= "Unknown";
local artifactIsOnCoolDown = false;
local articateMayBeReady = false;
local firstTimeLoot = true;


local debugButton = CreateFrame("Button", "Buff", mainframe)
	debugButton:SetPoint("CENTER", statusBarFrame, 400, -100)
	debugButton:SetWidth(100)
	debugButton:SetHeight(25)
		
	local text = debugButton:CreateFontString(nil, "OVERLAY")
	text:SetFont("Fonts\\ARIALN.TTF", 11, nil)
	text:SetPoint("CENTER",-19,5)
	text:SetText("debug")
	debugButton.text = text
	debugButton:SetNormalFontObject("GameFontNormalSmall")
        
	debugButton:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Up")
	debugButton:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	debugButton:SetPushedTexture("Interface/Buttons/UI-Panel-Button-Down")
	debugButton:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			foundByChatEmote("Debugger");
		elseif button == "RightButton" then
			addArtifactWaypoints();
			--unLockSBFrame()
			--debugButton:Hide()
		end
	end)


local sBFrame = CreateFrame("Frame","statusBarFrame",UIParent)
	sBFrame:SetFrameStrata("BACKGROUND")
	sBFrame:SetWidth(245)
	sBFrame:SetHeight(70)
local sBTexture = sBFrame:CreateTexture(nil,"BACKGROUND")
	sBTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	sBTexture:SetAllPoints(sBFrame)
	sBFrame.texture = sBTexture
	sBFrame:SetPoint("RIGHT", -150, 170)
	sBFrame:Show()

	sBFrame:SetMovable(true)
	sBFrame:EnableMouse(true)
	sBFrame:RegisterForDrag("LeftButton")
	sBFrame:SetScript("OnDragStart", sBFrame.StartMoving)
	sBFrame:SetScript("OnDragStop", sBFrame.StopMovingOrSizing)

	
local sBF_LockButton = CreateFrame("Button", "sBFLockButton", statusBarFrame)	
    sBF_LockButton:SetPoint("TOPLEFT",0,15)
    sBF_LockButton:SetWidth(60)
    sBF_LockButton:SetHeight(25)
    local text = sBF_LockButton:CreateFontString(nil, "OVERLAY")
	text:SetFont("Fonts\\ARIALN.TTF", 11, nil)
	text:SetPoint("CENTER",-10,5)
	text:SetText("Lock")
	sBF_LockButton.text = text
    sBF_LockButton:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Up")
    sBF_LockButton:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight")
    sBF_LockButton:SetPushedTexture("Interface/Buttons/UI-Panel-Button-Down")
	sBF_LockButton:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			lockSBFrame()
		end
	end)
	
local carrierNameLabel = CreateFrame("Frame", "carrierNameFrame", statusBarFrame)
	carrierNameLabel:SetPoint("TOPLEFT",5,-5)
	carrierNameLabel:SetWidth(325)
    carrierNameLabel:SetHeight(50)


function targetCarrier()
	TargetUnit(carrierName);
end		
		
function lockSBFrame()
	saveSBFramePos()
	sBFrame:SetMovable(false)
	sBFrame:EnableMouse(false)
	frameLocked = 1
	sBF_LockButton:Hide()
end

function unLockSBFrame()
	sBFrame:SetMovable(true)
	sBFrame:EnableMouse(true)
	sBF_LockButton:Show()
	frameLocked = 0
end


function saveSBFramePos()
	local point, relativeto, relativepoint, xofs, yofs = statusBarFrame:GetPoint()		
	AshranToolsDB = {sBF_Xof = xofs,
		sBF_Yof = yofs,
		sBF_P = relativepoint,
		sBF_locked = frameLocked
	}
end
	
local eventResponseFrame = CreateFrame("Frame") --TODO one Frame for every event?
	eventResponseFrame:RegisterEvent("CHAT_MSG_ADDON");
	eventResponseFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	eventResponseFrame:RegisterEvent("ADDON_LOADED");
	eventResponseFrame:RegisterEvent("CHAT_MSG_MONSTER_EMOTE");
	eventResponseFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
	eventResponseFrame:RegisterEvent("PLAYER_LOGOUT");
	
	local function eventHandler(self, event, arg1 , arg2, arg3, arg4, arg5)
		if (event == "PLAYER_TARGET_CHANGED") then --("cause")
			findBuff("target")
			--debug("findbuff target")
		elseif (event == "CHAT_MSG_ADDON" and arg1 == MSG_PREFIX) then --("prefix", "message", "channel", "sender")
			OnMessageReceived(arg2, arg4)
			--debug("addon message from "..arg4..": "..arg2)
		elseif (event == "ADDON_LOADED" and not settingsLoadedBool) then
			--setSettings();
			if not isInAshran() then 
				--hideAddon()
			end
		elseif (event == "UPDATE_MOUSEOVER_UNIT") then --()
			findBuff("mouseover")
		elseif (event == "CHAT_MSG_MONSTER_EMOTE") then --("message", "sender", "language", "channelString", "target", "flags", unknown, channelNumber, "channelName", unknown, counter)
			findEvent(arg1, arg5)
		elseif (event == "PLAYER_LOGOUT") then --()
			saveSBFramePos()
		end
	end
	eventResponseFrame:SetScript("OnEvent", eventHandler);
	
	
local function sec2digital(seconds)
	local returnString
	local nSeconds = seconds
	if nSeconds == 0 then
		returnString = "00:00";
	else
		local nMins = string.format("%02.f", math.floor(nSeconds/60));
		local nSecs = string.format("%02.f", math.floor(nSeconds - nMins *60));
		returnString =  nMins..":"..nSecs
	end
	return returnString
end



AncientArtifactStatusBar = CreateFrame("StatusBar", nil, statusBarFrame)
	AncientArtifactStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	AncientArtifactStatusBar:GetStatusBarTexture():SetHorizTile(false)
	AncientArtifactStatusBar:SetValue(50)
	AncientArtifactStatusBar:SetWidth(225)
	AncientArtifactStatusBar:SetHeight(15)
	AncientArtifactStatusBar:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
												edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
												tile = true, tileSize = 32, edgeSize = 8, 
												insets = { left = 2, right = 2, top = 2, bottom = 2 }
												})
	AncientArtifactStatusBar:SetBackdropColor(0,0,0,1)
	AncientArtifactStatusBar:SetPoint("TOPLEFT",10,-45)
	AncientArtifactStatusBar:SetMinMaxValues(0,1)
	AncientArtifactStatusBar:SetValue(1)
	AncientArtifactStatusBar:SetStatusBarColor(1,1,0)	
	AncientArtifactStatusBar.value = AncientArtifactStatusBar:CreateFontString(nil, "OVERLAY")
	AncientArtifactStatusBar.value:SetPoint("LEFT", AncientArtifactStatusBar, "LEFT", 4, 1)
	AncientArtifactStatusBar.value:SetFont("Fonts\\ARIALN.TTF", 11, nil)
	AncientArtifactStatusBar.value:SetJustifyH("LEFT")
	AncientArtifactStatusBar.value:SetShadowOffset(1, -1)
	AncientArtifactStatusBar.value:SetTextColor(255,255,255)
	AncientArtifactStatusBar.value:SetText("Find the artifact!")
	
	AncientArtifactStatusBar:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" then
			print(AncientArtifactStatusBar.value:GetText())
		end
	end)
	
	
function findEvent(message,target)
	if message:find("168506") then
		debug("AT:Artifact lootet by "..target)
		foundByChatEmote(target)
	end
end

function foundByChatEmote(name)
	debug("found by chat")
	carrierName = name;
	if (firstTimeLoot) then
		firstTimeLoot = false;
		artifactUptime = GetTime()+1800;
		artifactFound();
	end
end


function findBuff(target)
	if (target ~= nil) then
		for i= 1, 40 do
			local name, _, _, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(target,i);
			artifactUptime = expirationTime;
			if (spellId == 168506 and expirationTime) then 
				--print("found buff "..name.." with duration "..duration.." and remaining time of "..SecondsToTime(expirationTime-GetTime()).." on "..UnitName(target));
				carrierName = UnitName(target);
				artifactFound();				
				break;
			end
		end
	end
end


function artifactFound()
	found = true;
	AncientArtifactStatusBar:SetMinMaxValues(0, 1800)
	AncientArtifactStatusBar:SetStatusBarColor(0,1,0)
end

function artifactOnCooldown()
	lastKnownTime = 0;
	CDTime = GetTime()+900;
	artifactIsOnCoolDown = true
	found = false;
	AncientArtifactStatusBar:SetMinMaxValues(0,900)
	AncientArtifactStatusBar:SetStatusBarColor(1,0,0)
end

function artifactMayBeReady()
	CDTimeReady = GetTime()+900;
	artifactIsOnCoolDown = false
	articateMayBeReady = true
	AncientArtifactStatusBar:SetMinMaxValues(0,900)
	AncientArtifactStatusBar:SetStatusBarColor(1,0.5,0)
end

function artifactNotYetFound()
	articateMayBeReady = false
	AncientArtifactStatusBar:SetMinMaxValues(0,1)
	AncientArtifactStatusBar:SetValue(1)
	AncientArtifactStatusBar:SetStatusBarColor(1,1,0)
	AncientArtifactStatusBar.value:SetText("Find the artifact!")
end

local waypointsList = {
	{60.3, 28.7},
	{62.4, 31.3},
	{32.4, 30.3},
	{32.2, 36.3},
	{43.1, 51.8},
	{37.1, 60.9},
	{35.0, 62.6},
	{37.0, 65.4},
	{58.3, 68.2},
	{58.4, 72.4},
}


function addArtifactWaypoints()
	if _G.TomTom then
		for  k,v in ipairs(waypointsList) do
			--debug("key "..v[1].." value "..v[2]);
			TomTom:AddWaypoint(v[1],v[2], "Ancient Artifact");
		end
	end
end



local updater=CreateFrame("Frame")
updater:SetScript("OnUpdate", function(self)
	if (found) then
		artifactIsOnCoolDown = false
		if (artifactUptime ~= nil) then 
			lastKnownTime = artifactUptime
		else 
			artifactUptime = lastKnownTime
		end
		AncientArtifactStatusBar:SetValue(artifactUptime-GetTime())
		local text = carrierNameLabel:CreateFontString(nil, "OVERLAY")
			text:SetFont("Fonts\\ARIALN.TTF", 15, nil)
			text:SetPoint("LEFT",10,5)
			text:SetText(carrierName)
			carrierNameLabel.text = text
		AncientArtifactStatusBar.value:SetText(sec2digital(artifactUptime-GetTime()))
		if artifactUptime-GetTime() <= 0 then
			artifactOnCooldown()
			firstTimeLoot = true;
		end
	elseif (artifactIsOnCoolDown) then
		AncientArtifactStatusBar:SetValue(CDTime-GetTime())
		AncientArtifactStatusBar.value:SetText("Cooldown: "..sec2digital(CDTime-GetTime()))
		if (CDTime-GetTime() <= 0) then
			artifactMayBeReady()
		end
	elseif (articateMayBeReady) then
		AncientArtifactStatusBar:SetValue(CDTimeReady-GetTime())
		AncientArtifactStatusBar.value:SetText("ReadyCooldown: "..sec2digital(CDTimeReady-GetTime()))	
		if (CDTimeReady-GetTime() <= 0) then
			artifactNotYetFound()
		end
				
	end
end)



--SLASH-----------------------

local function handler(msg, editbox)
	local command, rest = msg:match("^(%S*)%s*(.-)$");
	if command == "unlock" then
		--debug("unlock")
		unLockSBFrame();
	elseif command == "sync" then
		requestSync();
	end
end

SlashCmdList["ASHRANTOOLS"] = handler;


--SYNC--------------

local MSG_PREFIX = "ASHRANTOOLS"
RegisterAddonMessagePrefix(MSG_PREFIX)
--SendAddonMessage(MSG_PREFIX, "request", "INSTANCE_CHAT")

SLASH_ASHRANTOOLS1 = '/ashrantools';

function isInAshran() --TODO better zoneID?
	return GetZoneText() == "Ashran";
end

function sendInstanceMessage(message)
	SendAddonMessage(MSG_PREFIX, message, "INSTANCE_CHAT")
end

function sendWhisperMessage(message, name)
	debug("sending message to "..name..": "..message)
	SendAddonMessage(MSG_PREFIX, message, "WHISPER", name)	
end

function OnMessageReceived(message, sender)
	--debug("got message from "..sender..": "..message)
	--debug("isme?: "..tostring(isMe(sender)))
	local incoming = splitString(message)
	--debug(table.getn(incoming))
	if incoming[1] == "syncrequest" then
		sendWhisperMessage("timersync "..getStates(), sender)
	elseif incoming[1] == "timersync" and not isMe(sender) then
		setStates(incoming[2],incoming[3],incoming[4],incoming[5])
	end
end

function requestSync()
	if IsInRaid() then
		sendInstanceMessage("syncrequest")
		--debug("not in raid")
	end
	sendWhisperMessage("syncrequest", UnitName("player"))
end

function splitString(inString)
	local splited ={}
	for i in string.gmatch(inString, "%S+") do
		--debug("splitting "..i)
		tinsert(splited, i)
	end
	return splited
end

function isMe(name)
	--print((UnitName("player").."-"..GetRealmName())..".."..name)
	return (UnitName("player").."-"..GetRealmName()) == name 
end
--SYNC--------------------



function setSettings()
	debug("setSettings")
	if (AshranToolsDB) then
		debug(AshranToolsDB.sBF_P)
		debug(AshranToolsDB.sBF_Xof)
		debug(AshranToolsDB.sBF_Yof)
		frameLocked = AshranToolsDB.sBF_locked
		sBFrame:SetPoint(AshranToolsDB.sBF_P, AshranToolsDB.sBF_Xof, AshranToolsDB.sBF_Yof)
		settingsLoadedBool = true;
		debug("seetings loaded")
		if frameLocked == 1 then
			lockSBFrame()
		end
	else
		sBFrame:SetPoint("RIGHT",-150,170)
		AshranToolsDB = {sBF_Xof = -150,
			sBF_Yof = 170,
			sBF_P = "RIGHT",
			sBF_locked = 0
		}
		--tinsert(AshranToolsDB, settings)
		
		debug("no settings found, load default")
	end
end


--DEBUG
function debug(debugtext)
	print(debugtext)
end

