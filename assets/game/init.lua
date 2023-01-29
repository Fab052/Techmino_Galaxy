Minoes=require'assets.game.minoes'
ColorTable=require'assets.game.colorTable'
defaultMinoColor=setmetatable({2,22,42,6,52,12,32},{__index=function() return math.random(64) end})
defaultPuyoColor=setmetatable({2,12,42,22,52},{__index=function() return math.random(64) end})
particleSystemTemplate=require'assets.game.particleSystemTemplate'
require'assets.game.rotsys_mino'
require'assets.game.atksys_mino'

local gc=love.graphics

local layoutFuncs={}
do -- function layoutFuncs.default():
    local defaultPosList={
        alive={
            [1]={main={800,500}},
            [3]={main={800,500},
                {1380,600,.5},
                {220,600,.5},
            },
            [5]={main={800,500},
                {220,260,.5},
                {1380,260,.5},
                {220,740,.5},
                {1380,740,.5},
            },
            [7]={main={800,500},
                {220,200,.34},{220,500,.34},{220,800,.34},
                {1380,200,.34},{1380,500,.34},{1380,800,.34},
            },
            [17]={main={800,500},
                {120,140,.26},{120,380,.26},{120,620,.26},{120,860,.26},
                {320,140,.26},{320,380,.26},{320,620,.26},{320,860,.26},
                {1280,140,.26},{1280,380,.26},{1280,620,.26},{1280,860,.26},
                {1480,140,.26},{1480,380,.26},{1480,620,.26},{1480,860,.26},
            },
            [37]=(function()
                local l={main={800,500}}
                for y=-2.5,2.5 do
                    for x=0,2 do
                        table.insert(l,{340-130*x ,500+160*y,.17})
                        table.insert(l,{1260+130*x,500+160*y,.17})
                    end
                end
                return l
            end)(),
            [73]=(function()
                local l={main={800,500}}
                for y=-4,4 do
                    for x=0,3 do
                        table.insert(l,{360-100*x ,500+110*y,.13})
                        table.insert(l,{1240+100*x,500+110*y,.13})
                    end
                end
                return l
            end)(),
            [MATH.inf]={main={800,500}},
        },
        dead={
            [1]={{800,500}},
            [2]={
                {420,500,.9},{1180,500,.9},
            },
            [3]={
                {280,500,.66},{800,500,.66},{1320,500,.66},
            },
            [4]={
                {210,500,.5},{600,500,.5},{1000,500,.5},{1390,500,.5},
            },
            [15]=(function()
                local l={}
                for y=-1,1 do
                    for x=-2,2 do
                        table.insert(l,{800+315*x ,500+320*y,.36})
                    end
                end
                return l
            end)(),
            [32]=(function()
                local l={}
                for y=-1.5,1.5 do
                    for x=-3.5,3.5 do
                        table.insert(l,{800+200*x ,500+240*y,.25})
                    end
                end
                return l
            end)(),
            [72]=(function()
                local l={}
                for y=-2.5,2.5 do
                    for x=-5.5,5.5 do
                        table.insert(l,{800+130*x ,500+160*y,.17})
                    end
                end
                return l
            end)(),
            [MATH.inf]={},
        },
    }
    function layoutFuncs.default()
        local mode=GAME.mainPlayer and defaultPosList.alive or defaultPosList.dead
        local minCap=MATH.inf
        for count in next,mode do
            if count<=minCap and count>=#GAME.playerList then
                minCap=count
            end
        end
        local layoutData=mode[minCap]

        local pos=1
        for _,P in next,GAME.playerList do
            if P.isMain then
                P:setPosition(unpack(layoutData.main))
            else
                P:setPosition(unpack(layoutData[pos]))
                pos=pos+1
            end
        end
    end
end

local modeLib={}
local modeMeta={
    __index={
        initialize=NULL,
        settings={},
        layout='default',
        checkFinish=function() return true end,
        result=NULL,
        resultPage=NULL,
    },
    __metatable=true,
}

local function task_switchToResult()
    if SCN.cur=='game_in' then
        SCN.swapTo('result_in','none')
    elseif SCN.cur=='game_out' then
        local time=love.timer.getTime()
        repeat
            if SCN.swapping then return end
            coroutine.yield()
        until love.timer.getTime()-time>1.26
        SCN.swapTo('result_out','none')
    end
end

