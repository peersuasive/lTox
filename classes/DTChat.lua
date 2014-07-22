--[[----------------------------------------------------------------------------

 DTChatBox.lua

 Display the chat box

    @alias meta

    @author Christophe Berbizier (cberbizier@peersuasive.com)
    @license GPLv3
    @copyright 

(c) 2014, Peersuasive Technologies

------------------------------------------------------------------------------]]

local luce, app = _G.Luce, _G.App
local log, logError = app.log, app.logError

local componentName = "DTChatBox"

local require, _require = require, _require
if(LUCE_LIVE_CODING)then
    print(componentName)
    _require = _require and _require or require
    local function safe_require(p)
        package.loaded[p] = nil
        if ( pcall(_require,p) ) then
            return _require(p)
        end
    end
    require = safe_require
end

local EC = require"EventCentral"

-- TODO: 
--  save history (using user's uuid)
--
--

local resources = {
    status = {
           busy = luce.Image:getFromFile("./assets/status.busy.png"),
         online = luce.Image:getFromFile("./assets/status.online.png"),
        offline = luce.Image:getFromFile("./assets/status.offline.png"),
    },
    user = {
           user = luce.Image:getFromFile("./assets/contact.png"),
          group = luce.Image:getFromFile("./assets/groupchat.png"),
    },
    avf = {
          audio = luce.Image:getFromFile("./assets/call.audio.png"),
          video = luce.Image:getFromFile("./assets/call.video.png"),
     attachment = luce.Image:getFromFile("./assets/attachment.png"),
    },

}

local function new(_, users)
    local ec = EC()
    math.randomseed(os.time()) math.random() math.random() math.random()
    local myuuid = math.random(1,10000)
    local resources = resources
    local users     = users
    local name      = componentName
    local comp      = luce:Component(name)
    local topBar    = luce:Component("top")
    local contact   = luce:Label("contact")
    local attach    = luce:ImageButton("attach")
    local attachIcon= resources.avf.attachment
    local av        = luce:ImageButton("av")
    local avIcon    = resources.avf.audio
    -- TODO: create an object with two columns for hbox: owner | message
    local historyBox = luce:ListBox("history")
    local inputBox  = luce:TextEditor("input")
    local send      = luce:TextButton("send")

    local pendingMsg, pendingMsgId = {}, {}

    local self = {
        contacts = users,
        messages = {}
    }
    
    function self:setContactList( contacts )
        -- do something...
    end

    -- méthode pour afficher les messages reçus
    -- événement NewMessage + user id
    
    local function showMessage(friend, msg, update)
        -- friend name == -1 -> me
        print(string.format("new message from %s: %s", friend, msg))
        local name = "[ukn]"
        if(friend<0)then
            name = "me"
        else
            for _, f in next, users do
                if(f.num==friend)then
                    name = f.name
                    break;
                end
            end
        end
        print("friend name: " .. name)
        local i = update or #self.messages+1
        self.messages[i] = string.format("[%s] %s", name, msg)
        historyBox:updateContent()
        historyBox:repaint()
    end
    -- TODO: add this to setContactList also
    for _,user in next, users do
        print("register for new message: " .. user.num)
        assert(ec.register("newMessage.".. user.num , showMessage))
    end

    local pending = "sending..."
    local function pendingSend(user, msg)
        print("sending to user...", user.name)
        showMessage( -1, pending )
        local msg_num = #self.messages
        pendingMsg[msg_num] = msg
        assert( ec.broadcast("sendMessage", user, msg, myuuid, msg_num ) )
    end

    local function messageReceived(friend, msg_id)
        if(pendingMsgId[msg_id])then
            local msg_num = pendingMsgId[msg_id]
            local msg = pendingMsg[msg_num]
            showMessage( -1, msg, msg_num )
            pendingMsgId[msg_id] = nil
            pendingMsg[msg_num] = nil
        end
    end
    for _, user in next, users do
        assert(ec.register("readReceipt."..user.num, messageReceived))
    end
    
    local function recvMsgId(msg_num, msg_id)
        pendingMsgId[msg_id] = msg_num
    end
    for _,user in next, users do
        assert(ec.register("sendMsgId."..user.num, recvMsgId))
    end

    local function sendMessage(msg)
        if(app.tox)then
            for _,user in next, self.contacts do
                if(app.tox.tox:getFriendConnectionStatus(user.num))then
                    pendingSend(user, msg)
                    return true
                else
                    print("User's not connected")
                end
            end
        end
        return false
    end

    inputBox.multiLine = true
    inputBox.returnKeyStartsNewLine = false
    inputBox.popupMenuEnabled = true

    send.buttonText = "[send]"
    send:setLookAndFeel(4)
    send:buttonClicked(function()
        if(sendMessage(inputBox.text))then
            inputBox.text = ""
        end
    end)

    historyBox.popupMenuEnabled = true
    historyBox:setColour( historyBox.ColourIds.backgroundColourId, "white" )
    historyBox:setColour( historyBox.ColourIds.outlineColourId, "black" )
    historyBox:getNumRows(function()
        return #self.messages
    end)
    local selectColour = luce:Colour(luce.Colours.yellow):withAlpha(0.2)
    historyBox:paintListBoxItem(function(rowNumber, g, width, height, rowIsSelected)
        if (rowIsSelected) then
            g:fillAll ( selectColour )
        end

        g:setColour (luce.Colours.black)
        g:setFont (height * 0.7)
    
        local text = self.messages[rowNumber+1] or "<empty>"
        g:drawText ( text , 5, 0, width, height, luce.JustificationType.left, true );
    end)

    contact.text = self.contacts and self.contacts[1].name or "<noone>"
    contact:setMinimumHorizontalScale( 1.0 )
    contact:setJustificationType( luce.JustificationType.left )
    contact:setEditable( false, false, true )
    contact:setColour( contact.ColourIds.backgroundColourId, "darkslategrey" )

    av:setLookAndFeel(4)
    av:setImages(true, true, true, 
                        avIcon, 1.0, luce:Colour(luce.Colours.black):withAlpha(1.0),
                        avIcon, 1.0, luce:Colour(luce.Colours.blue):withAlpha(1.0),
                        avIcon, 1.0, luce:Colour(luce.Colours.red):withAlpha(1.0),
                        0.0)

    attach:setLookAndFeel(4)
    attach:setImages(true, true, true, 
                        attachIcon, 1.0, luce:Colour(luce.Colours.black):withAlpha(1.0),
                        attachIcon, 1.0, luce:Colour(luce.Colours.blue):withAlpha(1.0),
                        attachIcon, 1.0, luce:Colour(luce.Colours.red):withAlpha(1.0),
                        0.0)

    topBar:setSize{1,1}
    topBar:addAndMakeVisible( contact )
    topBar:addAndMakeVisible( av )
    topBar:addAndMakeVisible( attach )
    topBar:resized(function(g)
        local bounds = luce:Rectangle(topBar:getLocalBounds()):withTrimmedBottom(5)
        local bbounds = bounds:removeFromRight(100):withTrimmedRight(2):withTrimmedLeft(2)
        av:setBounds( bbounds:removeFromLeft(44) )
        attach:setBounds(bbounds:withTrimmedLeft(4))
        contact:setBounds(bounds)
    end)

    comp:paint(function(g)
        g:setColour(luce.Colours.white)
        g:fillAll()
    end)
    comp:resized(function(...)
        local bounds = luce:Rectangle(comp:getLocalBounds()):withTrimmedLeft(5):withTrimmedRight(5):withTrimmedTop(5)
        local cbounds = bounds:removeFromTop(40)
        topBar:setBounds( cbounds )
        local ibounds = bounds:removeFromBottom(40)
        local sbounds = ibounds:removeFromRight(60)
        send:setBounds(sbounds)
        inputBox:setBounds(ibounds)
        historyBox:setBounds(bounds:withTrimmedBottom(5))
    end)

    comp:addAndMakeVisible(topBar)
    comp:addAndMakeVisible(historyBox)
    comp:addAndMakeVisible(inputBox)
    comp:addAndMakeVisible(send)
    self.__self = comp.__self
    return setmetatable(self, {
        __tostring = function()return name end,
        __self     = comp.__self,
        __index    = comp,
        __newindex = comp,
    })
end

return setmetatable({}, {
    __tostring = function()return componentName end,
    __call = new
})
