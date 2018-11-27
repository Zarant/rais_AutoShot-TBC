
local _,class = UnitClass("player");
if not(class == "HUNTER") then return end

local AddOn = "rais_AutoShot"
local _G = getfenv(0)


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
autoshot_latency = 0
local castTime = 0.60


	


local castdelay = 0
local castStart = false;
local swingStart = false;
local shooting = false; 
local posX, posY 
local swingTime
local prevswing = 0
local relative
local InterruptTimer = 0


local Lat


local function AutoShotBar_Create()
	Table["posX"] = Table["posX"] *GetScreenWidth() /1000;
	Table["posY"] = Table["posY"] *GetScreenHeight() /1000;
	Table["Width"] = Table["Width"] *GetScreenWidth() /1000;
	Table["Height"] = Table["Height"] *GetScreenHeight() /1000;

	_G[AddOn.."_Frame_Timer"] = CreateFrame("Frame",nil,UIParent);
	local Frame = _G[AddOn.."_Frame_Timer"];
	Frame:SetFrameLevel(1)
	Frame:SetFrameStrata("HIGH");
	Frame:SetWidth(Table["Width"]);
	Frame:SetHeight(Table["Height"]);
	Frame:SetPoint("CENTER",UIParent,"CENTER",Table["posX"],Table["posY"]);
	Frame:SetAlpha(0);
	
	_G[AddOn.."_Frame_Timer2"] = CreateFrame("Frame",nil,UIParent);
	local Frame2 = _G[AddOn.."_Frame_Timer2"];
	Frame2:SetFrameLevel(2)
	Frame2:SetFrameStrata("HIGH");
	Frame2:SetWidth(Table["Width"]);
	Frame2:SetHeight(Table["Height"]);
	Frame2:SetPoint("CENTER",UIParent,"CENTER",Table["posX"],Table["posY"]);
	Frame2:SetAlpha(0);
	
	

	_G[AddOn.."_Texture_Timer"] = Frame2:CreateTexture(nil,"OVERLAY"); --overlay
	local Bar = _G[AddOn.."_Texture_Timer"];
	Bar:SetHeight(Table["Height"]);
	Bar:SetTexture(Textures.Bar);
	Bar:SetPoint("CENTER",Frame2,"CENTER");

	

	_G[AddOn.."_Texture_LATENCY"] = Frame:CreateTexture(nil,"OVERLAY");
	Lat = _G[AddOn.."_Texture_LATENCY"];
	Lat:SetHeight(Table["Height"]);
	Lat:SetTexture(Textures.Bar);
	Lat:SetPoint("CENTER",Frame,"CENTER");
	Lat:SetVertexColor(0.15,0.15,0.15)
	Lat:SetWidth(Table["Width"] * (castTime - castdelay)/castTime);
	
	
	_G[AddOn.."_Texture_BG"] = Frame:CreateTexture(nil,"ARTWORK");
	Background = _G[AddOn.."_Texture_BG"];
	Background:SetHeight(Table["Height"]);
	Background:SetTexture(Textures.Bar);
	Background:SetPoint("CENTER",Frame,"CENTER");
	Background:SetVertexColor(0.5,0.5,0.5)
	Background:SetWidth(Table["Width"]);
	

	Border = Frame:CreateTexture(nil,"BORDER"); 
	Border:SetPoint("CENTER",Frame,"CENTER");
	Border:SetWidth(Table["Width"] +3);
	Border:SetHeight(Table["Height"] +3);
	Border:SetTexture(0,0,0);
	

	local Border = Frame:CreateTexture(nil,"BACKGROUND");
	Border:SetPoint("CENTER",Frame,"CENTER");
	Border:SetWidth(Table["Width"] +6);
	Border:SetHeight(Table["Height"] +6);
	Border:SetTexture(1,1,1);
end

local function autoshot_latency_update()
	
	Lat:SetWidth(Table["Width"] * (castTime - castdelay)/castTime);
	Background:SetDrawLayer("ARTWORK")
	
end




local function Cast_Start()
	

	if IsSpellInRange("Auto Shot","target") ~= 1 then
		_G[AddOn.."_Frame_Timer"]:SetAlpha(0);
		_G[AddOn.."_Frame_Timer2"]:SetAlpha(0);
		swingStart = false;
	else
		autoshot_latency_update()
		_G[AddOn.."_Texture_Timer"]:SetVertexColor(1,0,0);
		posX, posY = GetPlayerMapPosition("player");
		castStart = GetTime();
	end

	
end

local function Cast_Interrupted()
	_G[AddOn.."_Frame_Timer"]:SetAlpha(0);
	_G[AddOn.."_Frame_Timer2"]:SetAlpha(0);
	
	swingStart = false;
	
	Cast_Start()
end

