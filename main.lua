--========================================================--

-- This table will be used for everything in the script.
pS = {}

-- Globals
pS.g_pLocalPlayer = LocalPlayer()
pS.g_pDefaultColor = Color(145, 255, 0)

if not EasyChat then
	surface.CreateFont('pSilentFont', {
		font = 'Tahoma',
		size = 12,
		weight = 700,
		antialias = false,
		outline = true
	})
else
	-- EasyChat detours surface.CreateFont() :(
	debug.getupvalues(surface.CreateFont).surface_CreateFont('pSilentFont', {
		font = 'Tahoma',
		size = 12,
		weight = 700,
		antialias = false,
		outline = true
	})
end

--========================================================--

-- A list of all the source files, sorted by load order.
local tblFiles = {
	'sdk.lua',
	'features/features.lua',
	'features/visuals.lua',
	'features/misc.lua',
	'hooks.lua',
}

-- Include all of our files in order.
for _, File in pairs(tblFiles) do
	include('KuteHook-Gmod-main/' .. File)
	MsgC(pS.g_pDefaultColor, string.format('File "%s" loaded.\n', File))
end

-- initialize the cheat.
include('KuteHook-Gmod-main/init.lua')
