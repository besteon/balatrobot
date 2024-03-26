local unpack = unpack or table.unpack

local Hook = {}

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

	local f = nil

	if t == 'function' then
		f = { }
	
		f.__breakpoints = {  }
		f.__callbacks = { }

		f.__func = obj
		
		setmetatable(f, {
			__call = function(obj, ...)
				_callfuncs(f, Hook.FUNCTYPES.BREAKPOINT, ...)
				local result = f.__func(...)
				_callfuncs(f, Hook.FUNCTYPES.CALLBACK, ..., result)

				return result
			end
		})
	elseif t == 'table' then
		f = { }
		f.__orig = obj
		f.__func = obj

		f.__breakpoints = { }
		f.__callbacks = { }
		f.__onreads = { }
		f.__onwrites = { }

		setmetatable(f, {
			__call = function(obj, ...)
				_callfuncs(f, Hook.FUNCTYPES.BREAKPOINT, ...)
				local result = f.__func(...)
				_callfuncs(f, Hook.FUNCTYPES.CALLBACK, ..., result)

				return result
			end,

			__index = function (...)
				local t, k = ...
				--print("*access to element " .. tostring(k))
				_callfuncs(f, Hook.FUNCTYPES.ONREAD, ...)
				return f.__orig[k]   -- access the original table
			end,
			
			__newindex = function (...)
				local t, k, v = ...
				--print("*update of element " .. tostring(k) .." to " .. tostring(v))
				_nv = _callfuncs(f, Hook.FUNCTYPES.ONWRITE, ...)
				if _nv ~= nil then
					v = _nv
				end
				f.__orig[k] = v   -- update original table
			end
		})
	end
	
	return f
end

local function _addfunc(obj, which, func)
	if func == nil then
		return obj
	end
	obj = _inithook(obj)
	obj[which][#obj[which] + 1] = func
	return obj
end

local function ishooked(obj)
	for i = 1, #Hook.FUNCTYPES, 1 do
		if (type(obj[Hook.FUNCTYPES[i]])) == 'table' then
			return true
		end
	end

	return false
end


function Hook.addbreakpoint(obj, func)
	return _addfunc(obj, Hook.FUNCTYPES.BREAKPOINT, func)
end

function Hook.addcallback(obj, func)
	return _addfunc(obj, Hook.FUNCTYPES.CALLBACK, func)
end

function Hook.addonread(obj, func)
	return _addfunc(obj, Hook.FUNCTYPES.ONREAD, func)
end

function Hook.addonwrite(obj, func)
	return _addfunc(obj, Hook.FUNCTYPES.ONWRITE, func)
end

function Hook.clear(obj)
	if ishooked(obj) then
		for i = 1, #Hook.FUNCTYPES, 1 do
			obj[Hook.FUNCTYPES[i]] = { }
		end
	end

	if type(obj) == 'function' then
		return obj.__func
	end

	if type(obj) == 'table' then
		return obj.__orig
	end
	
	return obj
end

return Hook