local function Cast_Update()
	_G[AddOn.."_Frame_Timer"]:SetAlpha(1);
	_G[AddOn.."_Frame_Timer2"]:SetAlpha(1);
	relative = GetTime() - castStart;
	
	if ( relative > castTime ) then
		castStart = false;
		_G[AddOn.."_Frame_Timer"]:SetAlpha(0);
		_G[AddOn.."_Frame_Timer2"]:SetAlpha(0);
	elseif ( swingStart == false ) then
		if  UnitCastingInfo("player") ~= nil or InterruptTimer > GetTime() then
			Cast_Interrupted()
		else
			_G[AddOn.."_Texture_Timer"]:SetWidth(Table["Width"] * relative/castTime);
		end
	end
	if ((relative > (castTime - castdelay)) and (castStart ~= false)) then
		_G[AddOn.."_Texture_Timer"]:SetVertexColor(0,0,0.5);		

	end
	
end


local function Shot_Start()
	Cast_Start();
	shooting = true;
end

local function Shot_End()
	if ( swingStart == false ) then
		_G[AddOn.."_Frame_Timer"]:SetAlpha(0);
		_G[AddOn.."_Frame_Timer2"]:SetAlpha(0);
	end
	castStart = false
	shooting = false
end


local prevswingspeed = false
local function Swing_Start()
	
	
	swingTime = UnitRangedDamage("player") - castTime;
	
	if not prevswingspeed then
		prevswingspeed = swingTime
	end
	
	if (GetTime() - prevswing) > (prevswingspeed+0.3) then
		_G[AddOn.."_Frame_Timer"]:SetAlpha(1);
		_G[AddOn.."_Frame_Timer2"]:SetAlpha(1);
		_G[AddOn.."_Texture_Timer"]:SetVertexColor(1,1,1);
		castStart = false
		swingStart = GetTime();
		prevswing = swingStart;
		prevswingspeed = swingTime
	end
	
end




local function print(a)
	DEFAULT_CHAT_FRAME:AddMessage(a)
end

local Frame = CreateFrame("Frame");
Frame:RegisterEvent("UNIT_SPELLCAST_SENT")
Frame:RegisterEvent("PLAYER_LOGIN")
Frame:RegisterEvent("UNIT_SPELLCAST_STOP")
Frame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
Frame:RegisterEvent("START_AUTOREPEAT_SPELL")
Frame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
Frame:RegisterEvent("ITEM_LOCK_CHANGED")
Frame:RegisterEvent("CHAT_MSG_SPELL_FAILED_LOCALPLAYER")
Frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
Frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")

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

	if (event == "UNIT_SPELLCAST_SUCCEEDED") and arg1 == "player" then

		if arg2 == "Auto Shot" then
		castdelay = autoshot_latency/1e3
		autoshot_latency_update();
		Swing_Start();
		
		elseif _G[AddOn.."_Frame_Timer"]:GetAlpha() == 0 and (arg2 == "Steady Shot" or arg2 == "Multi-Shot" or arg2 == "Aimed Shot") then

			Cast_Interrupted();	
		end

	end
	
	if event == "UNIT_SPELLCAST_SENT" and arg1 == "player" and arg2 == "Multi-Shot" then
		InterruptTimer = GetTime()+0.5
	end
	
	if ( event == "PLAYER_LOGIN" ) then
		AutoShotBar_Create();
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff"..AddOn.."|cffffffff Loaded");
	end
	
	if ( event == "START_AUTOREPEAT_SPELL" ) then
		if castdelay > 0 then
			castdelay = 0
			autoshot_latency_update();
		end
		
		Shot_Start();	
	end
	
	if ( event == "STOP_AUTOREPEAT_SPELL" ) then
		prevswingspeed = false
		Shot_End();
	end


end)

local AutoShotRange = 0
Frame:SetScript("OnUpdate",function()
	
	if IsSpellInRange("Auto Shot","target") == 1 and AutoShotRange == 0 and castStart == false and swingStart == false then
	   Cast_Start()
	end
	
	if ( shooting == true ) then

		autoshot_latency_update()
		if ( castStart ~= false ) then
		
			local cposX, cposY = GetPlayerMapPosition("player") -- player position atm				

			if ( posX == cposX and posY == cposY ) then
				Cast_Update();
			else
				if castdelay > 0 then
					
					castdelay = 0
					autoshot_latency_update();
				end
				Cast_Interrupted();

			end
		end
		
	end

	if ( swingStart ~= false ) then
		relative = GetTime() - swingStart

		_G[AddOn.."_Texture_Timer"]:SetWidth(Table["Width"] - (Table["Width"]*relative/swingTime));
		_G[AddOn.."_Texture_Timer"]:SetVertexColor(1,1,1);
		
	
		if ( relative > swingTime ) then
			if ( shooting == true and UnitCastingInfo("player") == nil ) then
				Cast_Start()
			else
				_G[AddOn.."_Texture_Timer"]:SetWidth(0);
				_G[AddOn.."_Frame_Timer"]:SetAlpha(0);
				_G[AddOn.."_Frame_Timer2"]:SetAlpha(0);
			end
			swingStart = false;
		end
	end
	AutoShotRange = IsSpellInRange("Auto Shot","target")

end)
