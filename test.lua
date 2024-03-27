local Hook = require "hook"

local f = function(arg)
    return arg
end

f = Hook.addbreakpoint(f, function(arg)
    print('breakpoint')
    print(arg)
    return 456
end)

f = Hook.addcallback(f, function(arg)
    print('callback')
    print(arg)
    return 777
end)

a = f('test')

print(a)

print("==================")

local b = { }
b[1] = "abc"
b[2] = "def"
b[3] = "xyz"

local x = function(...)
    print('onread')
    local _t, _k = ...
    --return 2
end

local y = function(...)
    local _t, _k, _v = ...
    return 3, "testing"
end

b = Hook.addonwrite(b, y)
b = Hook.addonread(b, x)

b[1] = "asdf"
print(b[1])
print(b[2])
print(b[3])