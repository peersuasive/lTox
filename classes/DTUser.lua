--[[----------------------------------------------------------------------------

 DTUser.lua

 Hold contact informations

    @alias meta

    @author Christophe Berbizier (cberbizier@peersuasive.com)
    @license GPLv3
    @copyright 

(c) 2014, Peersuasive Technologies

------------------------------------------------------------------------------]]

local luce, app = _G.Luce, _G.App
local log, logError = app.log, app.logError

local componentName = "DTUser"

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

local EC = require"EventCentral"

--[[
     name
[icon] tox client name  {status}

- componsant passif -- il peut retourner l'id et l'uuid de l'utilisateur,
  c'est tout
  -> pas de listener ici
  mais il peut envoyer les clics au parent

  TODO: ajouter un bagdge pour les nouveaux événements non lus

--]]

-- dialog box

local function createDialog(size, cb)
    local size = {100,100}
    local confirmDialog = luce:Component("confirmBox")
    confirmDialog:setSize(size)
    local message = luce:Label("message")
    local ok, cancel = luce:TextButton("ok"), luce:TextButton("cancel")

    local result = false
    local self = {
        getResult = function()return result end,
    }

    message.text = "Are you sure you want to remove this contact ?"
    ok.buttonText = "ok"
    ok:setLookAndFeel(4)
    cancel.buttonText = "cancel"
    cancel:setLookAndFeel(4)
    confirmDialog:addAndMakeVisible(message)
    confirmDialog:addAndMakeVisible(ok)
    confirmDialog:addAndMakeVisible(cancel)
    
    local backgroud = luce:Colour("black"):withAlpha(0.0)
    confirmDialog:paint(function(g)
        g:setColour(backgroud)
        g:fillAll()

        local bounds = luce:Rectangle(confirmDialog:getLocalBounds())
        local mbounds = bounds:removeFromTop(40)
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
        cb(true)
    end)
    cancel:buttonClicked(function()
        cb(false)
    end)

    self.__self = confirmDialog.__self
    return setmetatable(self, {
        __tostring = function()return "ConfirmDialog" end,
        __self     = confirmDialog.__self,
        __index    = confirmDialog,
        __newindex = confirmDialog,
    })
end

local resources = {
    status = {
           busy = luce.Image:getFromFile("./assets/status.busy.png"),
         online = luce.Image:getFromFile("./assets/status.online.png"),
        offline = luce.Image:getFromFile("./assets/status.offline.png"),
        [app.Tox.status.BUSY]   = luce.Image:getFromFile("./assets/status.busy.png"),
        [app.Tox.status.AWAY]   = luce.Image:getFromFile("./assets/status.away.png"),
        [app.Tox.status.INVALID]= luce.Image:getFromFile("./assets/status.offline.png"),
        [app.Tox.status.NONE]   = luce.Image:getFromFile("./assets/status.online.png"),
    },
    user = {
           user = luce.Image:getFromFile("./assets/contact.png"),
         remove = luce.Image:getFromFile("./assets/remove.png"),
          group = luce.Image:getFromFile("./assets/groupchat.png"),
    },
    avf = {
          audio = luce.Image:getFromFile("./assets/call.audio.png"),
          video = luce.Image:getFromFile("./assets/call.video.png"),
     attachment = luce.Image:getFromFile("./assets/attachment.png"),
    },

}

local borderDefaultColour = luce:Colour(luce.Colours.black):withAlpha(0.3)
local defaultSelectedColour = luce:Colour(luce.Colours.teal):withAlpha(0.1)
local defaultOverColour = luce:Colour(luce.Colours.yellow):withAlpha(0.5)
local defaultOverSelectedColour = luce:Colour(luce.Colours.yellow):withAlpha(0.2)
local defaultUnselectedColour = luce:Colour(luce.Colours.teal)

