#!/usr/bin/env luajit

--[========================================================[

DeTox, InTox, ToxIn

  +-----------------------------------------------------+
  | DeTox - Conversation with alpha@m.com         _ - x |
  +------------------++---------------------------------+
  |  o  dbdl       o ||  o o dbdl              /  ^  V  |      
  | '|` Toxing on... ||  _v_ Toxing on DeTox v0.1       |
  |  ^               ||                                 |
  +------------------++---------------------------------+
  | Online           || Me Hello !                14:35 |
  | alpha@m.com    o || alpha@m.com Yo!           14:55 |
  | smone@g.com    x ||                                 |
  |                  ||                                 |
  |                  ||                                 |
  |                  ||                                 |
  |                  ||                                 |
  |                  |+---------------------------------+
  |                  ||                            +--+ |
  +------------------++ Hello                      |  | |
  | +              o ||                            +--+ |
  +------------------++---------------------------------+

    Contacts widget          Chat widget
    (including me)          send file, audio call, video call

    show by status
     all, online
    add
    settings
     history
     show typing
     flash new messages
    context menu
     remove, edit/show info
    me
     copy ID
     set my status, mood
     edit

--]========================================================]

--[[

je vais commencer par charger la config
qui contient mon id et mon nick

--]]

local title = "Hello World!"
local app, luce = require"luce.LApplication"("app", ...)

-- TODO: create a Tox class to hold all callbacks, initialise things, etc
-- just to keep it safe from LLC reloads

local function MainWindow(params)
    -- TODO: integrate in module/reload
    -- TODO: make llive to watch deps also
    --

    local Tox
    local require, _require = require, _require
    if(LUCE_LIVE_CODING)then
        _require = _require or require
        local function safe_require(p)
            --print("loaded ?", package.loaded[p])
            package.loaded[p] = nil
            if ( pcall(_require,p) ) then
                return _require(p)
            end
        end
        require = safe_require
        -- reset callbacks
        if(_G.App.EventCentral)then
            _G.App.EventCentral = nil
        end
        if not(_G.App.Tox) then
            local Tox = _require"tox"
            _G.App.Tox = Tox
        end
    else
        Tox = require"tox"
    end

    local app, luce = app or _G.App, luce or _G.Luce
    local log, logError = app.log, app.logError

    local wsize = {800,600}
    local dw  = luce:Document(title)
    local mc  = luce:MainComponent("mc")
    mc:setSize(wsize)

    local Tox      = Tox or app.Tox
    local EC       = require"EventCentral"
    local Contacts = require"DTContacts"
    local Chat     = require"DTChat"
    local User     = require"DTUser"

    local ec = EC()
    local tox = app.tox or Tox()
    app.tox = tox

    --local contacts = require"DTContacts"("contacts")
    -- TODO: move to initialised, probably
    local contacts = Contacts("contacts")
    local user     = User("mememe")
    local chat     = nil --
    -- -----------------

    -- load config ?
    -- set my ID
    --  that's a table { name = "me", uuid = "UUID...", status = "online" }

    local data = io.open("data.json"):read("*a")
    data = require"json".decode(data)

    local config = assert(io.open("/home/distances/.config/tox/data", "rb"), "Can't load tox config")
    assert( tox:load(config:read("*a")) )

    local friends = {}
    local function cbOnFriendAdded(max)
        local friends = friends
        for i=0,max-1 do
            if not(friends[i+1]) then
                local friend = {
                    num     = i,
                    active  = true,
                    chatwin = 0,
                    online  = false,
                    status  = Tox.status.USERSTATUS_NONE,
                    key     = tox:getClientId(i),
                    name    = tox:getName(i) or "Anonymous",
                    lastOnline = tox:getLastOnline(i),
                }
                friends[i+1] = friend
            end
        end
    end
    cbOnFriendAdded(tox:countFriendlist())

    -- init frient list, that'll be data for DTContact

    local function createChat(user)
        -- TODO: add a cleanup method in chat for callbacks, if any
        --       and call it before creating new window
        chat = Chat("chat", {"moi"})
        local bounds = luce:Rectangle(mc:getLocalBounds()):withTrimmedLeft(240)
        chat:setBounds(bounds)
        mc:addAndMakeVisible(chat)
        mc:repaint()
    end
    local function itemClicked(msg)
        createChat("meme")
    end

    -- -----------------

    local black = luce:Colour(luce.Colours.black)
    app:initialised(function()
        ec.register("itemClicked", itemClicked)
        contacts:setData(friends)
    end)

    mc:paint(function(g)
        g:setColour(luce.Colours.dimgrey)
        g:fillAll()
    end)

    mc:resized(function(...)
        local bounds = luce:Rectangle(mc:getLocalBounds())
        local lbounds = bounds:removeFromLeft(240)
        local ubounds = lbounds:removeFromTop(40)
        user:setBounds(ubounds)
        contacts:setBounds(lbounds)
    end)

    mc:addAndMakeVisible(contacts)
    --mc:addAndMakeVisible(chat)
    mc:addAndMakeVisible(user)

    dw:setContentOwned(mc, true)
    dw:centreWithSize{800,600}
    dw:setVisible(true)
    return dw
end

local function control()
    tox:toxDo()
end

return app:start(MainWindow)--, control)
