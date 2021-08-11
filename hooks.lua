hook.Add('CreateMove', 'pCreateMove', function(pCmd)
	if pCmd:CommandNumber() ~= 0 then
		-- Make sure it goes in this order.
		pS.pMisc:OnCreateMove(pCmd)
	end
end)

--==================================================================================--

hook.Add('CalcView', 'pCalcView', function(plyPlayer, vecOrigin, angAngles, flFov)
	return {
		origin = vecOrigin,
		angles = angViewAngle,
		fov = pCache.Misc.CustomFOV
	}
end)

--==================================================================================--

gameevent.Listen('player_hurt')

hook.Add('player_hurt', 'pPlayerHurt', function(pData)
	-- TODO: Add an actual hitmarker instead of just playing a sound.
	if not pCache.Misc.Hitmarker then
		return
	end

	local numVictimID = pData.userid
	local numAttackerID = pData.attacker
	local numLocalPlyID = pS.g_pLocalPlayer:UserID()

	if numAttackerID ~= numLocalPlyID then
		return
	end

	if numVictimID == numLocalPlyID then
		return
	end

	if IsMounted('tf') then
		surface.PlaySound('ui/hitsound_electro' .. math.random(1, 3) .. '.wav')
	else
		surface.PlaySound('buttons/blip2.wav')
	end
end)

gameevent.Listen('player_spawn')

hook.Add('player_spawn', 'pPlayerSpawn', function(pData) -- Called when the player spawns initially or respawns.
	local numPlayerID = pData.userid

	if Player(numPlayerID).m_bNoHitbox then
		-- Rebuild the player's hitbox
		Player(numPlayerID).m_bNoHitbox = nil
		Player(numPlayerID).tblHitbox = nil
	end
end)

--==================================================================================--

-- This was never implemented :(
--[[
	-- For Error handling.
	hook.Add('OnLuaError', 'pOnLuaError', function(strError, numRealm, tblStack, strName, numID)

	end)
]]

--==================================================================================--

hook.Add('HUDPaint', 'pHUDPaint', function()
	cam.Start3D()
	pS.pVisuals:RenderPropEsp()
	pS.pVisuals:RenderPlayerEsp()
	pS.pVisuals:RenderPropTracers()
	cam.End3D()

	pS.pVisuals:DrawPlayerEsp()
	pS.pVisuals:DrawPropInfo()
	pS.pVisuals:DrawCrosshair()
end)

hook.Add('RenderScreenspaceEffects', 'pRenderScreenspaceEffects', function()
	pS.pVisuals:RenderHeadBeams()
end)

-- BUG: This renders both our stuff and a copy of it but in the skybox, could just be the hook I'm using that breaks it.
hook.Add('PreDrawOpaqueRenderables', 'pPreDrawOpaqueRenderables', function()
	pS.pVisuals:DrawTrajectory()
end)