local GAME={
    playing=false,

    playerList=false,
    playerMap=false,

    hitWaves={},

    seed=false,
    mode=false,

    mainPID=false,
    mainPlayer=false,
}

function GAME.getMode(name)
    if modeLib[name] then
        return modeLib[name]
    else
        local path='assets/game/mode/'..name..'.lua'
        assert(love.filesystem.getInfo(path) and FILE.isSafe(path),"No mode named "..tostring(name))
        local M=FILE.load(path,'-lua -canskip')
        assert(type(M)=='table')
        setmetatable(M,modeMeta)
        assert(type(M.initialize)         =='function',"[mode].initialize must be function")
        assert(type(M.settings)           =='table',   "[mode].settings must be table")
        assert(type(layoutFuncs[M.layout])=='function',"[mode].layout type wrong")
        assert(type(M.checkFinish)        =='function',"[mode].checkFinish must be function")
        assert(type(M.result)             =='function',"[mode].result must be function")
        assert(type(M.resultPage)         =='function',"[mode].resultPage must be function")

        M.name=name
        modeLib[name]=M
        return M
    end
end

function GAME.reset(mode,seed)
    GAME.playing=true
    GAME.playerList={}
    GAME.playerMap={}

    GAME.hitWaves={}

    GAME.mainPlayer=false
    GAME.seed=seed or math.random(2^16,2^26)
    GAME.mode=mode and GAME.getMode(mode) or NONE
    if GAME.mode.initialize then GAME.mode.initialize() end
    TASK.removeTask_code(task_switchToResult)
end

function GAME.newPlayer(id,pType)
    if not (type(id)=='number' and math.floor(id)==id and id>=1 and id<=1000) then
        MES.new('error',"player id must be 1~1000 integer")
        return
    end

    local P
    if pType=='mino' then
        P=require'assets.game.minoPlayer'.new(GAME.mode)
    elseif pType=='puyo' then
        P=require'assets.game.puyoPlayer'.new(GAME.mode)
    elseif pType=='gem' then
        P=require'assets.game.gemPlayer'.new(GAME.mode)
    else
        MES.new('error',"invalid player type :'"..tostring(pType).."'")
        return
    end

    P.gameMode=pType
    P.id=id
    P.group=0
    P.isMain=false
    GAME.playerMap[id]=P
    table.insert(GAME.playerList,P)
end

function GAME.setMain(id)
    if GAME.mainPlayer then
        GAME.playerMap[GAME.mainPlayer].isMain=false
        GAME.mainPID=false
        GAME.mainPlayer=false
    end
    if GAME.playerMap[id] then
        GAME.mainPID=id
        GAME.mainPlayer=GAME.playerMap[id]
        GAME.mainPlayer.isMain=true
        GAME.mainPlayer.sound=true
    end
end

function GAME.setGroup(id,gid)
    assert(type(gid)=='number' and gid>=0 and gid%1==gid,"Invalid group id")
    if GAME.playerMap[id] then
        GAME.playerMap[id].group=gid
    end
end

function GAME.start()
    if #GAME.playerList==0 then
        MES.new('warn',"No players created in this mode")
    else
        if GAME.mainPlayer then
            local conf=SETTINGS["game_"..GAME.mainPlayer.gameMode]
            if conf then GAME.mainPlayer:loadSettings(conf) end
        end
        if GAME.mode.settings then
            for i=1,#GAME.playerList do
                local conf=GAME.mode.settings[GAME.playerList[i].gameMode]
                if conf then
                    GAME.playerList[i]:loadSettings(conf)
                end
            end
        end

        for i=1,#GAME.playerList do
            GAME.playerList[i]:initialize()
            GAME.playerList[i]:triggerEvent('playerInit')
        end

        layoutFuncs[GAME.mode['layout']]()
    end
end

function GAME.press(action,id)
    if id then
        GAME.playerMap[id]:pressKey(action)
    elseif GAME.mainPlayer then
        GAME.mainPlayer:pressKey(action)
    end
end

function GAME.release(action,id)
    if id then
        GAME.playerMap[id]:releaseKey(action)
    elseif GAME.mainPlayer then
        GAME.mainPlayer:releaseKey(action)
    end
end