local function new(_, user, parent)
    local ec = EC()
    local resources = resources
    local borderDefaultColour = borderDefaultColour
    local defaultUnselectedColour, defaultSelectedColour = defaultUnselectedColour, defaultSelectedColour
    
    local name      = user.name or componentName
    local withListener = parent and true or false

    local comp      = luce:Component(name)
    local slm       = luce:StretchableLayoutManager("slm")
    local statusIcon= resources.status.offline
    local userIcon  = resources.user.user
    local status    = luce:ImageComponent("status")
    local icon      = luce:ImageComponent("icon")
    local remove    = luce:ImageComponent("remove")
    local badge     = luce:Label("badge")

    remove:setImage( resources.user.remove )

    if(withListener)then
        comp:addMouseListener(true)
    end

    local self = {
        user        = user,
        selected  = false,
        backgroud   = defaultUnselectedColour,
        borders     = {
            size = 0,
            colour = borderDefaultColour
        }
    }
    function self:setBorder(size, col)
        self.borders.size = size
        if(col)then
            self.border.colour = col
        end
    end

    function self:setBackground(col)
        defaultSelectedColour = col
        self.backgroud = col
        comp:repaint()
    end

    function self:setSelected(isNowSelected)
        self.selected = isNowSelected
        self.backgroud = isNowSelected and defaultSelectedColour or defaultUnselectedColour
    end
    function self:isSelected()
        return self.selected
    end

    local function statusChanged(friend, newStatus)
        if(friend == user.num)then
            status:setImage( resources.status[newStatus] )
            user.status = newStatus
        end
    end
    ec.register("statusChanged", statusChanged)

    -- tmp -- create a component for these
    local username = luce:Label("name")
    username.text = name
    username:setMinimumHorizontalScale( 1.0 )
    username:setJustificationType( luce.JustificationType.centredLeft )
    username:setColour( username.ColourIds.textColourId, luce.Colours.white )
    --username:setBorderSize{ 10, 0, 10, 0 }

    local message = luce:Label("message")
    message.text = self.user.message
    message:setMinimumHorizontalScale( 1.0 )
    message:setJustificationType( luce.JustificationType.centredLeft )
    message:setColour( message.ColourIds.textColourId, luce.Colours.lightgrey )
    --message:setBorderSize{ 10, 0, 10, 0 }

    status:setImage( user.status and resources.status[user.status] or statusIcon)
    icon:setImage(userIcon)

    comp:addAndMakeVisible(username)
    comp:addAndMakeVisible(message)
    comp:addAndMakeVisible(status)
    comp:addAndMakeVisible(icon)
    comp:addChildComponent(remove)
    -- slm pour les quatres éléments: icone, nom, client, statut

    if(withListener)then
        remove:mouseUp(function(mouseEvent)
            if(mouseEvent:mouseWasClicked())then
                local cob = nil
                local function cb(res)
                    result = res
                    if(cob)then
                        cob:dismiss()
                    end
                    if(res)then
                        ec.broadcast("removeFriend", self.user)
                    end
                end
                local confirm = createDialog({200,200}, cb)
                cob = luce:CallOutBox( confirm, comp:getBounds(), parent )
            end
        end)

        -- callbacks and overrided callbacks
        local itemClicked = function()end
        function self:itemClicked(func)
            if("function"==type(func))then
                itemClicked = func
            end
        end

        local itemDoubleClicked = function()end
        function self:itemDoubleClicked(func)
            if("function"==type(func))then
                itemDoubleClicked = func
            end
        end

        comp:mouseUp(function(mouseEvent)
            if(mouseEvent:mouseWasClicked())then
                if(remove.visible)then
                    remove.visible = false
                    comp:repaint()
                    return
                end
                if(mouseEvent.mods.isLeftButtonDown())then
                    itemClicked(mouseEvent)
                else
                    itemDoubleClicked(mouseEvent)
                end
            else
                if(remove.visible)then
                    remove.visible = false
                else
                    local toRight = (mouseEvent:getDistanceFromDragStartX() >= 0)
                    if(toRight)then
                        remove.visible = false
                    else
                        remove.visible = true
                    end
                end
                comp:repaint()
            end
        end)

        --[[
        comp:mouseDoubleClick(function(mouseEvent)
            if(mouseEvent.mods.isRightButtonDown())then
                itemDoubleClicked(mouseEvent)
            end
        end)
        --]]
 
        comp:mouseEnter(function(me)
            if not(self.selected) then
                self.backgroud = defaultOverColour
            else
                self.backgroud = defaultOverSelectedColour
            end
            comp:repaint()
        end)
        comp:mouseExit(function(me)
            if not(self.selected) then
                self.backgroud = defaultUnselectedColour
            else
                self.backgroud = defaultSelectedColour
            end
            comp:repaint()
        end)
    end

    comp:paint(function(g)
        g:setColour(self.backgroud)
        g:fillAll()

        if(self.borders.size > 0)then
            local b = comp:getLocalBounds()
            g:setColour(self.borders.colour)
            g:drawRect (1, 1, b[3]-1, b[4]-1, self.borders.size);
        end
        local bounds = luce:Rectangle(comp:getLocalBounds())
                            :withTrimmedLeft(5)
                            :withTrimmedRight(5)
                            :withTrimmedTop(5)
        local sbounds = bounds:removeFromRight(40)
        status:setBounds(sbounds)
        local ibounds = bounds:removeFromLeft(40)
        icon:setBounds(ibounds)

        if(remove.visible)then
            local rbounds = bounds:removeFromRight(25)
            remove:setBounds(rbounds)
        end

        username:setBounds(bounds:removeFromTop( bounds.h/2 ))
        message:setBounds(bounds)
 
        --[[ center label
        local h = 0
        local fontHeight = username:getFont():getHeight()
        if (bounds.h>fontHeight) then
            h = (bounds.h-fontHeight)/2
        end
        username:setBorderSize{ h, 0, h, 0 }
        --]]

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
