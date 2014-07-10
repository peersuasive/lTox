local luce, app = _G.Luce, _G.App

local function startDHT()
    local nodesList = "/home/distances/.config/tox/DHTnodes"
    -- 192.254.75.98 33445 951C88B7E75C867418ACDB5D273821372BB5BD652740BCDF623A4FA293E75D2F
    local f = io.open(nodesList, "rb")
    local nodes = { nil, nil, nil, nil, nil }
    while true do
        local l = f:read("*l")
        if not(l) then break end
        local ip, port, id = l:match("^([^%s]+) ([^%s]+) ([^%s]+)$")
        nodes[#nodes+1] = { ip = ip, port = port, id = id }
    end 
    f:close()
    -- random connect to a peer
    local node = nodes[1]
    print( "dht connect...", app.tox.tox:bootstrapFromAddress( node.ip, 0, node.port, node.id ) )
    return true
end

local function formatAddress(raw)
    local raw_hex = {}
    for i=1, #raw do
        raw_hex[#raw_hex+1] = string.format( "%02X", string.byte( raw:sub(i,i) ) )
    end
    return table.concat(raw_hex)
end

local function format_date(d)
    return os.date( "%c", d or os.time())
end

local self = {
    startDHT = startDHT,
    formatAddress = formatAddress,
    formatDate = format_date,
}
return setmetatable(self, { __index = self })
