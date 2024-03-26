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