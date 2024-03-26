local unpack = unpack or table.unpack

Hook = {}

Hook.FUNCTYPES = {
	BREAKPOINT = '__breakpoints',
	CALLBACK = '__callbacks',
	ONWRITE = '__onwrites',
	ONREAD = '__onreads'
}

local function _callfuncs(obj, which, ...)
	local _result = nil

	for i = 1, #obj[which], 1 do
		_result = {obj[which][i](...)}

		if _result ~= nil and #_result > 0 then
			return unpack(_result)
		end
	end
end

local function _inithook(obj)	
	local typ = type(obj)

	-- Return if already initialized
	if typ == 'table' and obj.__inithook then return obj end

	local hook = { }
	hook.__inithook = true
	hook.__breakpoints = { }
	hook.__callbacks = { }
	hook.__onreads = { }
	hook.__onwrites = { }
	hook.__orig = obj

	local _metatable = { }

	if typ == 'function' then
		_metatable['__call'] = function(obj, ...)
			_callfuncs(hook, Hook.FUNCTYPES.BREAKPOINT, ...)
			local result = hook.__orig(...)
			_callfuncs(hook, Hook.FUNCTYPES.CALLBACK, ..., result)

			return result
		end
	end

	if typ == 'table' then
		_metatable['__index'] = function (...)
			local _t, _k = ...
			_callfuncs(hook, Hook.FUNCTYPES.ONREAD, ...)
			return hook.__orig[_k]
		end

		_metatable['__newindex'] = function (...)
			local _t, _k, _v = ...
			_v = _callfuncs(hook, Hook.FUNCTYPES.ONWRITE, ...) or _v
			hook.__orig[_k] = _v
		end
	end

	setmetatable(hook, _metatable)
	
	return hook
end

local function _addfunc(obj, which, func, ephemeral)
	if func == nil then	return obj	end
	obj = _inithook(obj)

	local _f_index = #obj[which] + 1

	obj[which][_f_index] = ephemeral and
		function(...)
			local _ret = func(...)
			obj = _clearfunc(obj, which, _f_index)
			return _ret
		end or func

	return obj
end

function _clearfunc(obj, which, func_index)
	if obj == nil then return obj end
	obj[which][func_index] = nil
	return obj
end

local function ishooked(obj)
	if type(obj) == 'table' and obj.__inithook then return true end
	return false
end

function Hook.addbreakpoint(obj, func, ephemeral)
	return _addfunc(obj, Hook.FUNCTYPES.BREAKPOINT, func, ephemeral)
end

function Hook.addcallback(obj, func, ephemeral)
	return _addfunc(obj, Hook.FUNCTYPES.CALLBACK, func, ephemeral)
end

function Hook.addonread(obj, func, ephemeral)
	return _addfunc(obj, Hook.FUNCTYPES.ONREAD, func, ephemeral)
end

function Hook.addonwrite(obj, func, ephemeral)
	return _addfunc(obj, Hook.FUNCTYPES.ONWRITE, func, ephemeral)
end

function Hook.clear(obj)
	if ishooked(obj) then
		for i = 1, #Hook.FUNCTYPES, 1 do
			obj[Hook.FUNCTYPES[i]] = { }
		end
	end

	return obj.__orig
end

return Hook
