----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
----------------------------------------------------------------------
-- Page Debug
----------------------------------------------------------------------
local p, utils = ...


----------------------------------------------------------------------
-- Interface
----------------------------------------------------------------------

local function doPageDebug()
    local x = 10;
    local y = 20;
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
  
    local txgps = getTxGPS()
    
    if txgps.fix then 
        lcd.drawText(x, y, 'FIX', CUSTOM_COLOR)
    else  
        lcd.drawText(x, y, 'no FIX', CUSTOM_COLOR)
    end  
    lcd.drawNumber(x, y+20, txgps.numsat, CUSTOM_COLOR)
    lcd.drawNumber(x, y+40, txgps.hdop, CUSTOM_COLOR+PREC2)
    
    y = 90
    lcd.drawNumber(x, y, txgps.lat*1e7, CUSTOM_COLOR)
    lcd.drawNumber(x, y+20, txgps.lon*1e7, CUSTOM_COLOR)
    
    lcd.drawText(x+150, y, utils:LatLonToDms(txgps.lat), CUSTOM_COLOR)
    lcd.drawText(x+150, y+20, utils:LatLonToDms(txgps.lon,txgps.lat), CUSTOM_COLOR)

    lcd.drawText(x, y+40, "alt (m)", CUSTOM_COLOR)  
    lcd.drawNumber(x+150, y+40, txgps.alt, CUSTOM_COLOR)

    y = 160
    lcd.drawText(x, y, "speed (m/s)", CUSTOM_COLOR)  
    lcd.drawNumber(x+150, y, txgps.speed, CUSTOM_COLOR+PREC2)
    lcd.drawText(x, y+20, "speed (km/h)", CUSTOM_COLOR)  
    lcd.drawNumber(x+150, y+20, 3.6*txgps.speed, CUSTOM_COLOR+PREC2)
    lcd.drawText(x, y+40, "heading (deg)", CUSTOM_COLOR)  
    lcd.drawNumber(x+150, y+40, txgps.heading, CUSTOM_COLOR+PREC1)
  
    local txgps2 = mavsdk.getTxGps()
    y = 20
    lcd.drawNumber(x+250, y, txgps2.fix, CUSTOM_COLOR)
    lcd.drawNumber(x+250, y+40, txgps2.hdop, CUSTOM_COLOR+PREC2)
    lcd.drawNumber(x+320, y+40, txgps2.vdop, CUSTOM_COLOR+PREC2)
  
