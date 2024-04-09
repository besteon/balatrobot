--- STEAMODDED HEADER
--- MOD_NAME: Balatrobot
--- MOD_ID: Balatrobot-v0.3
--- MOD_AUTHOR: [Besteon]
--- MOD_DESCRIPTION: A botting API for Balatro

function SMODS.INIT.BALATROBOT()
	mw = SMODS.findModByID("Balatrobot-v0.3")

	-- External libraries
	assert(load(NFS.read(mw.path .. "lib/list.lua")))()
	assert(load(NFS.read(mw.path .. "lib/hook.lua")))()
	assert(load(NFS.read(mw.path .. "lib/bitser.lua")))()
	assert(load(NFS.read(mw.path .. "lib/sock.lua")))()

	-- Mod specific files
	assert(load(NFS.read(mw.path .. "src/utils.lua")))()
	assert(load(NFS.read(mw.path .. "src/bot.lua")))()
	assert(load(NFS.read(mw.path .. "src/middleware.lua")))()
	assert(load(NFS.read(mw.path .. "src/botlogger.lua")))()
	assert(load(NFS.read(mw.path .. "src/api.lua")))()

	sendDebugMessage("Balatrobot v0.3 loaded")

	Middleware.hookbalatro()

	Botlogger.path = mw.path
	Botlogger.init()
	BalatrobotAPI.init()
end
