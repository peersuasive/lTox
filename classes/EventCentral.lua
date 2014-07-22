--[[----------------------------------------------------------------------------

 EventCentral.lua

 A very simple (synchronous) message broadcaster

    TODO: see https://github.com/Salmito/leda for a possible implementation
              or adapt with gadokai

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
        if not ec[event] then return nil, "Event not registered" end
        for l in next, ec[event] or {} do
            l(...)
        end
        return true
    end
    local function register(event, cb)
        if not("function"==type(cb))then return nil, "Callback not found or not a function" end
        local l = ec[event] or {}
        -- debug
        if(l[cb])then print "WARNING: already registered" end
        l[cb] = true
        ec[event] = l
        return true
    end
    local function unregister(event, cb)
        if(ec[event])then
            ec[event][cb] = nil
        end
    end

    local function isRegistered(event)
        return ec[event] and true or false
    end

    -- DEBUG
    local function dump()
        require"pl.pretty".dump( ec )
    end
    local function clear()
        app.EventCentral.listeners = {}
    end
    local self = {
        broadcast   = broadcast,
        register    = register,
        unregister  = unregister,
        isRegistered = isRegistered,
        -- DEBUG
        dump        = dump,
        clear       = clear,
    }
    return setmetatable(self,{
        __index = self
    })
end
return new
