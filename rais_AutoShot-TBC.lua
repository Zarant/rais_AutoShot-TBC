
local _,class = UnitClass("player");
if not(class == "HUNTER") then return end

local AddOn = "rais_AutoShot-TBC"
local _G = getfenv(0)

local r

local Textures = {
	Bar = "Interface\\AddOns\\"..AddOn.."\\Textures\\Bar.tga",
}

local Table = {
	["posX"] = 0;
	["posY"] = -180;
	["Width"] = 100;
	["Height"] = 15;
}


local Debug = false

local castTime = 0.55

local autoShot = GetSpellInfo(75)
local steadyShot = GetSpellInfo(34120)
local multiShot = GetSpellInfo(2643)
local aimedShot = GetSpellInfo(19434)

local strafeLeft, strafeRight, moveForward, moveBackward, moveAndSteer, rightClick, leftClick

local function IsMoving()
	return strafeLeft or strafeRight or moveForward or moveBackward or moveAndSteer or (leftClick and rightClick)
end


hooksecurefunc("CameraOrSelectOrMoveStart",function() leftClick=true end)
hooksecurefunc("CameraOrSelectOrMoveStop",function() leftClick=false end)

hooksecurefunc("TurnOrActionStart",function() rightClick=true end)
hooksecurefunc("TurnOrActionStop",function() rightClick=false end)

hooksecurefunc("StrafeLeftStart",function() strafeLeft=true end)
hooksecurefunc("StrafeLeftStop",function() strafeLeft=false end)

hooksecurefunc("StrafeRightStart",function() strafeRight=true end)
hooksecurefunc("StrafeRightStop",function() strafeRight=false end)

hooksecurefunc("MoveBackwardStart",function() moveBackward=true end)
hooksecurefunc("MoveBackwardStop",function() moveBackward=false end)

hooksecurefunc("MoveForwardStart",function() moveForward=true end)
hooksecurefunc("MoveForwardStop",function() moveForward=false end)

hooksecurefunc("MoveAndSteerStart",function() moveAndSteer=true end)
hooksecurefunc("MoveAndSteerStop",function() moveAndSteer=false end)


local castdelay = 0
local castStart = false;
local swingStart = false;

local posX, posY 
local swingTime
local prevswing = 0
local relative
local InterruptTimer = 0


local Lat,Background
local autoshot_latency_update

local function UpdateFrame(self,w,h,x,y)

	w = w or self:GetWidth()
	h = h or self:GetHeight()
	if w < 33 then
		w = 33
	end
	if h < 5 then
		h = 5
	end
	self:SetWidth(w)
	self:SetHeight(h)
	if x and y then
		self:SetPoint("CENTER",UIParent,"CENTER",x,y)
		r.point = "CENTER"
		r.relativePoint = "CENTER"
		r.x = x
		r.y = y
	end
	local wdiff = w - r.w
	local hdiff = h - r.h
	r.w = w
	r.h = h

	for _,t in pairs({self:GetRegions()}) do
		t:SetAlpha(1)
		t:SetWidth(t:GetWidth()+wdiff)
		t:SetHeight(t:GetHeight()+hdiff)
	end

	for _,f in pairs({self:GetChildren()}) do
		f:SetAlpha(1)
		f:SetWidth(r.w)
		f:SetHeight(r.h)
		for _,t in pairs({f:GetRegions()}) do
			t:SetAlpha(1)
			t:SetWidth(t:GetWidth()+wdiff)
			t:SetHeight(t:GetHeight()+hdiff)
		end
	end
	autoshot_latency_update()
end

function r_Reset()
	local f = _G[AddOn.."_Frame_Timer"]
	local x = Table["posX"] *GetScreenWidth() /1000;
	local y = Table["posY"] *GetScreenHeight() /1000;
	local w = Table["Width"] *GetScreenWidth() /1000;
	local h = Table["Height"] *GetScreenHeight() /1000;
	UpdateFrame(f,w,h,x,y)
end

function r_Latency(arg)
	r.autoshot_latency = tonumber(arg) or 0
	r.autoshot_latency = r.autoshot_latency/1e3
