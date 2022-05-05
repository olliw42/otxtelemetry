----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
----------------------------------------------------------------------
-- Touch Objects Classes
----------------------------------------------------------------------
local p, ttouch = ...


local tobject_has_focus = false

local tobjstate = {}

tobjstate.isFocusable = function()
    if tobject_has_focus then return false end
    return true
end    


-- tObject

local tobject = {}

tobject.visible = function(object,flag)
    object.visible = flag
end

tobject.enable = function(object,flag)
    object.enabled = flag
end

tobject.init = function(object,flag)
    if not object.initialized then
        object.initialized = true
        object.enabled = true
        if flag then object.visible = flag else object.visible = true
        end
    end
end


-- tButton

local tbutton = {}

tbutton.draw = function(button)
    if not button.visible then return end
    local r = button.rect
    lcd.setColor(CUSTOM_COLOR, p.BLUE)
    lcd.drawFilledRectangle(r.x, r.y, r.w, r.h, CUSTOM_COLOR+SOLID)
    if button.enabled then lcd.setColor(CUSTOM_COLOR, p.WHITE) else lcd.setColor(CUSTOM_COLOR, p.GREY) end    
    lcd.drawText(r.x + r.w/2, r.y + 3, button.txt, CUSTOM_COLOR+MIDSIZE+CENTER)
    if button.enabled and ttouch.EventPressed(r) then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawRectangle(r.x, r.y, r.w, r.h, CUSTOM_COLOR+SOLID)
        lcd.drawRectangle(r.x+1, r.y+1, r.w-2, r.h-2, CUSTOM_COLOR+SOLID)
    end
end

tbutton.handle = function(button)
    if not button.visible then return end
    if not button.enabled then return end
    if tobject_has_focus then return end
    if ttouch.EventTap(button.rect) then button.click_func(button) end
end  

tbutton.init = function(button, flag)
    if not button.initialized then
        tobject.init(button, flag)
    end    
end


-- tButtonLong

local tbuttonlong = {}

tbuttonlong.draw = function(button)
--    tbutton.draw(button)
    if not button.visible then return end
    local r = button.rect
    lcd.setColor(CUSTOM_COLOR, p.BLUE)
    lcd.drawFilledRectangle(r.x, r.y, r.w, r.h, CUSTOM_COLOR+SOLID)
    if button.enabled then lcd.setColor(CUSTOM_COLOR, p.WHITE) else lcd.setColor(CUSTOM_COLOR, p.GREY) end
    if button.case_func ~= nil and button.case_func() == 2 then
        lcd.drawText(r.x + r.w/2, r.y + 3, button.txt2, CUSTOM_COLOR+MIDSIZE+CENTER)
    else
        lcd.drawText(r.x + r.w/2, r.y + 3, button.txt, CUSTOM_COLOR+MIDSIZE+CENTER)
    end
    --if button.enabled and touchEventPressed(r) then
    if button.enabled and button.pressed then  
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawRectangle(r.x, r.y, r.w, r.h, CUSTOM_COLOR+SOLID)
        lcd.drawRectangle(r.x+1, r.y+1, r.w-2, r.h-2, CUSTOM_COLOR+SOLID)
        if button.clicked then 
          lcd.drawRectangle(r.x+2, r.y+2, r.w-4, r.h-4, CUSTOM_COLOR+SOLID)
          lcd.drawRectangle(r.x+3, r.y+3, r.w-6, r.h-6, CUSTOM_COLOR+SOLID)
        end
    end
end  

tbuttonlong.handle = function(button)
    if not button.visible or not button.enabled or tobject_has_focus then
        button.press_start = nil; 
        return false
    end
    if ttouch.EventTap(button.rect) or ttouch.EventPressed(button.rect) then 
        button.pressed = true
        if button.press_start == nil then 
            button.press_start = getTime() 
            if button.press_func ~= nil then button.press_func() end
        end
        if (getTime() - button.press_start) > button.press_time and not button.clicked then 
            button.clicked = true
            button.click_func()
        end
        return true
    end
    button.pressed = false
    button.press_start = nil
    button.clicked = false
    return false
end  