--[[ data:
    power      (0~∞,  no default)
    cancelRate (0~∞,  default to 1)
    defendRate (0~∞,  default to 1)
    mode       (0~1,   default to 0, 0: trigger by time, 1:trigger by step)
    time       (0~∞,  default to 0, seconds)
    fatal      (0~100, default to 50, percentage)
    speed      (0~100, default to 50, percentage)
]]
function GAME.initAtk(atk)-- Normalize the attack object
    if not atk then return end
    assert(type(atk)=='table',"data not table")
    assert(type(atk.power)=='number' and atk.power>0,"wrong power value")
    if atk.cancelRate==nil then atk.cancelRate=1 else
        assert(type(atk.cancelRate)=='number' and atk.cancelRate>=0,"cancelRate not non-negative number")
    end

    if atk.defendRate==nil then atk.defendRate=1 else
        assert(type(atk.defendRate)=='number' and atk.defendRate>=0,"defendRate not non-negative number")
    end

    if atk.mode==nil then atk.mode=0 end
    assert(atk.mode==0 or atk.mode==1,"mode not 0 or 1")
    if atk.time==nil then atk.time=0 else
        assert(type(atk.time)=='number' and atk.time>=0,"time not non-negative number")
        if atk.mode==1 then atk.time=math.floor(atk.time) end
    end
    if atk.fatal==nil then atk.fatal=50 else
        assert(type(atk.fatal)=='number',"fatal not number")
        atk.fatal=MATH.clamp(atk.fatal,0,100)
    end
    if atk.speed==nil then atk.speed=50 else
        assert(type(atk.speed)=='number',"speed not number")
        atk.speed=MATH.clamp(atk.speed,0,100)
    end
    return atk
end
function GAME.send(source,data)
    -- Find target
    if data.target==nil then
        local l=GAME.playerList
        if #l>1 then
            local count=0
            for i=1,#l do
                if source.group==0 and l[i]~=source or source.group~=l[i].group then
                    count=count+1
                end
            end
            if count>0 then
                count=math.random(count)
                for i=1,#l do
                    if source.group==0 and l[i]~=source or source.group~=l[i].group then
                        count=count-1
                        if count==0 then
                            data.target=l[i]
                            break
                        end
                    end
                end
            end
        end
    else
        assert(type(data.target)=='number',"target not number")
        data.target=GAME.playerMap[data.target]
    end

    -- Sending airmail
    if data.target then
        data.target:receive(data)
    end
end

function GAME.checkFinish()
    if GAME.playing and GAME.mode.checkFinish() then
        GAME.playing=false
        GAME.mode.result()
        if GAME.mode.resultPage~=NULL then
            TASK.new(task_switchToResult)
        end
    end
end

function GAME.update(dt)
    for _,P in next,GAME.playerList do P:update(dt) end

    for i=#GAME.hitWaves,1,-1 do
        local wave=GAME.hitWaves[i]
        wave.time=wave.time+dt
    end
end

function GAME.render()
    gc.setCanvas({Zenitha.getBigCanvas('player'),stencil=true})
    gc.clear(0,0,0,0)
    for _,P in next,GAME.playerList do P:render() end
    gc.setCanvas()

    gc.replaceTransform(SCR.origin)
    if #GAME.hitWaves>0 then
        local L=GAME.hitWaves
        for i=1,#L do
            local timeK=1/(400*L[i].time+50)-.0026
            if timeK<=0 then
                L[i][3]=0
            else
                L[i][3]=6.26-2.6*L[i].time
                L[i][4]=math.cos(L[i].time*26)*L[i].power*timeK
            end
        end
        SHADER.warp:send('hitWaves',unpack(L))
        gc.setShader(SHADER.warp)
    else
        gc.setShader(SHADER.none)-- Directly draw the content, don't consider color, for better performance(?)
    end
    gc.draw(Zenitha.getBigCanvas('player'))
    gc.setShader()
end

function GAME._addHitWave(x,y,power)
    if SETTINGS.system.hitWavePower<=0 then return end
    if #GAME.hitWaves>=8 then
        local maxI=1
        for i=2,#GAME.hitWaves do
            if GAME.hitWaves[i].time>GAME.hitWaves[maxI].time then
                maxI=i
            end
        end
        table.remove(GAME.hitWaves,maxI)
    end
    table.insert(GAME.hitWaves,{
        x,y,
        nil,nil,-- power1 & power2, calculated before sending uniform
        time=0,
        power=power*SETTINGS.system.hitWavePower,
    })
end

return GAME
