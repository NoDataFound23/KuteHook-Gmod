pS.pVisuals = {}
pS.pVisuals.ClosestToProp = nil

-- Materials for ESP.
pS.pVisuals.WireFrameMat = Material('models/wireframe')
pS.pVisuals.ShinyMat = Material('models/shiny')
pS.pVisuals.BeamMat = Material("sprites/tp_beam001")

-- A table of attack props.
pS.pVisuals.AttackProps = {
	['models/props/de_tides/gate_large.mdl'] = true,
	['models/props/CS_militia/refrigerator01.mdl'] = true
}

-- A table of defense props
pS.pVisuals.DefenseProps = {
	['models/props_canal/canal_bars002.mdl'] = true,
	['models/props_canal/canal_bars004.mdl'] = true
}

pS.pVisuals.RT = GetRenderTarget('pRenderTarget' .. os.time(), ScrW(), ScrH())

-- Chams materials.
pS.pVisuals.ChamsMat = CreateMaterial('pChams' .. os.time(), 'VertexLitGeneric', {
	['$basetexture'] = 'models/debug/debugwhite',
	['$model'] = 1
})

function pS.pVisuals:GetEspBoxBounds(entEntity)
	local tblBox = { x = math.huge, y = math.huge, w = math.huge * -1, h = math.huge * -1 }
	local vecBoxMins, vecBoxMaxs = entEntity:OBBMins(), entEntity:OBBMaxs()
	local vecBoundaryBoxCenter = entEntity:LocalToWorld(entEntity:OBBCenter()):ToScreen()

	local m_tblBoxBounds = {
		Vector(vecBoxMins.x, vecBoxMins.y, vecBoxMins.z),
		Vector(vecBoxMins.x, vecBoxMins.y, vecBoxMaxs.z),
		Vector(vecBoxMins.x, vecBoxMaxs.y, vecBoxMins.z),
		Vector(vecBoxMins.x, vecBoxMaxs.y, vecBoxMaxs.z),
		Vector(vecBoxMaxs.x, vecBoxMins.y, vecBoxMins.z),
		Vector(vecBoxMaxs.x, vecBoxMins.y, vecBoxMaxs.z),
		Vector(vecBoxMaxs.x, vecBoxMaxs.y, vecBoxMins.z),
		Vector(vecBoxMaxs.x, vecBoxMaxs.y, vecBoxMaxs.z)
	}

	for Int = 1, #m_tblBoxBounds do
		local vecBoundOrigin = entEntity:LocalToWorld(m_tblBoxBounds[Int]):ToScreen()

		tblBox.x = math.min(tblBox.x, vecBoundOrigin.x, vecBoundaryBoxCenter.x - 2)
		tblBox.y = math.min(tblBox.y, vecBoundOrigin.y, vecBoundaryBoxCenter.y - 2)
		tblBox.w = math.max(tblBox.w, vecBoundOrigin.x, vecBoundaryBoxCenter.x + 2)
		tblBox.h = math.max(tblBox.h, vecBoundOrigin.y, vecBoundaryBoxCenter.y + 2)
	end

	tblBox.x = math.ceil(tblBox.x)
	tblBox.y = math.ceil(tblBox.y)
	tblBox.w = math.ceil(tblBox.w - tblBox.x)
	tblBox.h = math.ceil(tblBox.h - tblBox.y)

	return tblBox
end

function pS.pVisuals:PlayerShouldDraw(plyPlayer)
	if not plyPlayer:IsDormant() then
		if plyPlayer ~= pS.g_pLocalPlayer and plyPlayer:Alive() then
			-- Old code from the old libby's days :(
			--[[
				-- Check if the player is in build mode.
				if pCache.Visuals.PVPModeOnly and plyPlayer:GetNWBool("BuildMode", false) then
					return false
				end
			]]

			return true
		end
	end

	return false
end

function pS.pVisuals:PropShouldDraw(entProp)
	return not entProp:IsDormant()
end

function pS.pVisuals:PrePlayerEspDraw(plyPlayer)
	if not plyPlayer.m_flVisualAlpha then
		plyPlayer.m_flVisualAlpha = 0
	end

	-- Should we draw the player?
	local bValid = pS.pVisuals:PlayerShouldDraw(plyPlayer)

	if bValid then
		if not plyPlayer.m_flVisualAlpha ~= 1 then
			plyPlayer.m_flVisualAlpha = 1
		end
	else
		if not plyPlayer.m_flVisualAlpha ~= 0 then
			-- A simple fade effect for players who shouldn't draw.
			plyPlayer.m_flVisualAlpha = math.max(plyPlayer.m_flVisualAlpha - (1 / .2) * RealFrameTime(), 0)
		end
	end
