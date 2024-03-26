local unpack = unpack or table.unpack

Hook = {}

Hook.FUNCTYPES = {
	BREAKPOINT = '__breakpoints',
	CALLBACK = '__callbacks',
	ONWRITE = '__onwrites',
	ONREAD = '__onreads'
}

local function _callfuncs(obj, which, ...)
	local result = nil

	for i = 1, #obj[which], 1 do
		result = {obj[which][i](...)}

		if result ~= nil and #result > 0 then
			return unpack(result)
		end
	end
end

local function _inithook(obj)	
	local t = type(obj)
	if t == 'table' and obj.__inithook then return obj end

	local f = { }
	f.__inithook = true
	f.__breakpoints = { }
	f.__callbacks = { }
	f.__onreads = { }
	f.__onwrites = { }
	f.__orig = obj

	local _metatable = { }

	if t == 'function' then
		_metatable['__call'] = function(obj, ...)
			_callfuncs(f, Hook.FUNCTYPES.BREAKPOINT, ...)
			local result = f.__orig(...)
			_callfuncs(f, Hook.FUNCTYPES.CALLBACK, ..., result)

			return result
		end
	end

	if t == 'table' then
		_metatable['__index'] = function (...)
			local t, k = ...
			--print("*access to element " .. tostring(k))
			_callfuncs(f, Hook.FUNCTYPES.ONREAD, ...)
			return f.__orig[k]   -- access the original table
		end

		_metatable['__newindex'] = function (...)
			local t, k, v = ...
			--print("*update of element " .. tostring(k) .." to " .. tostring(v))
			_nv = _callfuncs(f, Hook.FUNCTYPES.ONWRITE, ...)
			if _nv ~= nil then
				v = _nv
			end
			f.__orig[k] = v   -- update original table
		end
	end

	setmetatable(f, _metatable)
	
	return f
end

local function _addfunc(obj, which, func, ephemeral)
	if func == nil then
		return obj
	end
	obj = _inithook(obj)

	local _f_index = #obj[which]+1
	local f = nil
	if ephemeral then
		f = function(...)
			local _ret = func(...)
			-- TODO pass f to this someone (the modified func)
			obj = _clearfunc(obj, which, _f_index)
			return _ret
		end
	else
		f = func
	end

	obj[which][_f_index] = f
	return obj
end

function _clearfunc(obj, which, func_index)
	if obj == nil then
		return obj
	end
	
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
