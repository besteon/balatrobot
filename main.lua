--- STEAMODDED HEADER
--- MOD_NAME: Balatrobot
--- MOD_ID: Balatrobot-v0.1
--- MOD_AUTHOR: [Besteon]
--- MOD_DESCRIPTION: A botting API for Balatro

function SMODS.INIT.BALATROBOT()
	mw = SMODS.findModByID("Balatrobot-v0.1")

	assert(load(love.filesystem.read(mw.path .. "hook.lua")))()
	assert(load(love.filesystem.read(mw.path .. "bot.lua")))()
	assert(load(love.filesystem.read(mw.path .. "middleware.lua")))()

	sendDebugMessage("Balatrobot v0.1 loaded")

	Middleware.hookbalatro()
end