end

local function AutoShotBar_Create()
	r.x = r.x or Table["posX"] *GetScreenWidth() /1000;
	r.y = r.y or Table["posY"] *GetScreenHeight() /1000;
	r.w = r.w or Table["Width"] *GetScreenWidth() /1000;
	r.h = r.h or Table["Height"] *GetScreenHeight() /1000;
	r.point = r.point or "CENTER"
	r.relativePoint = r.relativePoint or "CENTER"

	local backdrop = {
		bgFile = "Interface/BUTTONS/WHITE8X8",
		tile = true,
		tileSize = 8,
	}

	_G[AddOn.."_Frame_Timer"] = CreateFrame("Frame",nil,UIParent);
	local Frame = _G[AddOn.."_Frame_Timer"];

	Frame:SetBackdrop(backdrop)
	Frame:SetBackdropColor(0.15,0.15,0.15)
	Frame:SetFrameLevel(1)
	Frame:SetFrameStrata("HIGH");
	Frame:SetWidth(r.w);
	Frame:SetHeight(r.h);
	Frame:SetPoint(r.point,UIParent,r.relativePoint,r.x,r.y);

	_G[AddOn.."_Frame_Timer2"] = CreateFrame("Frame",nil,Frame);
	local Frame2 = _G[AddOn.."_Frame_Timer2"];
	Frame2:SetFrameLevel(2)
	Frame2:SetFrameStrata("HIGH");
	Frame2:SetWidth(r.w);
	Frame2:SetHeight(r.h);
	Frame2:SetPoint("CENTER",Frame,"CENTER");
	--Frame2:SetAlpha(0);

	Frame:SetClampedToScreen(true)
	Frame:SetScript("OnMouseDown", function(self, button)
		if IsAltKeyDown() then
			self:StartSizing("BOTTOMRIGHT")

			for _,t in pairs({Frame:GetRegions()}) do
				t:SetAlpha(0)
			end

			for _,f in pairs({self:GetChildren()}) do
				f:SetAlpha(0)
			end

		else
			self:StartMoving()
		end
	end)
	Frame:SetScript("OnMouseUp", function(self,button)
		local point, relativeTo, relativePoint, x, y = self:GetPoint()
		r.point = point
		r.relativePoint = relativePoint
		r.x = x
		r.y = y
		self:StopMovingOrSizing()
		UpdateFrame(self)

	end)


	_G[AddOn.."_Texture_Timer"] = Frame2:CreateTexture(nil,"OVERLAY"); --overlay
	local Bar = _G[AddOn.."_Texture_Timer"];
	Bar:SetHeight(r.h);
	Bar:SetTexture(Textures.Bar);
	Bar:SetPoint("CENTER",Frame2,"CENTER");



	_G[AddOn.."_Texture_LATENCY"] = Frame:CreateTexture(nil,"OVERLAY");
	Lat = _G[AddOn.."_Texture_LATENCY"];
	Lat:SetHeight(r.h);
	Lat:SetTexture(Textures.Bar);
	Lat:SetPoint("CENTER",Frame,"CENTER");
	Lat:SetVertexColor(0.15,0.15,0.15)

	SetWidth_OLD = Lat.SetWidth
	function Lat.SetWidth(self,width)
		--print('ok')
		return SetWidth_OLD(self,width*(castTime - castdelay)/castTime)
	end
	Lat:SetWidth(r.w);

	_G[AddOn.."_Texture_BG"] = Frame:CreateTexture(nil,"ARTWORK");
	Background = _G[AddOn.."_Texture_BG"];
	Background:SetHeight(r.h);
	Background:SetTexture(Textures.Bar);
	Background:SetPoint("CENTER",Frame,"CENTER");
	Background:SetVertexColor(0.5,0.5,0.5)
	Background:SetWidth(r.w);


	Border = Frame:CreateTexture(nil,"BORDER"); 
	Border:SetPoint("CENTER",Frame,"CENTER");
	Border:SetWidth(r.w +3);
	Border:SetHeight(r.h +3);
	Border:SetTexture(0,0,0);


	local Border = Frame:CreateTexture(nil,"BACKGROUND");
	Border:SetPoint("CENTER",Frame,"CENTER");
	Border:SetWidth(r.w +6);
	Border:SetHeight(r.h +6);
	Border:SetTexture(1,1,1);
	--]]


