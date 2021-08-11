-- Play a sound on script init.
surface.PlaySound('buttons/bell1.wav')

-- Enable Multi-Core.
pS.g_pLocalPlayer:ConCommand('gmod_mcore_test 1; mat_queue_mode -1; cl_threaded_bone_setup 1')

-- Propkill settings.
pS.g_pLocalPlayer:ConCommand('cl_interp_all 0; cl_cmdrate 1000; cl_updaterate 1000; cl_interp 0; cl_interp_ratio 0; cl_drawspawneffect 0; rate 750000')

chat.AddText(pS.g_pDefaultColor, '[KuteHook]', color_white, ' KuteHook v2.3 Public Edition loaded.')
