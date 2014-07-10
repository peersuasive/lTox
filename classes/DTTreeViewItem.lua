--[[----------------------------------------------------------------------------

 DTTreeViewItem.lua

 TreeView Instanciation

    @alias meta

    @author Christophe Berbizier (cberbizier@peersuasive.com)
    @license GPLv3
    @copyright 

(c) 2014, Peersuasive Technologies

------------------------------------------------------------------------------]]

local luce, app = _G.Luce, _G.App
local log, logError = app.log, app.logError

local componentName = "DTTreeViewItem"

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

local ROOT = "ROOT"

local User = require"DTUser"
local EC = require"EventCentral"

-- Item class
local function Item(id, val, parent)
    local id    = id and tostring(id) or "<root>"
    local val   = val and tostring(val)
    local self = {}
    local parent = parent or { itemClicked = function()end }
    local slm   = luce:StretchableLayoutManager("item_slm")
    local comp  = luce:Component("container")
    local field = luce:Label(id)

    comp:addMouseListener(true)

    field.text = id..(val and " :" or "")
    field:setMinimumHorizontalScale( 1.0 )

    if(val)then
        field:setJustificationType( luce.JustificationType.centredRight )
    else
        field:setJustificationType( luce.JustificationType.centredLeft )
    end
    comp:addAndMakeVisible( field )
    local itemChanged_cb = nil
    function self:itemChanged(func)
        itemChanged_cb = func
    end

    local value = nil
    local field_w = field:getFont():getStringWidth( id )
    if not(val) then
        slm:setItemLayout( 0, { -0.5, -1.0, field_w } )
        -- TODO: don't edit with clicks, set a popup menu instead
        field:setEditable( false, false, true )
        field:labelTextChanged(function(...)
            if (field.text ~= id) then
                if("function"==type(itemChanged_cb))then
                    itemChanged_cb(field.text)
                end
            end
        end)
    else
        value = luce:Label(val)
        value.text = val
        value:setMinimumHorizontalScale(1.0);
        value:setJustificationType( luce.JustificationType.centredLeft );
        slm:setItemLayout( 0, { 80, field_w, field_w } )
        value:setEditable( false, true, true );
        comp:addAndMakeVisible( value );
        value:labelTextChanged(function(...)
            if (value.text ~= val) then
                if("function"==type(itemChanged_cb))then
                    itemChanged_cb(value.text)
                end
            end
        end)
        local value_w = value:getFont():getStringWidth( val or "<no value>" );
        slm:setItemLayout( 1, { 60, value_w, value_w } );
    end

    function self:setTooltip(b)
        if(value)then
            if(b)then
                value:setTooltip(val)
            else
                value:setTooltip()
            end
        end
    end

    comp:mouseDown(function(mouseEvent)
        parent:itemClicked(mouseEvent)
    end)

    comp:mouseDoubleClick(function(mouseEvent)
        parent:itemDoubleClicked(mouseEvent)
    end)

    comp:mouseDrag(function(mouseEvent)
        comp:startDragging( "LUser", parent:getItemPosition(true) )
    end)

    comp:resized(function()
        local r = luce:Rectangle(comp:getLocalBounds())
        slm:layOutComponents( {field, value or ""}, r:dump(), false, true)
    end)
 
    self.__self = comp.__self
    return setmetatable(self, {
        __tostring = function()return "Item("..id..(val and ":"..val or "")..")"end,
        __self     = comp.__self,
        __index    = comp,
        __newindex = comp,
    })
end

local function format_key(raw)
    local raw_hex = {}
    for i=1, #raw do
        raw_hex[#raw_hex+1] = string.format( "%02X", string.byte( raw:sub(i,i) ) )
    end
    return table.concat(raw_hex)
end
local function format_date(d)
    return os.date( "%c", d or os.date())
end
local attrs = {
    num     = function(n)return n end,
    active  = false,
    chatwin = false,
    online  = false,
    status  = false,
    name    = function(n)return n end,
    key     = format_key,
    lastOnline = format_date,
}

local function itemOpennessChanged(self, isNowOpen, parent)
    if (isNowOpen) then
        if(ROOT==self.name)then
            for _, c in next, self.data do
                self:addSubItem(self:new(c, nil, parent))
            end
        elseif("table"==type(self.data))then
            for k, v in next, attrs do
                if(v and self.data[k])then
                    self:addSubItem( self:new( k, v(self.data[k]) ) )
                end
            end
        end
    else
        if not(self.name == ROOT) then
            self:clearSubItems()
        end
    end
end

local function new(_, data, value, parent)
    local itemOpennessChanged = itemOpennessChanged
    local ec = EC()

    local User = User
    local Item = Item

    local name = ("table"==type(data) and (data.name or ROOT)) or data
    local itemOpennessChanged = itemOpennessChanged
    local comp = luce:TreeViewItem("TreeViewItem")

    comp:setDrawsInLeftMargin(false)

    local self = {
        isnode = data.name and true or false,
        parent = parent,
        name   = name,
        data   = data,
        new    = new,
        value  = value,
        item   = nil,
        width  = 120,
        height = 42,
        __self = comp.__self,
    }
    local self = setmetatable(self, {
        __tostring = function()return "DTTreeViewItem("..name..")"end,
        __self     = comp.__self,
        __index    = comp,
        __newindex = comp,
    })

    comp:getItemHeight(function()
        if(self.isnode)then
            return self.height
        else
            return 20
        end
    end)

    comp:itemSelectionChanged(function(isNowSelected)
        if(self.item and self.item.setSelected)then
            self.item:setSelected(isNowSelected)
        end
    end)
    comp:itemOpennessChanged(function(isNowOpen)
        itemOpennessChanged(self, isNowOpen, self.parent)
    end)

    comp:getUniqueName(function()
        return name
    end)

    comp:mightContainSubItems(function()
        return ("table"==type(self.data))
    end)

    local black, centredLeft = luce.Colours.black, luce.JustificationType.centredLeft
    local blueAlpha = luce:Colour(luce.Colours.blue):withAlpha(0.3)
    local selected = luce:Colour(luce.Colours.darkslategrey):withAlpha(0.9)

    local itemDoubleClicked = function(...) return comp.itemDoubleClicked(comp, ...) end
    local itemClicked = function(...) return comp.itemClicked(comp,...) end
    comp:itemClicked(function(e)
        local selected = not(self.item:isSelected())
        comp:setSelected(selected, true)
        if(self.isnode)then
            ec.broadcast("itemClicked", e, self.data, selected)
        end
    end)

    comp:paintItem(function(g,w,h)
        if(comp:isSelected())then
            g:fillAll(selected)
        end
    end)
    comp:createItemComponent(function()
        if(ROOT==name)then return nil end
        local item
        if(self.isnode)then
            item = User(data, self.parent)
            item:setBorder(1)
            item:itemClicked(itemClicked)
            item:itemDoubleClicked(itemDoubleClicked)
        else
            item = Item(data, value, self)
            item:setTooltip(true)
        end
        self.item = item
        return item
    end)

    comp:getDragSourceDescription(function()
        return "DTItem"
    end)

    comp:isInterestedInDragSource(function(...)
        return false
    end)

    return self
end

return setmetatable({}, {
    __tostring = function()return componentName end,
    __call = new
})
