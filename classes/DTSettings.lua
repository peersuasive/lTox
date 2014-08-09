--[[----------------------------------------------------------------------------

 DTSettings.lua

 Display and set parameters

    @alias meta

    @author Christophe Berbizier (cberbizier@peersuasive.com)
    @license GPLv3
    @copyright 

(c) 2014, Peersuasive Technologies

------------------------------------------------------------------------------]]

local luce, app = _G.Luce, _G.App
local log, logError = app.log, app.logError

local componentName = "DTSettings"

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

local function new(_, users)
    local ec = EC()
    math.randomseed(os.time()) math.random() math.random() math.random()
    local name = componentName
    local comp = luce:Component(name)

    local uuid = luce:Label()
    uuid.text = "My ID:"
    uuid:setMinimumHorizontalScale( 1.0 )
    uuid:setJustificationType( luce.JustificationType.centredLeft )
    uuid:setColour( uuid.ColourIds.textColourId, luce.Colours.black )

    local tox = app.tox.tox
    local utils = app.tox.utils
    local myaddress = utils.formatAddress(tox:getAddress())

    local address = luce:Label()
    address.text = myaddress
    address:setMinimumHorizontalScale( 1.0 )
    address:setJustificationType( luce.JustificationType.centredLeft )
    address:setColour( uuid.ColourIds.textColourId, luce.Colours.black )
    address:setEditable( false, true, true )
    -- FIXME: set te as readonly, but allow esc to hideText
    --[==[
    address:createEditorComponent(function()
        local textEditor = luce:TextEditor()
        --textEditor:setReadOnly(true)
        textEditor:setEscapeAndReturnKeysConsumed(false)
        textEditor:keyPressed(function()
            return false
        end)
        --[[
        textEditor:escapePressed(function()
            print"ESC"
            address:hideEditor(true)
        end)
        --]]
        return textEditor
    end)
    --]==]
    address:labelTextChanged(function(...)
        address.text = myaddress
    end)


    --uuid:attachToComponent( address, true )

    comp:addAndMakeVisible( uuid )
    comp:addAndMakeVisible( address )

    local self = {
        pending = false,
    }

    -- show UUID
    -- set audio/video parameters
    -- create groups
    -- encrypt/don't encrypt config
    -- change NOSPAM
    -- change client name / mood
    --
    -- save / discard

    comp:paint(function(g)
        g:setColour(luce.Colours.white)
        g:fillAll()
        g:setFont(48.0)
        g:setColour( luce.Colours.red )
        g:drawText("TODO",comp:getLocalBounds(), luce.JustificationType.centred, true)

        local bounds = luce:Rectangle(comp:getLocalBounds()):withTrimmedLeft(5):withTrimmedRight(5):withTrimmedTop(5)
        local abounds = bounds:removeFromTop( 50 )
        local ubounds = abounds:removeFromLeft( 60 )
        uuid:setBounds( ubounds )
        address:setBounds( abounds )
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
