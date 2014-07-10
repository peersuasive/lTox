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

local function new(_, name, parent)
    local name  = name or componentName
    local comp  = luce:Component(name)
    local add   = luce:ImageComponent("add")
    local settings = luce:ImageComponent("settings")
    local self  = {}

    add:setImage(resources.add)
    settings:setImage(resources.settings)
    print( resources.settings:isNull())

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