end

function pS.pVisuals:GetPlayerEspColor(plyPlayer)
	local Ret = Color(pS.g_pDefaultColor.r, pS.g_pDefaultColor.g, pS.g_pDefaultColor.b, 255)

	if not plyPlayer then
		return Ret
	end

	if not plyPlayer.m_flVisualAlpha then
		return Ret
	end

	Ret = Color(pS.g_pDefaultColor.r, pS.g_pDefaultColor.g, pS.g_pDefaultColor.b, 255 * plyPlayer.m_flVisualAlpha)

	local Col = team.GetColor(plyPlayer:Team())
	Ret = Color(Col.r, Col.g, Col.b, Ret.a * plyPlayer.m_flVisualAlpha)

	return Ret
end

function pS.pVisuals:GetPropEspColor(entProp)
	local Col = Color(pS.g_pDefaultColor.r, pS.g_pDefaultColor.g, pS.g_pDefaultColor.b, 255);

	-- Check if entProp is valid.
	if not entProp then
		return Col
	end

	-- Check if it's an attack prop.
	if pS.pVisuals.AttackProps[entProp:GetModel()] then
		Col = Color(255, 0, 0, Col.a)
	end

	-- Check if it's either a defense prop or an attack prop being used for defense.
	if (pS.pVisuals.DefenseProps[entProp:GetModel()]) or (pS.pVisuals.AttackProps[entProp:GetModel()] and (entProp:GetVelocity():LengthSqr() < 50)) then
		Col = Color(0, 0, 255, Col.a)
	end

	-- Return the determined color.
	return Col
end

function pS.pVisuals:DrawEspBox(x, y, w, h, col)
	-- Extremely basic, but it works.
	surface.SetDrawColor(col)
	surface.DrawOutlinedRect(x, y, w, h)
end

