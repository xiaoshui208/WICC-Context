mylib = require "mylib"

_G.Context = {
    _Version = "1.0.0",
    _Author = "Mr.Meeseeks",
    Lib = require "mylib",
    Debug = false,
    Exit = false,
    Event = {},
    Contract = {},
    CallDomain = 0x00,
    CallFunc = 0x00,
    RecvData = {},
    CurTxAddr = nil,
    CurTxPayAmount = nil,
    GetCurTxAddr = function()
        if _G._C.CurTxAddr == nil then
            local acc = _G._C.IHexArray:New({_G._C.Lib.GetCurTxAccount()})
            assert(acc:IsEmptyOrNil() == false, "GetCurTxAccount error.")
            local addr = _G._C.IHexArray:New({_G._C.Lib.GetBase58Addr(acc:Unpack())})
            assert(addr:IsEmptyOrNil() == false, "GetBase58Addr error.")
            _G._C.CurTxAddr = addr:ToString()
        end
        return _G._C.CurTxAddr
    end,
    GetCurTxPayAmount = function()
        if _G._C.CurTxPayAmount == nil then
            local amount = _G._C.IHexArray:New({_G._C.Lib.GetCurTxPayAmount()})
            assert(amount:IsEmptyOrNil() == false, "GetCurTxPayAmount error.")
            _G._C.CurTxPayAmount = amount:ToInt()
        end
        return _G._C.CurTxPayAmount
    end,
    IHexArray = {
        Posit = 1,
        New = function(s, d)
            local mt = {}
            if (type(d) == "string") then
                for i = 1, #d do
                    table.insert(mt, string.byte(d, i))
                end
            elseif d ~= nil then
                mt = d
            end
            setmetatable(mt, s)
            s.__index = s
            s.__eq = _G._C.IHexArray.Equals
            s.__tostring = _G._C.IHexArray.ToString
            return mt
        end,
        Equals = function(s, t)
            if (#s ~= #t) then
                return false
            end
            for i = #s, 1, -1 do
                if s[i] ~= t[i] then
                    return false
                end
            end
            return true
        end,
        Select = function(s, start, len)
            assert(#s >= start + len - 1, "[Select] Index Out Of Range")
            local newt = {}
            for i = 0, len - 1 do
                newt[1 + i] = s[start + i]
            end
            return _G._C.IHexArray:New(newt)
        end,
        Skip = function(s, start)
            local newt = {}
            for i = 0, #s - 1 do
                newt[1 + i] = s[1 + start + i]
            end
            return _G._C.IHexArray:New(newt)
        end,
        Take = function(s, len)
            local newt = {}
            for i = 0, len - 1 do
                newt[1 + i] = s[i]
            end
            return _G._C.IHexArray:New(newt)
        end,
        Next = function(s, len)
            local newt = {}
            for i = 0, len - 1 do
                assert(#s > s.Posit, "[Next] Index Out Of Range")
                newt[1 + i] = s[s.Posit]
                s.Posit = s.Posit + 1
            end
            return _G._C.IHexArray:New(newt)
        end,
        IsEmpty = function(s)
            return #s == 0
        end,
        IsEmptyOrNil = function(s)
            return _G.next(s) == nil or #s == 0
        end,
        ToString = function(s)
            local str = ""
            for i = 1, #s do
                str = str .. string.format("%c", s[i])
            end
            return str
        end,
        ToHexString = function(s)
            local str = ""
            for i = 1, #s do
                str = str .. string.format("%02x", s[i])
            end
            return str
        end,
        ToInt = function(s)
            assert(#s == 4 or #s == 8 or #s == 1 or #s == 2, "convet to int faild, len=" .. #s .. " type=" .. type(s))
            return _G._C.Lib.ByteToInteger(s:Unpack())
        end,
        Unpack = function(s)
            return _G._C.IHexArray.__expand(s)
        end,
        Fill = function(s, t)
            local filled = {}
            for k, v in pairs(t) do
                local vt = type(v)
                if vt == "table" then
                    if t[k].Loop then
                        if t[k].Loop == -4 then
                            t[k].Loop = s:Next(4):ToInt()
                        end
                        local subt = {}
                        local maxStep = #s
                        if t[k].Loop > 0 then
                            maxStep = s.Posit + t[k].Loop * t[k].Len
                        end
                        while s.Posit < maxStep do
                            local cell = s:Next(t[k].Len)
                            if t[k].Model then
                                cell = cell:Fill(t[k].Model)
                            end
                            table.insert(subt, cell)
                        end
                        filled[k] = subt
                    else
                        filled[k] = s:Next(v[1])
                    end
                elseif vt == "string" then
                    filled[k] = s:Next(tonumber(v)):ToString()
                elseif vt == "number" then
                    filled[k] = s:Next(v):ToInt()
                end
            end
            return filled
        end,
        __expand = function(t, i)
            i = i or 1
            if t[i] then
                return t[i], _G._C.IHexArray.__expand(t, i + 1)
            end
        end
    },
    IAppData = {
        SafeRead = function(key)
            assert(#key > 1, "[SafeReadAppData] Key lenght invalid")
            local value = _G._C.IHexArray:New({_G._C.Lib.ReadData(key)})
            if value.IsEmpty() then
                _G._C.Log("[SafeReadAppData] key has't set")
                return false, nil
            else
                return true, value
            end
        end,
        Read = function(key)
            assert(#key > 1, "[ReadAppData] Key lenght invalid")
            local value = _G._C.IHexArray:New({_G._C.Lib.ReadData(key)})
            return value
        end,
        Write = function(key, value)
            assert(type(key) == "string", "[Write] key type error")
            local writeDbTbl = {key = key, length = #value, value = value}
            if _G._C.Lib.WriteData(writeDbTbl) ~= true then
                _G._C.Log("WriteAppData error")
                error("WriteAppData error")
            end
            return true
        end,
        WriteStr = function(key, value)
            assert(type(value) == "string", "[WriteStr] value type error")
            local valueT = _G._C.IHexArray:New(value)
            return _G._C.IAppData.Write(key, valueT)
        end,
        Modify = function(key, value)
            assert(type(key) == "string", "[Modify] key type error")
            local writeDbTbl = {key = key, length = #value, value = value}
            if _G._C.Lib.ModifyData(writeDbTbl) ~= true then
                _G._C.Log("ModifyAppData error")
                error("ModifyAppData error")
            end
            return true
        end,
        Delete = function(key) --/*todo*/
            assert(type(key) == "string", "[DeleteData] key type error")
            if _G._C.Lib.DeleteData(key) ~= true then
                _G._C.Log("DeleteAppData error")
                error("DeleteAppData error")
            end
            return true
        end
    },
    IAsset = {
        NET_ASSET_OP = {
            ADD = 1,
            SUB = 2
        },
        APP_ASSET_OP = {
            ADD = 1,
            SUB = 2,
            ADD_FREEZED = 3,
            SUB_FREEZED = 4
        },
        ADDR_TYPE = {
            REGID = 1,
            BASE58 = 2
        },
        SendSelfNetAsset = function(toAddr, money)
            if type(toAddr) == "string" then
                toAddr = _G._C.IHexArray:New(toAddr)
            end
            if type(money) == "number" then
                money = _G._C.IHexArray:New({_G._C.Lib.IntegerToByte8(money)})
            end
            assert(#toAddr == 34 or #toAddr == 6, "toAddr lenght invalid")
            assert(#money == 8, "money lenght invalid")
            assert(money:ToInt() > 0, "money error")
            local tb = {
                addrType = (#toAddr == 6 and _G._C.IAsset.ADDR_TYPE.REGID) or _G._C.IAsset.ADDR_TYPE.BASE58,
                accountIdTbl = toAddr,
                operatorType = _G._C.IAsset.NET_ASSET_OP.ADD,
                outHeight = 0,
                moneyTbl = money
            }
            assert(_G._C.Lib.WriteOutput(tb), "WriteOutput err0")
            tb.addrType = _G._C.IAsset.ADDR_TYPE.REGID
            tb.operatorType = _G._C.IAsset.NET_ASSET_OP.SUB
            tb.accountIdTbl = {_G._C.Lib.GetScriptID()}
            assert(money:ToInt() < _G._C.IAsset.GetNetAsset(tb.accountIdTbl), "self balance error")
            assert(_G._C.Lib.WriteOutput(tb), "WriteOutput err1")
            return true
        end,
        GetNetAsset = function(addr)
            if type(addr) == "string" then
                addr = _G._C.IHexArray:New(addr)
            end
            assert(#addr == 34 or #addr == 6, "addr lenght invalid, len=" .. #addr)
            local mtb = _G._C.IHexArray:New({_G._C.Lib.QueryAccountBalance(addr:Unpack())})
            assert(#mtb > 0, "GetNetAssetValue error")
            return mtb:ToInt()
        end,
        GetAppAsset = function(addr)
            local mtb =
                _G._C.IHexArray:New(
                {
                    _G._C.Lib.GetUserAppAccValue(
                        {
                            idLen = #addr,
                            idValueTbl = addr
                        }
                    )
                }
            )
            assert(#mtb > 0, "GetUserAppAccValue error")
            return mtb:ToInt()
        end,
        AddAppAsset = function(toAddr, money)
            if type(toAddr) == "string" then
                toAddr = _G._C.IHexArray:New(toAddr)
            end
            if type(money) == "number" then
                money = _G._C.IHexArray:New({_G._C.Lib.IntegerToByte8(money)})
            end
            assert(#toAddr == 34, "[AddAppAsset] toAddr lenght invalid")
            assert(#money == 8, "[AddAppAsset] money lenght invalid")
            assert(money:ToInt() > 0, "[AddAppAsset] money error")
            local tb = {
                operatorType = _G._C.IAsset.APP_ASSET_OP.ADD,
                outHeight = 0,
                moneyTbl = money,
                userIdLen = #toAddr,
                userIdTbl = toAddr,
                fundTagLen = 0,
                fundTagTbl = {}
            }
            assert(_G._C.Lib.WriteOutAppOperate(tb), "WriteOutAppOperate error")
            --/todo:throw more error info and tx details /
            return true
        end,
        SubAppAsset = function(fromAddr, money)
            if type(fromAddr) == "string" then
                fromAddr = _G._C.IHexArray:New(fromAddr)
            end
            if type(money) == "number" then
                money = _G._C.IHexArray:New({_G._C.Lib.IntegerToByte8(money)})
            end
            assert(#fromAddr == 34, "[SubAppAsset] fromAddr lenght invalid")
            assert(#money == 8, "[SubAppAsset] money lenght invalid")
            assert(money:ToInt() > 0, "[SubAppAsset] money error")
            assert(_G._C.IAsset.GetAppAsset(fromAddr) >= money:ToInt(), "[SubAppAsset] fromAddr balance error")
            local tb = {
                operatorType = _G._C.IAsset.APP_ASSET_OP.SUB,
                outHeight = 0,
                moneyTbl = money,
                userIdLen = #fromAddr,
                userIdTbl = fromAddr,
                fundTagLen = 0,
                fundTagTbl = {}
            }
            assert(_G._C.Lib.WriteOutAppOperate(tb), "WriteOutAppOperate error")
            --/todo:throw more error info and tx details /
            return true
        end,
        SendAppAsset = function(fromAddr, toAddr, money)
            if type(fromAddr) == "string" then
                fromAddr = _G._C.IHexArray:New(fromAddr)
            end
            if type(toAddr) == "string" then
                toAddr = _G._C.IHexArray:New(toAddr)
            end
            if type(money) == "number" then
                money = _G._C.IHexArray:New({_G._C.Lib.IntegerToByte8(money)})
            end

            assert(#fromAddr == 34, "[SendAppAsset] fromAddr lenght invalid")
            assert(#toAddr == 34, "[SendAppAsset] toAddr lenght invalid")
            assert(fromAddr ~= toAddr, "[SendAppAsset] fromAddr can't be a toAddr")
            assert(#money == 8, "[SendAppAsset] money lenght invalid")
            assert(money:ToInt() > 0, "[SendAppAsset] money error")
            assert(_G._C.IAsset.GetAppAsset(fromAddr) >= money:ToInt(), "[SendAppAsset] fromAddr balance error")

            local tb = {
                operatorType = _G._C.IAsset.APP_ASSET_OP.SUB,
                outHeight = 0,
                moneyTbl = money,
                userIdLen = #fromAddr,
                userIdTbl = fromAddr,
                fundTagLen = 0,
                fundTagTbl = {}
            }
            assert(_G._C.Lib.WriteOutAppOperate(tb), "WriteOutAppOperate error at sub")

            tb = {
                operatorType = _G._C.IAsset.APP_ASSET_OP.ADD,
                outHeight = 0,
                moneyTbl = money,
                userIdLen = #toAddr,
                userIdTbl = toAddr,
                fundTagLen = 0,
                fundTagTbl = {}
            }
            assert(_G._C.Lib.WriteOutAppOperate(tb), "WriteOutAppOperate error at add")
            --/todo:throw more error info and tx details /
            return true
        end
    },
    Log = function(content)
        assert(#content >= 1, "[Log] content lenght invalid")
        assert(type(content) == "string", "[Log] content type error")
        _G._C.Lib.LogPrint({key = 0, length = #content, value = content})
        return content
    end,
    ThrowError = function(msg)
        assert(type(msg) == "string", "[ThrowError] msg type error")
        error(msg)
    end,
    Init = function(...)
        if _G._C == nil then
            _G._C = _G.Context
            _G.HexArray = _G._C.IHexArray
            _G.AppData = _G._C.IAppData
            _G.Asset = _G._C.IAsset
            _G.Log = _G._C.Log
            for k ,v in pairs({ ... }) do
                if v.Init ~= nil then
                    v.Init()
                end
            end
        end
        return _G._C
    end,
    RegDomain = function(domainId, domain)
        _G._C.Event[domainId] = domain
        return _G._C
    end,
    LoadContract = function()
        if #_G.contract > 0 then
            _G._C.Contract = _G._C.IHexArray:New(_G.contract)
            if _G._C.Contract[1] == 0xff then
                _G._C.Debug = true
                _G._C.CallDomain = _G._C.Contract[2]
                _G._C.CallFunc = _G._C.Contract[3]
                _G._C.RecvData = _G._C.Contract:Skip(3)
            else
                _G._C.CallDomain = _G._C.Contract[1]
                _G._C.CallFunc = _G._C.Contract[2]
                _G._C.RecvData = _G._C.Contract:Skip(2)
            end
        end
    end,
    Main = function()
        _G.Context.Init()
        _G._C.LoadContract()
        if _G._C.Event[_G._C.CallDomain] == nil then
            error("domain " .. string.format("%02x", _G._C.CallDomain) .. " not found")
        end
        if _G._C.Event[_G._C.CallDomain][_G._C.CallFunc] ~= nil then
            _G._C.Event[_G._C.CallDomain][_G._C.CallFunc]()
        else
            error("method " .. string.format("%02x", _G._C.CallFunc) .. " not found")
        end
    end
}

_G.ContextTestUnit={
    Init=function()
        _G._C.Event[0xaa]=_G.ContextTestUnit
        _G.ContextTestUnit[0xaa]=_G.ContextTestUnit.HexArrayTest
        _G.ContextTestUnit[0x01]=_G.ContextTestUnit.GetCurTxAddrTest
        _G.ContextTestUnit[0x02]=_G.ContextTestUnit.GetCurTxPayAmountTest
        _G.ContextTestUnit[0x03]=_G.ContextTestUnit.AppDataWrtieTest
        _G.ContextTestUnit[0x04]=_G.ContextTestUnit.AppDataReadTest
        _G.ContextTestUnit[0x05]=_G.ContextTestUnit.AppDataReadIntTest
        _G.ContextTestUnit[0x06]=_G.ContextTestUnit.AppDataDeleteTest
        _G.ContextTestUnit[0x07]=_G.ContextTestUnit.AppDataModifyTest
        _G.ContextTestUnit[0x08]=_G.ContextTestUnit.GetNetAssetTest
        _G.ContextTestUnit[0x09]=_G.ContextTestUnit.GetNetAssetTest2
        _G.ContextTestUnit[0x10]=_G.ContextTestUnit.ShowMeTheMoney
        _G.ContextTestUnit[0x11]=_G.ContextTestUnit.SubAppAssetTest
        _G.ContextTestUnit[0x12]=_G.ContextTestUnit.SendAppAssetTest
        --TODO
    end,
    HexArrayTest=function()
        local str="I'm Mr.Meeseeks~Look at me~"
        local ha=_G.HexArray:New(str)
        local str2=ha:ToString()
        error('len='..#ha..' type='..type(ha)..' print='..str2)
    end,
    GetCurTxAddrTest = function()
        local curaddr = _G.Context.GetCurTxAddr()
        error('CurTxAddr='..curaddr)
    end,
    GetCurTxPayAmountTest=function()
        local amount = _G.Context.GetCurTxPayAmount()
        error('CurTxPayAmount='..amount)
    end,
    AppDataWrtieTest=function()
        local key   = _G.Context.RecvData:Next(2):ToHexString()
        local value = _G.Context.RecvData:Skip(2)
        print('AppDataWrtieTest , Key='..key..' , Value='..value:ToHexString())
        _G.AppData.Write(key,value)
    end,
    AppDataReadTest=function()
        local key   = _G.Context.RecvData:Take(2):ToHexString()
        local value = _G.AppData.Read(key)
        local info  = 'AppDataReadTest , Key='..key..' , ValueHex='..value:ToHexString()..' , Value='..value:ToString()..' , Len='..#value
        print(info)
        error(info)
    end,
    AppDataReadIntTest=function()
        local key   = _G.Context.RecvData:Select(1,2):ToHexString()
        local value = _G.AppData.Read(key)
        local info  = 'AppDataReadTest , Key='..key..' , ValueHex='..value:ToHexString()..' , Value='..value:ToInt()..' , Len='..#value
        print(info)
        error(info)
    end,
    AppDataDeleteTest=function()
        local key   = _G.Context.RecvData:Next(2):ToHexString()
        local value = _G.AppData.Delete(key)
        local info  = 'AppDataDeleteTest , Key='..key..' Resault='..value
        print(info)
    end,
    AppDataModifyTest=function()
        local key   = _G.Context.RecvData:Next(2):ToHexString()
        local value = _G.Context.RecvData:Skip(2)
        print('AppDataModifyTest , Key='..key..' , Value='..value:ToHexString())
        _G.AppData.Modify(key,value)
    end,
    GetNetAssetTest=function()
        local curaddr = _G.Context.GetCurTxAddr()
        local txAddrMoney=_G.Asset.GetNetAsset(curaddr)
        error('byBase58='..txAddrMoney)
    end,
    GetNetAssetTest2=function()
	    local accountTbl = _G.HexArray:New({_G.Context.Lib.GetScriptID()})
        local txAddrMoney2=_G.Asset.GetNetAsset(accountTbl)
        error('byRegId='..txAddrMoney2)
    end,
    ShowMeTheMoney=function()
        local curaddr = _G.Context.GetCurTxAddr()
        _G.Asset.AddAppAsset(curaddr,1000000)
    end,
    SubAppAssetTest=function()
        local curaddr = _G.Context.GetCurTxAddr()
        _G.Asset.AddAppAsset(curaddr,100000)
    end,
    SendAppAssetTest=function()
        local curaddr = _G.Context.GetCurTxAddr()
        local tx=_G.RecvData:Fill({to='34',money=8})
        _G.Asset.SendAppAsset(curaddr,tx.to,tx.money)
    end,
}

_G.Context.Init(_G.ContextTestUnit).Main()
