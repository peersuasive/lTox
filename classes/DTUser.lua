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

--[[
     name
[icon] tox client name  {status}

- componsant passif -- il peut retourner l'id et l'uuid de l'utilisateur,
  c'est tout
  -> pas de listener ici
  mais il peut envoyer les clics au parent

  TODO: ajouter un bagdge pour les nouveaux événements non lus

--]]

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

local borderDefaultColour = luce:Colour(luce.Colours.black):withAlpha(0.3)
local defaultSelectedColour = luce:Colour(luce.Colours.teal):withAlpha(0.1)
local defaultOverColour = luce:Colour(luce.Colours.yellow):withAlpha(0.5)
local defaultUnselectedColour = luce:Colour(luce.Colours.teal)

local function new(_, name, withListener)
    local resources = resources
    local borderDefaultColour = borderDefaultColour
    local defaultUnselectedColour, defaultSelectedColour = defaultUnselectedColour, defaultSelectedColour
    
    local name   = name or componentName
    local withListener = withListener

    local comp   = luce:Component(name)
    local slm    = luce:StretchableLayoutManager("slm")
    local statusIcon = resources.status.online
    local userIcon   = resources.user.user
    local status = luce:ImageComponent("status")
    local icon   = luce:ImageComponent("icon")
    if(withListener)then
        comp:addMouseListener(true)
    end

    local self = {
        isSelected = false,
        backgroud = defaultUnselectedColour,
        borders = {
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

    function self:setSelected(isSelected)
        self.isSelected = isSelected
        self.backgroud = isSelected and defaultSelectedColour or defaultUnselectedColour
    end

    comp:mouseEnter(function(me)
        if not(self.isSelected) then
            self.backgroud = defaultOverColour
            comp:repaint()
        end
    end)
    comp:mouseExit(function(me)
        if not(self.isSelected) then
            self.backgroud = defaultUnselectedColour
            comp:repaint()
        end
    end)

    -- tmp
    local label  = luce:Label("tmp")
    label.text = name
    label:setMinimumHorizontalScale( 1.0 )
    label:setJustificationType( luce.JustificationType.centredLeft )

    label:setBorderSize{ 10, 0, 10, 0 }

    status:setImage(statusIcon)
    icon:setImage(userIcon)

    comp:addAndMakeVisible(label)
    comp:addAndMakeVisible(status)
    comp:addAndMakeVisible(icon)
    -- slm pour les quatres éléments: icone, nom, client, statut

    -- callbacks and overrided callbacks
    local itemClicked = function()end
    function self:itemClicked(func)
        if("function"==type(func))then
            itemClicked = func
        end
    end
    comp:mouseDown(function(mouseEvent)
        itemClicked(mouseEvent)
    end)

    local itemDoubleClicked = function()end
    function self:itemDoubleClicked(func)
        if("function"==type(func))then
            itemDoubleClicked = func
        end
    end
    comp:mouseDoubleClick(function(mouseEvent)
        itemDoubleClicked(mouseEvent)
    end)

    comp:paint(function(g)
        g:setColour(self.backgroud)
        g:fillAll()
        if(self.borders.size > 0)then
            local b = comp:getLocalBounds()
            g:setColour(self.borders.colour)
            g:drawRect (1, 1, b[3]-1, b[4]-1, self.borders.size);
        end
    end)

    comp:resized(function(...)
        local bounds = luce:Rectangle(comp:getLocalBounds())
                            :withTrimmedLeft(5)
                            :withTrimmedRight(5)
                            :withTrimmedTop(5)
        local sbounds = bounds:removeFromRight(40)
        status:setBounds(sbounds)
        local ibounds = bounds:removeFromLeft(40)
        icon:setBounds(ibounds)
        label:setBounds(bounds)
    
        local h = 0
        local fontHeight = label:getFont():getHeight()
        if (bounds.h>fontHeight) then
            h = (bounds.h-fontHeight)/2
        end
        label:setBorderSize{ h, 0, h, 0 }
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
