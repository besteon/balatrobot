local Hook = require "hook"

function testfunc(...)
    print('hello')
end

local a = 123
local b = 456

local f = function() print("f") end
local testtable = {}

f = Hook.addcallback(f, testfunc, true)
f = Hook.addbreakpoint(f, function()
    print('break')
end)

f()
f()

f = Hook.clear(f)

f()
print(type(f))

print("=====================")

local c = 12345

local X = { }

X.__orig = c

local _metatable = {
    __eq = function (a, b)
        print('in eq')
        if type(a) == 'table' then return a.__orig == b
        else return b.__orig == a end
    end
}

setmetatable(X, _metatable)

print({12345} == X)