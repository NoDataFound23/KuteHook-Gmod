pS.pMisc = {}

function pS.pMisc:BunnyHop(pCmd)
	if pCmd:KeyDown(IN_JUMP) and not pS.g_pLocalPlayer:IsFlagSet(FL_ONGROUND) then
		pCmd:SetButtons(bit.band(pCmd:GetButtons(), bit.bnot(IN_JUMP)))
	elseif pCmd:KeyDown(IN_JUMP) and pS.g_pLocalPlayer:IsFlagSet(FL_ONGROUND) then
		pCmd:SetForwardMove(10000) -- once we hit the ground we give ourselves a little boost. This allows us to go extremely fast on some servers.
	end
end

function pS.pMisc:Movement(pCmd)
	local MOVETYPE = pS.g_pLocalPlayer:GetMoveType()

	-- Are we alive?
	if pS.g_pLocalPlayer:Alive() then
		-- Make sure we aren't in a vehicle or in spectator mode.
		if not pS.g_pLocalPlayer:InVehicle() and pS.g_pLocalPlayer:GetObserverMode() == OBS_MODE_NONE then
			-- Check if we aren't in noclip or going up a ladder.
			if MOVETYPE ~= MOVETYPE_NOCLIP and MOVETYPE ~= MOVETYPE_LADDER then
				-- Should we run Bunnyhop code?
				if pCache.Misc.BunnyHop then
					pS.pMisc:BunnyHop(pCmd)
				end
			end
		end
	end
end

function pS.pMisc:OnCreateMove(pCmd)
	-- Function Calls
	pS.pMisc:Movement(pCmd)
end
