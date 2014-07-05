--[[----------------------------------------------------------------------------

 DTContacts.lua

 Show contacts list

    @alias meta

    @author Christophe Berbizier (cberbizier@peersuasive.com)
    @license GPLv3
    @copyright 

(c) 2014, Peersuasive Technologies

------------------------------------------------------------------------------]]

local luce, app = _G.Luce, _G.App
local log, logError = app.log, app.logError

local componentName = "DTContacts"

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


--[[

j'ai une première liste, ou un widget à définir,
qui contient mon nick, mon état et un menu contextuel
pour éditer mes infos, ie mon nick et peut-être mon nospam

j'ai une liste de tous mes contacts,
que je peux filtrer selon leur statut,
ou par nom
j'ai un menu contextuel par utilisateur
pour afficher leurs info, changer leur nick (possible ?)

en bas, j'ai une barre avec des icones
pour ajouter des utilisateurs
ou faire les réglages de l'appli

lorsque je veux démarrer un chat, j'envoie un événement
qui sera capté par un listener
dans l'idéal, le widget de chat,
sinon, la fenêtre principale, qui transmettra

le menu sur chaque contact permet d'envoyer un invitation
pour un group chat

+---------+
|me
+---------+
|contact
|contact
|...
+---------+
|+ ()
+---------+
--]]

local TreeViewItem = require"DTTreeViewItem"
local EC = require"EventCentral"

-- TODO: create components for bar and me

local function new(_, name, myId, parent)
    local ec = EC()
    local name = name or componentName
    local comp = luce:Component(name)
    local tree = luce:TreeView("TreeView")
    local bar  = luce:Component("bar")

    local myId = myId or "<me>"
    local me   = luce:Label(myId)

    tree:setLookAndFeel(4)
    tree:setColour( tree.ColourIds.backgroundColourId, "dimgrey" )
    tree.openCloseButtonsVisible = false
    tree.multiSelectEnabled = true
    tree.rootItemVisible = false
    tree.defaultOpenness = false

    me.text = myId
    me:setMinimumHorizontalScale( 1.0 )
    me:setJustificationType( luce.JustificationType.left )
    me:setEditable( false, false, true )
    me:setColour( me.ColourIds.backgroundColourId, "darkslategrey" )

    bar:paint(function(g)
        g:setColour( luce.Colours.darkslategrey )
        g:fillAll()
    end)
    local self = {
    }

    function self:setData(data)
        tree:setRootItem( TreeViewItem(data) )
    end

    comp:addAndMakeVisible(tree)
    comp:addAndMakeVisible(me)
    comp:addAndMakeVisible(bar)
    comp:paint(function(g)
        g:setColour(luce.Colours.darkgrey)
        g:fillAll()
    end)
    comp:resized(function(...)
        local bounds = luce:Rectangle(comp:getLocalBounds()):withTrimmedLeft(5):withTrimmedRight(5):withTrimmedTop(5)
        local mbounds = bounds:removeFromTop(40)
        me:setBounds(mbounds)
        local bbounds = bounds:removeFromBottom(40)
        bar:setBounds(bbounds)
        local lbounds = bounds:withTrimmedTop(5):withTrimmedBottom(5)
        tree:setBounds( lbounds )
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
