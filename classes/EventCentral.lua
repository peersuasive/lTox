--[[----------------------------------------------------------------------------

 EventCentral.lua

 A very simple (synchronous) message broadcaster

    @alias meta

    @author Christophe Berbizier (cberbizier@peersuasive.com)
    @license GPLv3
    @copyright 

(c) 2014, Peersuasive Technologies

------------------------------------------------------------------------------]]

-- TODO: when using with LLC, try to unregister first...

local function new()
    local app = _G.App
    if not(app.EventCentral)then
        app.EventCentral = {
            listeners = {}
        }
    end
    local ec = app.EventCentral.listeners
    local function broadcast(event, ...)
        for l in next, ec[event] or {} do
            l(...)
        end
    end
    local function register(event, cb)
        local l = ec[event] or {}
        l[cb] = true
        ec[event] = l
    end
    local function unregister(event, cb)
        if(ec[event])then
            ec[event][cb] = nil
        end
    end
    local self = {
        broadcast   = broadcast,
        register    = register,
        unregister  = unregister,
    }
    return setmetatable(self,{
        __index = self
    })
end
return new
