function sureCheck(event)
    if TASK.lock('sureCheck_'..event,1) then
        MSG.new('info',Text.sureText[event],1)
    else
        return true
    end
end

function drawGlitch()
    local setc,rect=GC.setColor,GC.rectangle
    local t=love.timer.getTime()
    local cellSize=math.min(SCR.w,SCR.h)/26
    GC.replaceTransform(SCR.origin)
    for x=0,SCR.w,cellSize do
        for y=0,SCR.h,cellSize do
            setc(1,1,1,(math.floor(t*2.6)*(x*26+62)*(y*42+24))/10%2.6%.042)
            rect('fill',x,y,cellSize,cellSize)
        end
    end
end
function drawGlitch2()
    local setc,rect=GC.setColor,GC.rectangle
    local t=love.timer.getTime()
    local a=1/26
    GC.replaceTransform(SCR.origin)
    GC.scale(1,SCR.h)
    for i=0,26 do
        setc(1,1,1,(math.floor(t*2.6+i/6)*(26+i))%0.0355)
        rect('fill',0,a*(i-2.6*t%1),SCR.w,a*.355)
    end
end

local _bgmPlaying ---@type string?
---@param name Techmino.MusicName
---@param full? boolean|table
---@param noProgress? boolean
function playBgm(name,full,noProgress)
    if name==_bgmPlaying then return end
    if not noProgress and not SONGBOOK[name].inside then
        PROGRESS.setBgmUnlocked(SONGBOOK[name].redirect or name,full and 2 or 1)
    end
    if full==true then
        FMOD.music(name)
    elseif not full then
        FMOD.music(name,{param={'intensity',0,true}})
    else
        ---@cast full table
        FMOD.music(name,full)
    end
    _bgmPlaying=name
end
function getBgm()
    return _bgmPlaying
end
function stopBgm(instant)
    FMOD.music.stop(instant)
    _bgmPlaying=nil
end
function playSample(...)
    local l={...}
    local inst
    for i=1,#l do
        if type(l[i])=='string' then
            inst=l[i]..'_wave'
        elseif type(l[i])=='table' then
            local note=l[i][1]
            if type(note)=='string' then note=SFX.getTuneHeight(l[i][1]) end
            local vol=l[i][2] or 1
            local len=l[i][3] or 420
            local rel=l[i][4] or 620
            local event=FMOD.effect(inst,{
                tune=note>=0 and note-26 or nil,
                pitch=note<0 and -note or nil,
                volume=vol,
                param={'release',rel*1.0594630943592953^(note-26)},
            })
            if not event then return end
            TASK.new(function()
                TASK.yieldT(len/1000)
                event:stop(FMOD.FMOD_STUDIO_STOP_ALLOWFADEOUT)
            end)
        end
    end
end

gameSoundFunc={}
gameSoundFunc.__index=gameSoundFunc
gameSoundFunc.__metatable=true
setmetatable(gameSoundFunc,{
    __newindex=function(self,k,v)
        if v==NULL then
            rawset(self,k,function(vol) FMOD.effect(k,vol) end)
        else
            rawset(self,k,v)
        end
    end
})
do
    local _someSFX=NULL
    gameSoundFunc.move                  =_someSFX
    gameSoundFunc.move_down             =_someSFX
    gameSoundFunc.move_failed           =_someSFX
    gameSoundFunc.touch                 =_someSFX
    gameSoundFunc.lock                  =_someSFX
    gameSoundFunc.tuck                  =_someSFX
    gameSoundFunc.rotate                =_someSFX
    gameSoundFunc.rotate_init           =_someSFX
    gameSoundFunc.rotate_locked         =_someSFX
    gameSoundFunc.rotate_corners        =_someSFX
    gameSoundFunc.rotate_failed         =_someSFX
    gameSoundFunc.rotate_special        =_someSFX
    gameSoundFunc.hold                  =_someSFX
    gameSoundFunc.hold_init             =_someSFX
    gameSoundFunc.drop                  =_someSFX
    gameSoundFunc.drop_old              =_someSFX
    gameSoundFunc.clear_all             =_someSFX
    gameSoundFunc.clear_half            =_someSFX
    gameSoundFunc.frenzy                =_someSFX
    gameSoundFunc.discharge             =_someSFX
    gameSoundFunc.suffocate             =_someSFX
    gameSoundFunc.desuffocate           =_someSFX
    gameSoundFunc.beep_rise             =_someSFX
    gameSoundFunc.beep_drop             =_someSFX
    gameSoundFunc.beep_notice           =_someSFX
    gameSoundFunc.finish_win            =_someSFX
    gameSoundFunc.finish_suffocate      =_someSFX
    gameSoundFunc.finish_lockout        =_someSFX
    gameSoundFunc.finish_topout         =_someSFX
    gameSoundFunc.finish_timeout        =_someSFX
    gameSoundFunc.finish_rule           =_someSFX
    gameSoundFunc.finish_exhaust        =_someSFX
    gameSoundFunc.finish_taskfail       =_someSFX
    gameSoundFunc.finish_other          =_someSFX
    for k,v in next,gameSoundFunc do
        if v==_someSFX then
            gameSoundFunc[k]=function(vol) FMOD.effect(k,vol) end
        end
    end