end

local isLocked = true
function r_Lock()

	if isLocked then
		local f = _G[AddOn.."_Frame_Timer"]
		f:Show()
		--f:SetAlpha(1);
		f:SetResizable(true)
		f:SetMovable(true)
		f:EnableMouse(true)
	else
		local f = _G[AddOn.."_Frame_Timer"]
		f:Hide()
		f:SetResizable(false)
		f:SetMovable(false)
		f:EnableMouse(false)
	end
	isLocked = not(isLocked)
end


function autoshot_latency_update()

	Lat:SetWidth(r.w);
	Background:SetDrawLayer("ARTWORK")

end


local function HideFrame()
	if isLocked then
		_G[AddOn.."_Frame_Timer"]:Hide();
	end
--_G[AddOn.."_Frame_Timer2"]:SetAlpha(0);
end

local function ShowFrame()
	_G[AddOn.."_Frame_Timer"]:Show();
end

local function Cast_Start()


	if IsSpellInRange(autoShot,"target") ~= 1 or IsAutoRepeatSpell(autoShot) ~= 1 then
		HideFrame()
		swingStart = false;
	else
		autoshot_latency_update()
		_G[AddOn.."_Texture_Timer"]:SetVertexColor(1,0,0);
		posX, posY = GetPlayerMapPosition("player");
		castStart = GetTime();
	end


end

local function Cast_Interrupted()
	HideFrame()

	swingStart = false;

	Cast_Start()
end

local function Cast_Update()
	ShowFrame()
	relative = GetTime() - castStart;

	if ( relative > castTime ) then
		castStart = false;
		HideFrame()
	elseif ( swingStart == false ) then
		--if  (UnitCastingInfo("player") ~= nil or IsCurrentSpell(steadyShot) or IsCurrentSpell(multiShot)) then --or InterruptTimer > GetTime()
		--	Cast_Interrupted()
	--	else
			_G[AddOn.."_Texture_Timer"]:SetWidth(r.w * relative/castTime);
	--	end
	end
	if ((relative > (castTime - castdelay)) and (castStart ~= false)) then
		_G[AddOn.."_Texture_Timer"]:SetVertexColor(0,0,0.5);

	end

end




local prevswingspeed = false
local function Swing_Start()


	swingTime = UnitRangedDamage("player") - castTime;

	if not prevswingspeed then
		prevswingspeed = swingTime
	end

	if (GetTime() - prevswing) > (prevswingspeed+0.3) then
		ShowFrame()

		_G[AddOn.."_Texture_Timer"]:SetVertexColor(1,1,1);
		castStart = false
		swingStart = GetTime();
		prevswing = swingStart;
		prevswingspeed = swingTime
	end

end



--[[
local function print(a)
	DEFAULT_CHAT_FRAME:AddMessage(a)
end
]]

local Frame = CreateFrame("Frame");
Frame:RegisterEvent("UNIT_SPELLCAST_SENT")
Frame:RegisterEvent("PLAYER_LOGIN")
Frame:RegisterEvent("UNIT_SPELLCAST_STOP")

Frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
Frame:RegisterEvent("UNIT_SPELLCAST_START")
Frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

if Debug == true then
	Frame:RegisterAllEvents()
end



