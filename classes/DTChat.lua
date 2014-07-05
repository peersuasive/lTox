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

--[[

j'ai un widget avec
j'ai mon statut, mon mood
un bouton pour envoyer un fichier, passer un call ou démarrer une video conf
un bouton pour ajouter des contacts au chat en cours, si c'est possible avec Tox

la zone principale avec l'historique des chats

la zone de saisie avec le bouton pour envoyer

chaque envoi envoi un événement qui sera capté par la fenêtre principale
pour activer les routines qui vont bien

je reçois la liste des intervenants au démarrage
et je souscris à un événement qui me signale l'arrivée de nouveaux
intervenants, pour le group chat
pas sûr que ce dernier point ne soit vraiment nécessaire


+-------------------- top bar -> label(s) with contact(s) + buttons -> holding component
| contact or group [a/v] [attachment]
+-------------------- history
|
|
|
| ...
+---------------+--------+ input box + send button
|               | [sent]
+---------------+--------+

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

local function new(_, name)
    local resources = resources
    local name      = name or componentName
    local comp      = luce:Component(name)
    local topBar    = luce:Component("top")
    local contact   = luce:Label("contact")
    local attach    = luce:ImageButton("attach")
    local attachIcon= resources.avf.attachment
    local av        = luce:ImageButton("av")
    local avIcon    = resources.avf.audio
    local historyBox = luce:ListBox("history")
    local inputBox  = luce:TextEditor("input")
    local send      = luce:TextButton("send")

    local self = {
        contacts = {},
        messages = {}
    }
    
    function self:setContactList( contacts )
        -- do something...
    end

    local function sendMessage(msg)
        print("send message")
        self.messages[#self.messages+1] = msg
        historyBox:updateContent()
        historyBox:repaint()
    end

    inputBox.multiLine = true
    inputBox.returnKeyStartsNewLine = false
    inputBox.popupMenuEnabled = true

    send.buttonText = "[send]"
    send:setLookAndFeel(4)
    send:buttonClicked(function()
        sendMessage(inputBox.text)
        inputBox.text = ""
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

    contact.text = self.contacts and self.contacts[1] or "<noone>"
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