end

function gameSoundFunc.countDown(num)
    if num==0 then -- 6, 3+6+6
        playSample('organ',{'A3',.8})
        playSample('square',{'A4',.9},{'E5',.9},{'A5',.9})
    elseif num==1 then -- 5, 3+7
        playSample('organ',{'G3',.9})
        playSample('square',{'B4',.9},{'E5',.9})
    elseif num==2 then -- 4, 6+2
        playSample('organ',{'F3'})
        playSample('square',{'A4',.8},{'D5',.8})
    elseif num==3 then -- 6+6
        playSample('organ',{'A3',.9},{'E4',.9})
        playSample('square',{'A4',.8})
    elseif num==4 then -- 5+7, 5
        playSample('organ',{'G3',.9},{'B3',.9})
        playSample('square',{'G4',.6})
    elseif num==5 then -- 4+6, 4
        playSample('organ',{'F3',.8},{'A3',.8})
        playSample('square',{'F4',.3})
    elseif num<=10 then
        playSample('organ',{'A2',2.2-num/5},{'E3',2.2-num/5})
    end
end
function gameSoundFunc.clear(lines)
    lines=math.floor(math.max(lines,1))
    FMOD.effect(
        lines<=6 and 'clear_'..lines or -- 1, 2, 3, 4, 5, 6
        lines<=18 and 'clear_'..(lines-lines%2) or -- 8, 10, 12, 14, 16, 18
        lines<=22 and 'clear_'..lines or -- 20, 21, 22
        lines<=26 and 'clear_'..(lines-lines%2) or -- 24, 26
        'clear_26'
    )
end
function gameSoundFunc.spin(lines)
    lines=math.floor(math.max(lines,0))
    FMOD.effect(
        lines<=4 and 'spin_'..lines or
        'spin_mega'
    )
end
function gameSoundFunc.charge(lv)
    FMOD.effect('charge_'..MATH.clamp(math.floor(lv),1,11))
end
gameSoundFunc.combo=setmetatable({__register=true,
    function() playSample('organ',{'A2',.70,420}) end, -- 1
    function() playSample('organ',{'C3',.75,410}) end, -- 2
    function() playSample('organ',{'D3',.80,400}) end, -- 3
    function() playSample('organ',{'E3',.85,390}) end, -- 4
    function() playSample('organ',{'G3',.90,380}) end, -- 5
    function() playSample('organ',{'A3',.90,370},'square',{'A2',.20,420,620}) end, -- 6
    function() playSample('organ',{'C4',.75,360},'square',{'C3',.40,400,620}) end, -- 7
    function() playSample('organ',{'D4',.60,350},'square',{'D3',.60,380,620}) end, -- 8
    function() playSample('organ',{'E4',.40,340},'square',{'E3',.75,360,620}) end, -- 9
    function() playSample('organ',{'G4',.20,330},'square',{'G3',.90,340,620}) end, -- 10
    function() playSample('organ',{'A4',.20,320},'square',{'A3',.85,320,620}) end, -- 11
    function() playSample('organ',{'A4',.40,310},'square',{'C4',.80,300,620}) end, -- 12
    function() playSample('organ',{'A4',.60,300},'square',{'D4',.75,280,620}) end, -- 13
    function() playSample('organ',{'A4',.75,290},'square',{'E4',.70,270,620}) end, -- 14
    function() playSample('organ',{'A4',.90,280},'square',{'G4',.65,260,640}) end, -- 15
    function() playSample('organ',{'A4',.90,270},{'E5',.70},'square',{'A4',1,250,660}) end, -- 16
    function() playSample('organ',{'A4',.85,260},{'E5',.75},'square',{'C5',1,240,680}) end, -- 17
    function() playSample('organ',{'A4',.80,250},{'E5',.80},'square',{'D5',1,230,700}) end, -- 18
    function() playSample('organ',{'A4',.75,240},{'E5',.85},'square',{'E5',1,220,720}) end, -- 19
    function() playSample('organ',{'A4',.70,230},{'E5',.90},'square',{'G5',1,210,740}) end, -- 20
},{__call=function(self,combo)
    if self[combo] then
        self[combo]()
    else
        playSample('organ',{'A4',.626-.01*combo,430-10*combo})
        local phase=(combo-21)%12
        playSample('square',{40+phase,1-((11-phase)/12)^2,400-10*combo,700+20*combo}) -- E4+
        playSample('square',{45+phase,1-((11-phase)/12)^2,400-10*combo,700+20*combo}) -- A4+
        playSample('square',{52+phase,1-(phase/12)^2,400-10*combo,700+20*combo}) -- E5+
        playSample('square',{57+phase,1-(phase/12)^2,400-10*combo,700+20*combo}) -- A5+
    end
end,__metatable=true})
gameSoundFunc.chain=gameSoundFunc.combo
gameSoundFunc.swap=gameSoundFunc.rotate
gameSoundFunc.swap_failed=gameSoundFunc.tuck
gameSoundFunc.twist=gameSoundFunc.rotate
gameSoundFunc.twist_failed=gameSoundFunc.tuck
gameSoundFunc.move_back=gameSoundFunc.rotate_failed

