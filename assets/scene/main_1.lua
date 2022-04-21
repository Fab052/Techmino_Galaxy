local scene={}

function scene.enter()
    BG.set('image')
    BG.send('image',.12,IMG.cover)
    playBgm('blank','-base')
    BGM.set(bgmList['blank'].add,'volume',0,0)
end

function scene.keyDown(key,isRep)
    if isRep then return end
    if key=='return' then
        SCN.go('game_simp',nil,'sprint')
    end
end

scene.widgetList={
    WIDGET.new{type='button',pos={.3,.3},w=626,h=260,fontSize=100,text='[SPRINT]',          code=function()SCN.go('game_simp',nil,'sprint')end},
    WIDGET.new{type='button',pos={.7,.3},w=626,h=260,fontSize=80, text='[MARATHON]',        code=function()SCN.go('game_simp',nil,'marathon')end},
    WIDGET.new{type='button',pos={.5,.7},w=626,h=260,fontSize=100,text=LANG'main_1_setting',code=WIDGET.c_goScn('setting_1')},
    WIDGET.new{type='button',pos={1,1},x=-120,y=-80,w=160,h=80,sound='back',fontSize=50,text=CHAR.icon.cross_thick,code=WIDGET.c_backScn},
}
return scene