Frame:SetScript("OnEvent",function()


	if Debug == true then

		if not ((event == "WORLD_MAP_UPDATE") or (event == "UPDATE_SHAPESHIFT_FORM") or string.find(event,"LIST_UPDATE") or string.find(event,"COMBAT_LOG") or string.find(event,"CHAT") or string.find(event,"CHANNEL")) then
			local a = GetTime()..' '..event..':'
			if arg1 ~= nil then
				a = a.."/"..tostring(arg1)
			end
			if arg2 ~= nil then
				a = a.."/"..tostring(arg2)
			end
			if arg3 ~= nil then
				a = a.."/"..tostring(arg3)
			end
			if arg4 ~= nil then
				a = a.."/"..tostring(arg4)
			end
			DEFAULT_CHAT_FRAME:AddMessage(a)
		end
	end

	if ((event == "UNIT_SPELLCAST_SUCCEEDED") or (event == "UNIT_SPELLCAST_START") or (event == "UNIT_SPELLCAST_STOP")) and arg1 == "player" then

		if arg2 == autoShot then
		castdelay = r.autoshot_latency
		autoshot_latency_update();
		Swing_Start();

		elseif _G[AddOn.."_Frame_Timer"]:GetAlpha() == 0 and (arg2 == steadyShot or arg2 == multiShot or arg2 == aimedShot) then
			Cast_Interrupted();
		end

	end

	--
	if event == "UNIT_SPELLCAST_FAILED" and arg1 == "player" and (arg2 == autoShot ) then
		Cast_Interrupted();
	end

	if event == "UNIT_SPELLCAST_SENT" and arg1 == "player" then 

		if arg2 == multiShot then
			InterruptTimer = GetTime()+0.5
		elseif arg2 == autoShot and castStart == false and swingStart == false and not UnitCastingInfo("player") then
			Cast_Start()
		end
	end

	if ( event == "PLAYER_LOGIN" ) then
		if type(raisAutoShot) ~= "table" then
			raisAutoShot = {}
			r.autoshot_latency = 0
		end
		r = raisAutoShot
		AutoShotBar_Create();
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff"..AddOn.."|cffffffff Loaded");
	end



end)

local AutoShotRange = 0

Frame:SetScript("OnUpdate",function()


	if ( swingStart == false ) then

		local cposX, cposY = GetPlayerMapPosition("player") -- player position atm

		if ( posX == cposX and posY == cposY ) and IsAutoRepeatSpell(autoShot) and not IsMoving() then
			if  castStart ~= false then
				Cast_Update();
			end
		else
			if castdelay < 0 then

				castdelay = 0

			end
			Cast_Interrupted();

		end
	end


	if ( swingStart ~= false ) then
		relative = GetTime() - swingStart

		_G[AddOn.."_Texture_Timer"]:SetWidth(r.w - (r.w*relative/swingTime));
		_G[AddOn.."_Texture_Timer"]:SetVertexColor(1,1,1);



		if ( relative > swingTime ) then
			if UnitCastingInfo("player") == nil then
				Cast_Start()
			else
				_G[AddOn.."_Texture_Timer"]:SetWidth(0);
				HideFrame()
			end
			swingStart = false;
		end
	end
	--autoshot_latency_update()
	AutoShotRange = IsSpellInRange(autoShot,"target")


end)


SLASH_RAISAUTOSHOT1 = "/raisautoshot"

local 	commandList = {
		["lock"] = {r_Lock,SLASH_RAISAUTOSHOT1.." lock | Lock/Unlock the bar, use alt+click to resize"};
		["reset"] = {r_Reset,SLASH_RAISAUTOSHOT1.." reset | reset to the default positions"};
		["latency"] = {r_Latency,SLASH_RAISAUTOSHOT1.." latency <number> | Sets the latency threshold indicator (in milliseconds)"};
	}


SlashCmdList["RAISAUTOSHOT"] = function(msg)
	_,_,cmd,arg = strfind(msg,"%s?(%w+)%s?(.*)")


	if cmd then
		cmd = strlower(cmd)
	end
	if arg == "" then
		arg = nil
	end

	if cmd == "help" or not cmd or cmd == "" then
		local list = {"Command List:",SLASH_RAISAUTOSHOT1.." help"}
		for command,entry in pairs(commandList) do
			if arg == command then
				print(entry[2])
				return
			else
				table.insert(list,SLASH_RAISAUTOSHOT1.." "..command)
			end
		end
		for i,v in pairs(list) do
			print(v)
		end
		print("For more info type "..SLASH_RAISAUTOSHOT1.." help <command>")
	else
		for command,entry in pairs(commandList) do
			if cmd == command then
				entry[1](arg)
				return 
			end
		end
	end
end 