function pS.pVisuals:DrawPropInfo()
	if pCache.Visuals.Enabled and pCache.Visuals.PropInfo then
		-- Check if pLastProp is valid.
		if pS.pMisc.pLastProp == nil or pS.pMisc.pLastProp == NULL then
			return
		end

		-- Make sure it's a prop.
		if pS.pMisc.pLastProp:GetClass() ~= 'prop_physics' then
			return
		end

		-- Check if the prop isn't dormant.
		if not pS.pVisuals:PropShouldDraw(pS.pMisc.pLastProp) then
			return
		end

		-- TODO: Optimizations.
		local vecPropCenter = pS.pMisc.pLastProp:LocalToWorld(pS.pMisc.pLastProp:OBBCenter()):ToScreen()
		local vecPropMins = pS.pMisc.pLastProp:LocalToWorld(pS.pMisc.pLastProp:OBBMins()):ToScreen()
		local Col = pS.pVisuals:GetPropEspColor(pS.pMisc.pLastProp)

		local plyClosestPlayer = pS.pVisuals:GetClosestPlayer(pS.pMisc.pLastProp, true)

		if not plyClosestPlayer then
			return
		end

		local flDistToTarget = pS.g_pLocalPlayer:GetPos():Distance(plyClosestPlayer:GetPos())
		local flDistToProp = pS.g_pLocalPlayer:GetPos():Distance(pS.pMisc.pLastProp:GetPos())

		if pS.pVisuals.AttackProps[pS.pMisc.pLastProp:GetModel()] and not (pS.pMisc.pLastProp:GetVelocity():LengthSqr() < 50) then
			draw.SimpleText(((flDistToTarget < flDistToProp) and ('FARTHER') or ('CLOSER')), 'pSilentFont', vecPropCenter.x, vecPropMins.y, Color(Col.r, Col.g, Col.b, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end
end

function pS.pVisuals:DrawEspPlayer(plyPlayer)
	-- This code is absolute shit
	local Box = pS.pVisuals:GetEspBoxBounds(plyPlayer)
	local Black = Color(0, 0, 0, 255 * plyPlayer.m_flVisualAlpha)
	local White = Color(255, 255, 255, 255 * plyPlayer.m_flVisualAlpha)
	local Col = pS.pVisuals:GetPlayerEspColor(plyPlayer)
	local vecHitboxPos = pSDK.GetHitboxPosition(plyPlayer)
	local bTarget = false
	local Mult = 1
	local nTextDrop = 0
	local Wpn = plyPlayer:GetActiveWeapon()

	if pCache.Visuals.Health then
		draw.SimpleText(plyPlayer:Health(), 'pSilentFont', math.ceil(Box.x + Box.w + 4), Box.y + nTextDrop - 5, Col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		nTextDrop = nTextDrop + 12
	end

	if pCache.Visuals.Distance then
		if plyPlayer ~= pS.g_pLocalPlayer then
			draw.SimpleText('Distance: ' .. tostring(math.Round(pS.g_pLocalPlayer:GetPos():Distance(plyPlayer:GetPos()), 2)), 'pSilentFont', math.ceil(Box.x + Box.w + 4), Box.y + nTextDrop - 5, Col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			nTextDrop = nTextDrop + 12
		end
	end

	if pCache.Visuals.HealthBar then
		local flHpFrac = math.max(math.min(plyPlayer:Health() / 100, 1), 0)
		local HsvCol = HSVToColor(90 * flHpFrac, 1, 1)
		local HpCol = Color(HsvCol.r, HsvCol.g, HsvCol.b, HsvCol.a * Mult * plyPlayer.m_flVisualAlpha)
		local BarH = math.ceil((Box.h + 4) * flHpFrac)
		local nStep = math.ceil((Box.h) / 10)

		surface.SetDrawColor(Black)
		surface.DrawOutlinedRect(Box.x - 8, Box.y - 3, 4, Box.h + 6)
		surface.SetDrawColor(HpCol)
		surface.DrawRect(Box.x - 7, Box.y - 2 + ((Box.h + 4) - BarH), 2, BarH)

		if nStep > 2 then
			surface.SetDrawColor(Black)

			for Int = 0, 9 do
				surface.DrawLine(Box.x - 8, (Box.y - 3) + Int * nStep, Box.x - 5, (Box.y - 3) + Int * nStep)
			end
		end
	end

	if pCache.Visuals.Name then
		draw.SimpleText(plyPlayer:Nick(), 'pSilentFont', Box.x - 2, Box.y - 3, Col, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	end

	if pCache.Visuals.Tracers then
		if vecHitboxPos and plyPlayer:Alive() then
			if (vecHitboxPos:ToScreen().visible and pSDK.IsVisible(pS.g_pLocalPlayer:GetShootPos(), vecHitboxPos, { plyPlayer, pS.g_pLocalPlayer })) then
				surface.SetDrawColor(Col)
				surface.DrawLine(ScrW() / 2, ScrH() / 2, vecHitboxPos:ToScreen().x, vecHitboxPos:ToScreen().y)
			end
		end
	end
end

function pS.pVisuals:DrawCrosshair()
	-- TODO: Toggle via concommand.
	surface.SetDrawColor(pS.g_pDefaultColor)

	surface.DrawLine((ScrW() / 2) - pCache.Visuals.CrosshairLength, ScrH() / 2, (ScrW() / 2) + pCache.Visuals.CrosshairLength, ScrH() / 2)
	surface.DrawLine(ScrW() / 2, (ScrH() / 2) - pCache.Visuals.CrosshairLength, ScrW() / 2, (ScrH() / 2) + pCache.Visuals.CrosshairLength)
end

function pS.pVisuals:GetClosestPlayer(entProp, bFilterLocal)
	-- Check if entProp is valid.
	if not entProp then
		return nil
	end

	-- We can't check using the NOT op because people will set this to false, so we need to specify nil.
	if bFilterLocal == nil then
		bFilterLocal = false
	end

	local tblPlayers = player.GetAll()

	-- Variables to store values to.
	local plyLastPlayer = nil
	local plyClosestPlayer = nil
	local flClosestDist = nil

	-- Iterate through every player on the server
	for Int = 1, #tblPlayers do
		-- Ignore localplayer if specified.
		if bFilterLocal and tblPlayers[Int] == pS.g_pLocalPlayer then
			continue
		end

		-- Save the current iterated player's distance to the entity position.
		local flDist = tblPlayers[Int]:GetPos():Distance(entProp:GetPos())

		-- Define flClosestDist if it isn't already.
		if not flClosestDist then
			flClosestDist = flDist
		end

		-- Define ClosestToProp if it isn't already.
		if not pS.pVisuals.ClosestToProp then
			pS.pVisuals.ClosestToProp = tblPlayers[Int]
		end

		-- Save the closest distance found.
		flClosestDist = ((flDist < flClosestDist) and flDist or flClosestDist)

		-- Store the closest player to the entity.
		if flDist == flClosestDist then
			plyClosestPlayer = tblPlayers[Int]
		end

		-- Store the last iterated player.
		plyLastPlayer = tblPlayers[Int]
	end

	-- Return the closest player.
	return plyClosestPlayer
end

function pS.pVisuals:RenderPropTracers()
	if not pS.pMisc.pLastProp or pS.pMisc.pLastProp == nil then
		return
	end

	-- Get the closest player to the last prop we held onto.
	local plyClosestPlayer = pS.pVisuals:GetClosestPlayer(pS.pMisc.pLastProp, true)

	-- Check if the player is valid.
	if not plyClosestPlayer then
		return
	end

	if plyClosestPlayer:Alive() and pS.pVisuals:PlayerShouldDraw(plyClosestPlayer) then
		local vecOrigin = pS.pMisc.pLastProp:LocalToWorld(pS.pMisc.pLastProp:OBBCenter())

		local trLinePos = util.TraceLine({
			start = vecOrigin,
			endpos = plyClosestPlayer:LocalToWorld(plyClosestPlayer:OBBCenter()),
			filter = { pS.pMisc.pLastProp, plyClosestPlayer },
			mask = MASK_SHOT
		})

		local flDist = math.Clamp(plyClosestPlayer:GetShootPos():Distance(pS.g_pLocalPlayer:GetShootPos()), 100, 2500)
		local StretchX = flDist / 200
		local StretchY = flDist / 400

		local trHeadBeam = {
			Start = vecOrigin,
			End = trLinePos.HitPos,
			Width = flDist / 40
		}

		local Col = pS.pVisuals:GetPlayerEspColor(plyClosestPlayer);

		if not trLinePos.HitWorld or trLinePos.Fraction == 1 then
			cam.Start3D()
			cam.IgnoreZ(true)
			render.SetMaterial(pS.pVisuals.BeamMat)
			render.DrawBeam(trHeadBeam.Start, trHeadBeam.End, trHeadBeam.Width, StretchX, StretchY, Color(Col.r, Col.g, Col.b, 255))
			cam.End3D()
		end
	end
end

function pS.pVisuals:DrawTrajectory()
	-- TODO: Optimization.
	if pCache.Visuals.Trajectory then
		local tblPlayers = player.GetAll()

		for Int = 1, #tblPlayers do
			if pS.pVisuals:PlayerShouldDraw(tblPlayers[Int]) then
				local Col = pS.pVisuals:GetPlayerEspColor(tblPlayers[Int])
				local vecDest = tblPlayers[Int]:GetPos()
				local vecGravity = Vector(0, 0, cvars.Number('sv_gravity', 600))

				local vecVelocity = tblPlayers[Int]:GetVelocity()
				-- local vecVelocity = Vector(0, -1200, 350) -- For testing.

				-- TODO: Move this whole operation into it's own function for organization because this is fucking messy as shit.

				-- Placeholders for values we need to set in the loop.
				local lastPoint = Vector()
				local currentPoint = Vector()

				-- The table of points that will be generated.
				local points = {}

				-- Ensure that our first value is our position.
				points[1] = vecDest

				-- Copy our destination vector to currentPoint.
				-- I have no idea why I'm doing this because without it the entire points table generates the same value for every iteration.
				vecDest:Add(vecVelocity * engine.TickInterval())
				pSDK.VectorCopy(vecDest, currentPoint);

				for j = 2, pCache.Visuals.TrajLength - 1 do
					-- Calculate our trajectory.
					vecVelocity = vecVelocity - (vecGravity * engine.TickInterval())

					-- Calculate where our current point is going to be.
					currentPoint = currentPoint + (vecVelocity * engine.TickInterval())

					-- Save our current point to our table.
					points[j] = currentPoint

					-- Store our last point. If the next index in the points table is defined then we store that instead, if not then we just store the current index.
					lastPoint = points[j + 1] and points[j + 1] or points[j]
				end

				-- Check if we're on the ground.
				if not tblPlayers[Int]:IsFlagSet(FL_ONGROUND) and tblPlayers[Int]:GetMoveType() ~= MOVETYPE_NOCLIP then
					for Int = 1, #points do
						-- We don't want to render our last point since there's nowhere for it to go.
						if Int < #points then
							-- NOTE: This is being rendered in a 3D context for optimization purposes.
							--       The reason why is because instead of making a traceline for each
							--       line drawn we can just render it in a 3D context so we can just
							--       render the z buffer along with it so it clips through walls.
							render.DrawLine(points[Int], points[Int + 1], Col, true)
						end
					end
				end
			end
		end
	end
end

function pS.pVisuals:RenderHeadBeams()
	if pCache.Visuals.HeadBeams then
		local tblPlayers = player.GetAll()

		for Int = 1, #tblPlayers do
			if tblPlayers[Int]:Alive() and pS.pVisuals:PlayerShouldDraw(tblPlayers[Int]) then
				local vecOrigin = tblPlayers[Int]:GetPos() + Vector(0, 0, 40)

				local trUp = util.TraceLine({
					start = vecOrigin,
					endpos = vecOrigin + Vector(0, 0, 16384),
					filter = { tblPlayers[Int] },
					mask = MASK_SHOT
				})

				local flDist = math.Clamp(tblPlayers[Int]:GetShootPos():Distance(pS.g_pLocalPlayer:GetShootPos()), 100, 2500)
				local flSpriteDist = tblPlayers[Int]:EyePos():Distance(trUp.HitPos)
				local StretchX = flDist / 200
				local StretchY = flDist / 400

				local trHeadBeam = {
					Start = tblPlayers[Int]:EyePos(),
					End = trUp.HitPos,
					Width = flDist / 40
				}

				local Col = pS.pVisuals:GetPlayerEspColor(tblPlayers[Int])

				if IsValid(trUp.Entity) and trUp.Entity:GetClass() == 'prop_physics' then
					Col = Color(255, 0, 0, 255)
				end

				cam.Start3D()
				cam.IgnoreZ(true)
				render.SetMaterial(pS.pVisuals.BeamMat)
				render.DrawBeam(trHeadBeam.Start, trHeadBeam.End, trHeadBeam.Width, StretchX, StretchY, Col)
				cam.End3D()
			end
		end
	end
end

function pS.pVisuals:DrawPlayerEsp()
	local tblPlayers = player.GetAll()

	for Int = 1, #tblPlayers do
		pS.pVisuals:PrePlayerEspDraw(tblPlayers[Int])

		if tblPlayers[Int].m_flVisualAlpha ~= 0 then
			pS.pVisuals:DrawEspPlayer(tblPlayers[Int])
		end
	end
end

function pS.pVisuals:RenderPlayerEsp()
	if pCache.Visuals.PlayerChams then
		local tblPlayers = player.GetAll()

		render.MaterialOverride(pS.pVisuals.ChamsMat)
		render.SuppressEngineLighting(pCache.Visuals.FlatChams)

		for Int = 1, #tblPlayers do
			if pS.pVisuals:PlayerShouldDraw(tblPlayers[Int]) and tblPlayers[Int].m_flVisualAlpha then
				local Col = pS.pVisuals:GetPlayerEspColor(tblPlayers[Int])

				render.SetColorModulation(Col.r / 255, Col.g / 255, Col.b / 255)
				render.SetBlend(127 / 255)

				tblPlayers[Int]:DrawModel()
			end
		end

		render.SuppressEngineLighting(false)
		render.MaterialOverride()
	end
end

function pS.pVisuals:RenderPropEsp()
	if pCache.Visuals.PropChams then
		-- Get a table containing every prop on the map that's not dormant.
		local tblProps = ents.FindByClass("prop_physics")

		render.MaterialOverride(pS.pVisuals.PropChamsMat)
		render.SuppressEngineLighting(pCache.Visuals.FlatChams)

		for Int = 1, #tblProps do
			if pS.pVisuals:PropShouldDraw(tblProps[Int]) then
				-- Determine the color that the ESP should use.
				local Col = pS.pVisuals:GetPropEspColor(tblProps[Int])

				tblProps[Int]:SetNoDraw(true)

				render.SetColorModulation(Col.r / 255, Col.g / 255, Col.b / 255)
				render.SetBlend(Col.a / 255)

				-- Draw a wireframe box.
				render.DrawWireframeBox(tblProps[Int]:GetPos(), tblProps[Int]:GetAngles(), tblProps[Int]:OBBMins(), tblProps[Int]:OBBMaxs(), Col, false)

				tblProps[Int]:DrawModel()

				tblProps[Int]:SetNoDraw(false)
			end
		end

		render.SuppressEngineLighting(false)
		render.MaterialOverride()

		-- I hate the fact that I have to do this.
		render.SetColorModulation(1, 1, 1)
		render.SetBlend(1)
	end
end