--[[ 
  
    local mem = mavlink.getMemUsed()
    local stack = mavlink.getStackUsed()
    local tasks = mavlink.getTaskStats()
  
    local x = 10;
    local y = 20;
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, "Mem", CUSTOM_COLOR)
    lcd.drawText(x, y+20, "scripts:", CUSTOM_COLOR)
    lcd.drawText(x, y+40, "widgets:", CUSTOM_COLOR)
    lcd.drawText(x, y+60, "extra:", CUSTOM_COLOR)
    lcd.drawText(x, y+80, "total:", CUSTOM_COLOR)
    lcd.drawText(x, y+100, "heap used:", CUSTOM_COLOR)
    lcd.drawText(x, y+120, "heap free:", CUSTOM_COLOR)
     
    lcd.drawNumber(x+100, y+20, mem.scripts, CUSTOM_COLOR)
    lcd.drawNumber(x+100, y+40, mem.widgets, CUSTOM_COLOR)
    lcd.drawNumber(x+100, y+60, mem.extra, CUSTOM_COLOR)
    lcd.drawNumber(x+100, y+80, mem.total, CUSTOM_COLOR)
    lcd.drawNumber(x+100, y+100, mem.heap_used, CUSTOM_COLOR)
    lcd.drawNumber(x+100, y+120, mem.heap_free, CUSTOM_COLOR)
    
    x = 220;
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, "Stack", CUSTOM_COLOR)
    lcd.drawText(x, y+20, "main:", CUSTOM_COLOR)
    lcd.drawText(x, y+40, "menus:", CUSTOM_COLOR)
    lcd.drawText(x, y+60, "mixer:", CUSTOM_COLOR)
    lcd.drawText(x, y+80, "audio:", CUSTOM_COLOR)
    lcd.drawText(x, y+100, "mavlink:", CUSTOM_COLOR)
    
    lcd.drawNumber(x+80, y+20, stack.main_available, CUSTOM_COLOR)
    lcd.drawNumber(x+80, y+40, stack.menus_available, CUSTOM_COLOR)
    lcd.drawNumber(x+80, y+60, stack.mixer_available, CUSTOM_COLOR)
    lcd.drawNumber(x+80, y+80, stack.audio_available, CUSTOM_COLOR)
    lcd.drawNumber(x+80, y+100, stack.mavlink_available, CUSTOM_COLOR)
    
    lcd.drawNumber(x+140, y+20, stack.main_size, CUSTOM_COLOR)
    lcd.drawNumber(x+140, y+40, stack.menus_size, CUSTOM_COLOR)
    lcd.drawNumber(x+140, y+60, stack.mixer_size, CUSTOM_COLOR)
    lcd.drawNumber(x+140, y+80, stack.audio_size, CUSTOM_COLOR)
    lcd.drawNumber(x+140, y+100, stack.mavlink_size, CUSTOM_COLOR)
    
    x = 220;
    y = 175;
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, "Task", CUSTOM_COLOR)
    lcd.drawText(x, y+20, "time:", CUSTOM_COLOR)
    lcd.drawText(x, y+40, "max:", CUSTOM_COLOR)
    lcd.drawText(x, y+60, "loop:", CUSTOM_COLOR)
    
    lcd.drawNumber(x+80, y+20, tasks.time, CUSTOM_COLOR)
    lcd.drawNumber(x+80, y+40, tasks.max, CUSTOM_COLOR)
    lcd.drawNumber(x+80, y+60, tasks.loop, CUSTOM_COLOR)
    
    x = 10;
    y = 180;
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x+20, y+20, "msg id cnt:", CUSTOM_COLOR)
    lcd.drawNumber(x+120, y+20, mavlink.getInCount(), CUSTOM_COLOR)
    
    -- this demonstrates how to use the mavlink api
    mavlink.enableIn(1) -- we just have to do it once, but hey...
    mavlink.enableOut(1) -- we just have to do it once, but hey...
    -- these are all possible ways to call it, don't all do the same though ;)
    -- attitude = mavlink.getMessage(mavlink.M_ATTITUDE);
    -- attitude = mavlink.getMessage(mavlink.M_ATTITUDE, 44, 1);
    -- attitude = mavlink.getMessage(mavlink.M_ATTITUDE, mavlink.getSystemId());
    -- attitude = mavlink.getMessage(mavlink.M_ATTITUDE, mavlink.getSystemId(), 0);
    -- attitude = mavlink.getMessage(mavlink.M_ATTITUDE, 0, mavlink.getAutopilotComponentIds );
    -- attitude = mavlink.getMessage(mavlink.M_ATTITUDE, mavlink.getSystemId(), mavlink.getAutopilotComponentIds );
    attitude = mavlink.getMessage(mavlink.M_ATTITUDE, mavlink.getAutopilotIds());
    if attitude ~= nil then
        lcd.drawNumber(x+20, y+40, attitude.sysid, CUSTOM_COLOR)
        lcd.drawNumber(x+20, y+60, attitude.yaw*100.0, CUSTOM_COLOR+PREC2)
        
        if attitude.updated then
            -- in principle we should first check isFree() before we send, 
            -- but for this simple example it doesn't matter
            local res = mavlink.sendMessage(attitude)
            if res == nil then
                lcd.drawText(x+100, y+60, "!", CUSTOM_COLOR)
            else
                lcd.drawText(x+100, y+60, "*", CUSTOM_COLOR)
            end
        end
        
    else
        lcd.drawNumber(x+20, y+40, 0.0, CUSTOM_COLOR)
    end
]]    
end


return 
    doPageDebug
