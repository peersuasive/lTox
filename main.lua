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

local title = "lTox"
local luce = require"luce"
local app, luce = require"luce.LApplication"("app", ...)

-- TODO: create a Tox class to hold all callbacks, initialise things, etc
-- just to keep it safe from LLC reloads


local function MainWindow(params)
    local version = "lTox 0.1"
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
        _G.App.Tox = Tox
    end

    local app, luce = app or _G.App, luce or _G.Luce
    app:setDoubleClickTimeout(250)

    local log, logError = app.log, app.logError

    local wsize, currentSize = {240,600}, {240,600}
    local dw  = luce:Document(title)
    local mc  = luce:MainComponent("mc")
    mc:setSize(wsize)

    local chatWidth = 560

    local Tox      = Tox or app.Tox
    local EC       = require"EventCentral"
    local Contacts = require"DTContacts"
    local Chat     = require"DTChat"
    local User     = require"DTUser"
    local Utils    = require"DTUtils"
    local Bar      = require"DTBar"

    --------------------

    local ec = EC()
    local tox = app.tox and app.tox.tox or Tox()
    app.tox = app.tox or { tox = tox, utils = Utils }

    --------------------

    -- load config
    local configFile = "/home/distances/.config/tox/data.mine"
    if not(app.tox.loaded)then
        local config = assert(io.open(configFile, "rb"), "Can't load tox config")
        assert( tox:load(config:read("*a")), "FAILED: can't load config" )
        app.tox.loaded = true
        config:close()
    end

    local me = {
        num     = -1,
        active  = true,
        chatwin = false,
        online  = false,
        status  = tox:getSelfUserStatus( i ) and Tox.status.NONE or Tox.status.INVALID,
        message = tox:getSelfStatusMessage( i ) or "",
        key     = tox:getAddress(),
        name    = tox:getSelfName() or "Anonymous",
        lastOnline = Utils.formatDate(),
    }

    --------------------

    local contacts = Contacts("contacts")
    local bar      = Bar("bar")
    local user     = User( me )
    user:setBackground( luce.Colours.peru )

    --------------------

    local function save_config()
        local data = assert(tox:save(), "Can't save tox data")
        local config = io.open(configFile, "wb")
        config:write( data )
        config:close()
    end

    local friends = {}
    local function clearFriend(friendnum)
        local i = friendnum + 1
        if(friends[i].chatwin)then
            friends[i].chatwin = nil
        end
        table.remove(friends, i)
    end
    local function addFriend(friendnum, info)
        local info = info or {}
        local num, i = friendnum, friendnum+1
        if not(friends[i]) then
            local friend = {
                num     = num,
                active  = info.active or false,
                chatwin = info.chatwin or false,
                online  = info.online or false,
                status  = info.status
                            or tox:getFriendConnectionStatus( num ) and Tox.status.NONE or Tox.status.INVALID,
                --status  = tox:getUserStatus( i ),
                message = info.message or tox:getStatusMessage( num ) or "",
                key     = info.key or tox:getClientId(num),
                name    = info.name or tox:getName(i) or "Anonymous",
                lastOnline = info.lastOnline or tox:getLastOnline(i),
            }
            friends[i] = friend
        end
    end
    local function dtOnFriendAdded(max)
        local friends = friends
        for i=0,max-1 do
            if not(friends[i+1]) then
                local friend = {
                    num     = i,
                    active  = true,
                    chatwin = false,
                    online  = false,
                    status  = tox:getFriendConnectionStatus( i ) and Tox.status.NONE or Tox.status.INVALID,
                    --status  = tox:getUserStatus( i ),
                    message = tox:getStatusMessage( i ) or "",
                    key     = tox:getClientId(i),
                    name    = tox:getName(i) or Utils.formatAddress(tox:getClientId(i)) or "Anonymous",
                    lastOnline = tox:getLastOnline(i),
                }
                print("user status:", friend.status)
                friends[i+1] = friend
            end
        end
    end

    local function dtAddFriend(req)
        if not(req.id) or (req.id=="")then
            ec.broadcast("error", "Can't add friend: Missing Tox ID")
        end
        local msg = (req.msg=="") and "Please, add me !" or req.msg
        print(string.format("requesting friend with req: '%s', '%s'", req.id, msg))
        local r, e = tox:addFriend(req.id, msg)
        if(r) then 
            -- TODO: create a method to update list in one go
            addFriend(r, { name = req.id })
            --dtOnFriendAdded(tox:countFriendlist())
            contacts:setData(friends)
            save_config()
        end
        ec.broadcast( (r and "success" or "error"), (e or "Successfully added friend with id: " .. r) )
    end
    ec.register("addFriend", dtAddFriend)

    local function dtSendMessage(user, msg, who, msg_num)
        print("sending message **********************", user.num, msg)
        local msg_id = assert( tox:sendAction(user.num, msg), "Can't send message" )
        ec.broadcast("sendMsgId."..user.num, msg_num, msg_id)
    end

    local function dtRemoveFriend(friend)
        if( tox:delFriend(friend.num) )then
            print("num of friends:", tox:countFriendlist())
            clearFriend(friend.num)
            contacts:setData(friends)
            save_config()
            ec.broadcast("success", "Friend %s (%d) removed successfully", friend.name, friend.num)
        else
            ec.broadcast("error", "Failed to remove friend %s (%d)", friend.name, friend.num)
        end
    end

    local function dtError(msg, ...)
        local msg = string.format("ERROR: "..msg, ...)
        print(msg)
    end

    local function dtSuccess(msg, ...)
        local msg = string.format("INFO: "..msg, ...)
        print(msg)
    end

    local function cbReceiveMessage(friend, msg)
        print(string.format("friend %s sent a message: %s", friend, msg))
    end
    tox:callbackFriendMessage(cbReceiveMessage)

    -- called when a user connects also, but won't detect disconnections
    local function cbChangeName(friend, msg)
        print(string.format("friend %s changed its name: %s", friend, msg))
        if(friends[friend+1])then
            friends[friend+1].name = msg
            contacts:setData(friends)
        else
            print("Couldn't change friend name: not yet addedd ?")
        end
    end
    tox:callbackNameChange(cbChangeName)

    local function cbStatusChanged(friend, status)
        print(string.format("user status"))
        ec.broadcast("statusChanged", friend, status)
    end
    tox:callbackUserStatus(cbStatusChanged)

    local function cbFriendRequest(pub, msg)
        print(string.format("friend requested adding: %s", msg))
    end
    tox:callbackFriendRequest(cbFriendRequest)

    local function cbFriendMessage(friend, msg)
        print(string.format("friend message: %s (%s)", msg, friend))
        ec.broadcast("newMessage."..friend, friend, msg)
    end
    tox:callbackFriendMessage(cbFriendMessage)

    local function cbFriendAction(friend, msg)
        print(string.format("friend action"))
    end
    tox:callbackFriendAction(cbFriendAction)

    local function cbNameChange(friend, msg)
        print(string.format("name change"))
    end
    tox:callbackNameChange(cbNameChange)

    local function cbStatusMessage(friend, msg)
        print(string.format("status message"))
    end
    tox:callbackStatusMessage(cbStatusMessage)

    local function cbTypingChange(friend, msg)
        print(string.format("typing change"))
    end
    tox:callbackTypingChange(cbTypingChange)

    local function cbReadReceipt(friend, msg_id)
        print(string.format("read receipt: %s, %s", friend, msg_id))
        ec.broadcast("readReceipt."..friend, friend, msg_id)
    end
    tox:callbackReadReceipt(cbReadReceipt)

    local function cbConnectionStatus(friend, msg)
        print(string.format("connection status"))
    end
    tox:callbackConnectionStatus(cbConnectionStatus)

    local function cbGroupInvite(friend, msg)
        print(string.format("group invite"))
    end
    tox:callbackGroupInvite(cbGroupInvite)

    local function cbGroupMessage(friend, msg)
        print(string.format("group message"))
    end
    tox:callbackGroupMessage(cbGroupMessage)

    local function cbGroupAction(friend, msg)
        print(string.format("group action"))
    end
    tox:callbackGroupAction(cbGroupAction)

    local function cbGroupNamelistChange(friend, msg)
        print(string.format("namelist change"))
    end
    tox:callbackGroupNamelistChange(cbGroupNamelistChange)

    local function cbFileSendRequest(friend, msg)
        print(string.format("send request"))
    end
    tox:callbackFileSendRequest(cbFileSendRequest)

    local function cbFileControl(friend, msg)
        print(string.format("file control"))
    end
    tox:callbackFileControl(cbFileControl)

    local function cbFileData(friend, msg)
        print(string.format("file data"))
    end
    tox:callbackFileData(cbFileData)


    -- -----------------

    local active, lastWidth = nil, nil
    local function createChat(user)
        -- TODO: add a cleanup method in chat for callbacks, if any
        --       and call it before creating new window
        local chat = user.chatwin
        if not(chat)then
            print("Creating new chat window for", user.name)
            chat = Chat{ user }
            user.chatwin = chat
        else
            print("loading existing chat window...")
        end
        if(active) and not(active==chat)then
            print("changing active chat window...")
            active.visible = false
            local status = tox:getFriendConnectionStatus( user.num ) and Tox.status.NONE or Tox.status.INVALID
            if(status ~= user.status)then
                user.status = status
                cbStatusChanged(user.num, status)
            end
        end
        local w = lastWidth or (mc:getWidth()+chatWidth)
        lastWidth = lastWidth or w
        mc:setSize( w, mc:getHeight() )
        chat.visible = true
        active = chat
        local bounds = luce:Rectangle(mc:getLocalBounds()):withTrimmedLeft(240)
        chat:setBounds(bounds)
        mc:addAndMakeVisible(chat)
        mc:repaint()
    end
    local function hideChat(user)
        if(active and active.visible)then
            active.visible = false
            lastWidth = mc:getWidth()
            mc:setSize( wsize[1], mc:getHeight() )
            active = nil
        end
    end
    local function itemClicked(e, user, isNowSelected)
        print("item clicked", isNowSelected)
        if(isNowSelected)then
            createChat(user)
        else
            hideChat(user)
        end
    end
 
    local black = luce:Colour(luce.Colours.black)
    app:initialised(function()
        assert(ec.register("itemClicked", itemClicked))
        assert(ec.register("sendMessage", dtSendMessage))
        assert(ec.register("removeFriend", dtRemoveFriend))

        -- temporary, create a status bar component or send to notifications
        assert(ec.register("success", dtSuccess))
        assert(ec.register("error", dtError))

        dtOnFriendAdded(tox:countFriendlist())
        contacts:setData(friends)
    end)

    mc:paint(function(g)
        g:setColour(luce.Colours.dimgrey)
        g:fillAll()

        local bounds = luce:Rectangle(mc:getLocalBounds())
        local lbounds = bounds:removeFromLeft(240)
        local ubounds = lbounds:removeFromTop(40)
        user:setBounds(ubounds)
        local bbounds = lbounds:removeFromBottom(40)
        bar:setBounds( bbounds )
        contacts:setBounds(lbounds)
        if(active and active.visible)then
            active:setBounds(bounds)
        end
    end)

    mc:resized(function(...)
        if(active and active.visible)then
            lastWidth = mc:getWidth()
        end
    end)

    mc:addAndMakeVisible(user)
    mc:addAndMakeVisible(contacts)
    mc:addAndMakeVisible(bar)

    dw:setContentOwned(mc, true)
    dw:centreWithSize(wsize)
    dw:setVisible(true)
    return dw
end

local function control()
    if (_G.App and _G.App.tox) then
        local app = _G.App
        local utils = app.tox.utils
        if not(app.tox.init)then
            app.tox.init = utils.startDHT()
        else
            local tox = app.tox.tox
            tox:toxDo()
            if not(tox:isConnected())then app.tox.connected = false end
            if not(app.tox.connected) and (tox:isConnected())then
                app.tox.connected = true
                print("CONNECTED:", 
                    utils.formatAddress(tox:getAddress()), 
                    tox:getSelfName(), 
                    tox:getSelfStatusMessage())
            end
            --[==[
            if(app.tox.connected) then
                local ec = require"EventCentral"()
                -- check status once in a while
                app.tox.check_users = (app.tox.check_users or 0) + 1
                if(app.tox.check_users>10)then
                    for i=1,tox:countFriendlist() do
                        local r, err = tox:getFriendConnectionStatus(i-1)
                        if(r~=1)then
                            ec.broadcast("statusChanged", i-1, app.Tox.status.INVALID)
                        end
                    end
                app.tox.check_users = 0
                end
            end
            --]==]
        end
    end
end

return app:start(MainWindow, { control, 200 })
