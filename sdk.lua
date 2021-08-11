pSDK = {}

pSDK.VectorCopy = function(vecSrc, vecDest)
	vecDest.x = vecSrc.x
	vecDest.y = vecSrc.y
	vecDest.z = vecSrc.z
end

pSDK.IsVisible = function(vecFrom, vecPosition, tblFilterEnts)
	if (vecPosition - vecFrom):Length() >= 56756 then -- Insanity check.
		return false -- This isn't right at all!
	end

	-- Is anything in our way?
	return util.TraceLine({
		start = vecFrom,
		endpos = vecPosition,
		mask = MASK_SHOT,
		filter = tblFilterEnts
	}).Fraction == 1
end

--============================================================================--
pSDK.HitboxBones = {
	-- Regular bones --
	['ValveBiped.Bip01_Head1'] = true,
	['ValveBiped.head'] = true,

	-- Used by zombie playermodels --
	['ValveBiped.Headcrab_Cube1'] = true,
	['ValveBiped.HC_Body_Bone'] = true,
	['ValveBiped.HC_BodyCube'] = true,
};

pSDK.UpdateHitboxData = function(plyTarget)
	for Int = 0, plyTarget:GetHitBoxCount(0) - 1 do
		local boneIndex = plyTarget:GetHitBoxBone(Int, 0)
		local boneName = plyTarget:GetBoneName(boneIndex)

		if pSDK.HitboxBones[boneName] then
			local vecHitboxMins, vecHitboxMaxs = plyTarget:GetHitBoxBounds(Int, 0)

			plyTarget.tblHitbox = {
				index = boneIndex,
				mins = vecHitboxMins,
				maxs = vecHitboxMaxs
			}

			return true
		end
	end

	return false
end

pSDK.GetHitboxPosition = function(plyTarget)
	if plyTarget.tblHitbox then
		plyTarget:InvalidateBoneCache()
		plyTarget:SetupBones()

		local boneIndex = plyTarget.tblHitbox.index
		local vecHitboxMins = plyTarget.tblHitbox.mins
		local vecHitboxMaxs = plyTarget.tblHitbox.maxs
		local vecHitboxCenter = (vecHitboxMins + vecHitboxMaxs) / 2

		-- Get the target's bone matrix.
		local boneMatrix = plyTarget:GetBoneMatrix(boneIndex)

		-- Is our bone matrix valid?
		if not boneMatrix then
			return nil
		end

		local vecHeadOrigin, angHeadAngles = boneMatrix:GetTranslation(), boneMatrix:GetAngles()

		vecHitboxCenter:Rotate(angHeadAngles)

		return (vecHeadOrigin + vecHitboxCenter)
	else
		-- Double check the player's hitbox.
		local bFoundHitbox = pSDK.UpdateHitboxData(plyTarget)

		if bFoundHitbox then
			-- Retry.
			return pSDK.GetHitboxPosition(plyTarget)
		else
			-- The target player has no valid hitbox!
			plyTarget.m_bNoHitbox = true
		end
	end
end