local interiorModeMeta={
    __call=function(self)
        local success,errInfo=pcall(GAME.getMode,self.name)
        if success then
            SCN.go('game_in','none',self.name)
        else
            MSG.new('warn',Text.noMode:repD(tostring(self.name):simplifyPath(),errInfo))
        end
    end
}
function playInterior(name)
    return setmetatable({name=name},interiorModeMeta)
end

local exteriorModeMeta={
    __call=function(self)
        local success,errInfo=pcall(GAME.getMode,self.name)
        if success then
            SCN.go('game_out','fade',self.name)
        else
            MSG.new('warn',Text.noMode:repD(tostring(self.name):simplifyPath(),errInfo))
        end
    end
}
function playExterior(name)
    return setmetatable({name=name},exteriorModeMeta)
end

function canPause()
    return GAME.playing and not GAME.mode.name:find('/test')
end

local function task_interiorAutoBack()
    local time=love.timer.getTime()
    local startScene=SCN.cur
    repeat
        if SCN.cur~=startScene then return end
        coroutine.yield()
    until love.timer.getTime()-time>1.26
    SCN.back('none')
end
function autoBack_interior(disable)
    TASK.removeTask_code(task_interiorAutoBack)
    if not disable then
        TASK.new(task_interiorAutoBack)
    end
end

local function _saveSettings()
    TASK.yieldT(.626)
    FILE.save({
        system=SETTINGS._system,
        game_brik=SETTINGS.game_brik,
        game_gela=SETTINGS.game_gela,
        game_acry=SETTINGS.game_acry,
    },'conf/settings','-json')
    if PROGRESS.get('main')>=3 then
        showSaveIcon(CHAR.icon.settings..CHAR.icon.save)
    end
end
function saveSettings()
    TASK.removeTask_code(_saveSettings)
    TASK.new(_saveSettings)
end
function saveKey()
    FILE.save({
        brik=KEYMAP.brik:export(),
        gela=KEYMAP.gela:export(),
        acry=KEYMAP.acry:export(),
        sys=KEYMAP.sys:export(),
    },'conf/keymap','-json')
    showSaveIcon(CHAR.icon.settings..CHAR.icon.save)
end
function saveTouch()
    FILE.save(VCTRL.exportSettings(),'conf/touch','-json')
    showSaveIcon(CHAR.icon.settings..CHAR.icon.save)
end
function showSaveIcon(str)
    TEXT:add{text=str,x=SCR.w0-15,y=SCR.h0+5,align='bottomright',a=.0626,duration=.62,fontSize=70}
end

function backText()
    return CHAR.icon.back_chevron..' '..Text.button_back
end

function callDict(entry)
    SCN.go('dictionary','none',entry)
end

function task_unloadGame()
    coroutine.yield()
    TASK.yieldUntilNextScene()
    GAME.unload()
    collectgarbage()
end

