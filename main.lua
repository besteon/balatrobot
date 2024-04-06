--- STEAMODDED HEADER
--- MOD_NAME: Balatrobot
--- MOD_ID: Balatrobot-v0.2
--- MOD_AUTHOR: [Besteon]
--- MOD_DESCRIPTION: A botting API for Balatro

function SMODS.INIT.BALATROBOT()
	mw = SMODS.findModByID("Balatrobot-v0.2")

	assert(load(NFS.read(mw.path .. "list.lua")))()
	assert(load(NFS.read(mw.path .. "hook.lua")))()
	assert(load(NFS.read(mw.path .. "bot.lua")))()
	assert(load(NFS.read(mw.path .. "middleware.lua")))()
	assert(load(NFS.read(mw.path .. "botlogger.lua")))()

	sendDebugMessage("Balatrobot v0.2 loaded")

	Middleware.hookbalatro()

	Botlogger.path = mw.path
	Botlogger.inithooks()
end