tbuttonlong.init = function(button)
    if not button.initialized then
        tbutton.init(button)
        button.pressed = false
        button.clicked = false
        button.press_start = nil
        button.press_time = 150
    end    
end


-- tMenu

local tmenu = {}

tmenu.popup_rect = function(menu)
  return {x = menu.px, y = menu.py, w = menu.w, h = menu.ph} 
end
  
tmenu.popup_touch = function(menu)
    if ttouch.isNil() then return end
    for i = menu.min, menu.max do
        if ttouch.y() > menu.py + menu.h*(i-1) and ttouch.y() < menu.py + menu.h*i then
            menu.m_idx = i
            return
        end
    end  
end

tmenu.popup_draw = function(menu)
    local size = MIDSIZE
    if menu.popup_text_size ~= nil then size = menu.popup_text_size end
    lcd.setColor(CUSTOM_COLOR, p.BLUE)
    lcd.drawFilledRectangle(menu.px, menu.py, menu.w, menu.ph, CUSTOM_COLOR+SOLID)
    if menu.idx >= menu.min and menu.idx <= menu.max then 
      lcd.setColor(CUSTOM_COLOR, p.GREEN)
      lcd.drawFilledRectangle(menu.px, menu.py + menu.h*(menu.m_idx-1), menu.w, menu.h, CUSTOM_COLOR+SOLID)
    end  
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawRectangle(menu.px, menu.py, menu.w, menu.ph, CUSTOM_COLOR+SOLID)
    local pxmid = menu.px + menu.w/2
    for i = menu.min, menu.max do
        lcd.drawText(pxmid, menu.py + 3 + menu.h*(i-1), menu.option[i], CUSTOM_COLOR+size+CENTER)
    end    
end

tmenu.draw = function(menu)
    if not menu.visible then return end
    local r = menu.rect
    lcd.setColor(CUSTOM_COLOR, p.BLUE)
    lcd.drawFilledRectangle(r.x, r.y, r.w, r.h, CUSTOM_COLOR+SOLID)
    if menu.enabled then lcd.setColor(CUSTOM_COLOR, p.WHITE) else lcd.setColor(CUSTOM_COLOR, p.GREY) end    
    if menu.idx >= menu.min and menu.idx <= menu.max then 
        lcd.drawText(r.x + r.w/2, r.y + 3, menu.option[menu.idx], CUSTOM_COLOR+MIDSIZE+CENTER)
    end    
    if menu.active then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawRectangle(r.x, r.y, r.w, r.h, CUSTOM_COLOR+SOLID)
        lcd.drawRectangle(r.x+1, r.y+1, r.w-2, r.h-2, CUSTOM_COLOR+SOLID)
        tmenu.popup_draw(menu)
    end
end

tmenu.handle = function(menu)
    if not menu.visible then return end
    if not menu.enabled then return end
    if not tobject_has_focus and not menu.active and ttouch.EventTap(menu.rect) then
        menu.active = true
        tobject_has_focus = true
        menu.m_idx = menu.idx
    elseif menu.active then
        if ttouch.EventTap(tmenu.popup_rect(menu)) then
            tmenu.popup_touch(menu)
            menu.active = false
            tobject_has_focus = false
            if menu.m_idx >= menu.min and menu.m_idx <= menu.max then 
                menu.idx = menu.m_idx
                menu.click_func(menu, menu.idx)
            end  
        elseif ttouch.Event(EVT_TOUCH_TAP) then
          ttouch.Clear()
          menu.active = false
          tobject_has_focus = false
        end
    end
end

tmenu.init = function(menu, flag)
    if not menu.initialized then
        tobject.init(menu, flag)
        menu.idx = menu.default
        menu.m_idx = menu.default
        menu.active = false
        menu.w = menu.rect.w
        menu.h = menu.rect.h
        if menu.popup_text_height ~= nil then
            menu.h = menu.popup_text_height
        end
        menu.ph = menu.h * (menu.max - menu.min + 1)
        menu.px = LCD_W/2 - menu.w/2
        menu.py = LCD_H/2 - menu.ph/2
    end
end



return tobjstate, tobject, tbutton, tbuttonlong, tmenu
--return { tobject = tobject, tbutton = tbutton, tbuttonlong = tbuttonlong }