getTouches=love.touch.getTouches
isMouseDown=love.mouse.isDown
isKeyDown=love.keyboard.isDown
local isKeyDown=isKeyDown
function isCtrlPressed() return isKeyDown('lctrl','rctrl') end
function isShiftPressed() return isKeyDown('lshift','rshift') end
function isAltPressed() return isKeyDown('lalt','ralt') end

local function _getActMode(mode,key)
    local act=KEYMAP[mode]:getAction(key)
    if act then
        return mode,act
    else
        return 'sys',KEYMAP.sys:getAction(key)
    end
end
local function _getActImg(mode,act)
    return IMG.actionIcons[mode][act]
end
function resetVirtualKeyMode(mode)
    VCTRL.reset()
    if not mode then return end

    for i=1,#VCTRL do
        local obj=VCTRL[i]
        if obj.type=='button' then
            local res,texture=pcall(_getActImg,_getActMode(mode,(obj.key)))
            obj:setTexture(res and texture)
        elseif obj.type=='stick2way' then
            for j,suffix in next,{'left','right'} do
                local res,texture=pcall(_getActImg,_getActMode(mode,'vj2'..suffix))
                obj:setTexture(j,res and texture)
            end
        elseif obj.type=='stick4way' then
            for j,suffix in next,{'down','left','up','right'} do
                local res,texture=pcall(_getActImg,_getActMode(mode,'vj4'..suffix))
                obj:setTexture(j,res and texture)
            end
        end
    end
end
function updateWidgetVisible(widgetList)
    if VCTRL.focus then
        widgetList.iconSize:setVisible(true)
        widgetList.button1:setVisible(VCTRL.focus.type=='button')
        widgetList.button2:setVisible(VCTRL.focus.type=='button')
        widgetList.stick2_1:setVisible(VCTRL.focus.type=='stick2way')
        widgetList.stick2_2:setVisible(VCTRL.focus.type=='stick2way')
        widgetList.stick4_1:setVisible(VCTRL.focus.type=='stick4way')
        widgetList.stick4_2:setVisible(VCTRL.focus.type=='stick4way')
    else
        widgetList.iconSize:setVisible(false)
        widgetList.button1:setVisible(false)
        widgetList.button2:setVisible(false)
        widgetList.stick2_1:setVisible(false)
        widgetList.stick2_2:setVisible(false)
        widgetList.stick4_1:setVisible(false)
        widgetList.stick4_2:setVisible(false)
    end
end

local sandBoxEnv={
    math=math,
    string=string,
    table=table,
    coroutine=coroutine,
    assert=assert,error=error,
    tonumber=tonumber,tostring=tostring,
    select=select,next=next,
    ipairs=ipairs,pairs=pairs,
    type=type,
    pcall=pcall,xpcall=xpcall,
    rawget=rawget,rawset=rawset,rawlen=rawlen,rawequal=rawequal,
    setmetatable=setmetatable,
}
function setSafeEnv(func)
    sandBoxEnv.mechLib=mechLib -- Update in case it changes during game
    setfenv(func,TABLE.copyAll(sandBoxEnv))
end

regFuncToStr,regStrToFunc={},{}
---Flatten a table of functions into string-to-function and function-to-string maps
---@param obj table|function
---@param path string
function regFuncLib(obj,path)
    if type(obj)=='function' or type(obj)=='table' and rawget(obj,'__register') then
        regFuncToStr[obj]=path
        regStrToFunc[path]=obj
    elseif type(obj)=='table' then
        for k,v in next,obj do
            if k~='__index' then
                regFuncLib(v,path.."."..k)
            end
        end
    end
end

regFuncLib(gameSoundFunc,'gameSoundFunc')

love_logo=GC.load{w=128,h=128,
    {'clear',0,0,0,0},
    {'move',64,64},
    {'setCL',COLOR.D},
    {'fCirc',0,0,64},
    {'setCL',.9,.3,.6},
    {'fCirc',0,0,60},
    {'setCL',.16,.66,.88},
    {'fBow',0,0,60,0,3.141593},
    {'move',-4,4},
    {'setCL',COLOR.L},
    {'fRect',-20,-20,40,40},
    {'fCirc',0,-20,20},
    {'fCirc',20,0,20},
}

transition_image={w=128,h=1}
for x=0,127 do
    table.insert(transition_image,{'setCL',1,1,1,1-x/128})
    table.insert(transition_image,{'fRect',x,0,1,1})
end
transition_image=GC.load(transition_image)
