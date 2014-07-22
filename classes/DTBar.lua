--[[----------------------------------------------------------------------------

 DTBar.lua

 Menu bar

    @alias meta

    @author Christophe Berbizier (cberbizier@peersuasive.com)
    @license GPLv3
    @copyright 

(c) 2014, Peersuasive Technologies

------------------------------------------------------------------------------]]

local luce, app = _G.Luce, _G.App
local log, logError = app.log, app.logError

local componentName = "DTBar"

local require, _require = require, _require
if(LUCE_LIVE_CODING)then
    print( componentName )
    _require = _require and _require or require
    local function safe_require(p)
        package.loaded[p] = nil
        if ( pcall(_require,p) ) then
            return _require(p)
        end
    end
    require = safe_require
end

local TreeViewItem = require"DTTreeViewItem"
local EC = require"EventCentral"

local resources = {
         add = luce.Image:getFromFile("./assets/settings.add.png"),
    settings = luce.Image:getFromFile("./assets/settings.settings.png"),
}

local function createDialog(size, cb)
    local confirmDialog = luce:Component("confirmBox")
    confirmDialog:setSize(size)
    local title = luce:Label("title")
    local addressLabel = luce:Label("addressLabel")
    local address = luce:TextEditor("address")
    local messageLabel = luce:Label("messageLabel")
    local message = luce:TextEditor("message")
    local ok, cancel = luce:TextButton("ok"), luce:TextButton("cancel")

    local result = false
    local self = {
        getResult = function()return result end,
    }

    title.text = "Add Friend"
    title:setColour( title.ColourIds.textColourId, luce.Colours.white )

    addressLabel.text = "Tox ID:"
    addressLabel:setColour( addressLabel.ColourIds.textColourId, luce.Colours.white )
    --addressLabel:attachToComponent(address, true)

    messageLabel.text = "Message:"
    messageLabel:setColour( messageLabel.ColourIds.textColourId, luce.Colours.white )

    ok.buttonText = "ok"
    ok:setLookAndFeel(4)
    cancel.buttonText = "cancel"
    cancel:setLookAndFeel(4)
    confirmDialog:addAndMakeVisible(title)
    confirmDialog:addAndMakeVisible(address)
    confirmDialog:addAndMakeVisible(addressLabel)
    confirmDialog:addAndMakeVisible(message)
    confirmDialog:addAndMakeVisible(messageLabel)
    confirmDialog:addAndMakeVisible(ok)
    confirmDialog:addAndMakeVisible(cancel)
    
    local backgroud = luce:Colour("black"):withAlpha(0.0)
    confirmDialog:paint(function(g)
        g:setColour(backgroud)
        g:fillAll()

        local bounds = luce:Rectangle(confirmDialog:getLocalBounds())
        title:setBounds( bounds:removeFromTop(20) )
        local abounds = bounds:removeFromTop(40)
        addressLabel:setBounds( abounds:removeFromTop( abounds.h/2 ) )
        address:setBounds( abounds )
        
        local mbounds = bounds:removeFromTop(100)
        messageLabel:setBounds( mbounds:removeFromTop( 20 ) )
        message:setBounds( mbounds )

        bounds = bounds:reduced(5):removeFromBottom(40)

        local obounds = bounds:removeFromLeft(40)
        ok:setBounds(obounds)
        ok:setSize{40,20}
        local cbounds = bounds:removeFromRight(40)
        cancel:setBounds(cbounds)
        cancel:setSize{40,20}
    end)

    ok:buttonClicked(function()
        cb{ id = address.text, msg = message.text }
    end)
    cancel:buttonClicked(function()
        cb()
    end)

    self.__self = confirmDialog.__self
    return setmetatable(self, {
        __tostring = function()return "ConfirmDialog" end,
        __self     = confirmDialog.__self,
        __index    = confirmDialog,
        __newindex = confirmDialog,
    })
end

local function new(_, name, parent)
    local name  = name or componentName
    local comp  = luce:Component(name)
    local add   = luce:ImageComponent("add")
    local settings = luce:ImageComponent("settings")
    local ec    = EC()
    local self  = {}

    add:setImage(resources.add)
    local isShowing = false
    add:mouseUp(function(m)
        if(isShowing)then return end
        local cob = nil
        local function cb(req)
            if(cob)then
                cob:dismiss()
                isShowing = false
            end
            if(req)then
                ec.broadcast("addFriend", req)
            end
        end
        local dialog = createDialog({200, 200}, cb)
        cob = luce:CallOutBox( dialog, comp:getBounds(), comp:getParentComponent() )
        cob:setLookAndFeel(4)
        isShowing = true
    end)

    settings:setImage(resources.settings)

    comp:addAndMakeVisible(add)
    comp:addAndMakeVisible(settings)
    comp:paint(function(g)
        g:setColour(luce.Colours.darkgrey)
        g:fillAll()
        local bounds = luce:Rectangle(comp:getLocalBounds())
                           :reduced(5)
                           :withTrimmedLeft(10)
                           :withTrimmedRight(10)
        local a = bounds:removeFromLeft(40)
        add:setBounds(a)
        local s = bounds:removeFromRight(40)
        settings:setBounds(s)
    end)

    comp:resized(function(...)
    end)

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
