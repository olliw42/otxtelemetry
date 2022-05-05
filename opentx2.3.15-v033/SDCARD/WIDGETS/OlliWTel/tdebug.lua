----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
----------------------------------------------------------------------
-- Page Debug
----------------------------------------------------------------------
local p, utils, apdraw = ...


----------------------------------------------------------------------
-- Interface
----------------------------------------------------------------------

local function doPageDebug()
    local x, y;
    local LStats = mbridge.getLinkStats()
    
    x = 255;
    y = 25;
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x-72, y, "rx LQ", CUSTOM_COLOR)  
    lcd.drawNumber(x, y-6, LStats.rx_LQ, CUSTOM_COLOR+MIDSIZE+CENTER)
    
    y = 90 --110
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawRectangle(60, y, 100, 50, CUSTOM_COLOR+SOLID)    
    lcd.drawRectangle(61, y+1, 98, 48, CUSTOM_COLOR+SOLID)    
    lcd.drawRectangle(300, y, 100, 50, CUSTOM_COLOR+SOLID)    
    lcd.drawRectangle(301, y+1, 98, 48, CUSTOM_COLOR+SOLID)    
    lcd.drawLine(177, y+25-10, 280, y+25-10, SOLID, CUSTOM_COLOR)
    lcd.drawLine(177, y+25-9, 280, y+25-9, SOLID, CUSTOM_COLOR)
    lcd.drawLine(177, y+25-11, 280, y+25-11, SOLID, CUSTOM_COLOR)
    lcd.drawLine(180, y+25+10, 283, y+25+10, SOLID, CUSTOM_COLOR)
    lcd.drawLine(180, y+25+11, 283, y+25+11, SOLID, CUSTOM_COLOR)
    lcd.drawLine(180, y+25+9, 283, y+25+9, SOLID, CUSTOM_COLOR)
    lcd.drawFilledTriangle(280+5, y+25-10, 280,y+25-10-5, 280,y+25-10+5, CUSTOM_COLOR+SOLID)
    lcd.drawFilledTriangle(180-5, y+25+10, 180,y+25+10-5, 180,y+25+10+5, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    
    x = 60;
    y = y - 45;
    lcd.drawText(x, y, "rssi", CUSTOM_COLOR)  
    if LStats.receive_antenna == 0 then
        lcd.drawNumber(x+60, y, LStats.rssi1_inst, CUSTOM_COLOR)
    else
        lcd.drawNumber(x+60, y, LStats.rssi2_inst, CUSTOM_COLOR)
    end
    lcd.drawText(x, y+20, "LQ ser", CUSTOM_COLOR)  
    lcd.drawNumber(x+60, y+20, LStats.LQ, CUSTOM_COLOR)
    
    if LStats.transmit_antenna == 0 then
        lcd.drawText(x+75, y+50, "a1", CUSTOM_COLOR)  
    else    
        lcd.drawText(x+75, y+50, "a2", CUSTOM_COLOR)  
    end    
    if LStats.receive_antenna == 0 then
        lcd.drawText(x+75, y+70, "a1", CUSTOM_COLOR)  
    else    
        lcd.drawText(x+75, y+70, "a2", CUSTOM_COLOR)  
    end    
    
    x = 300;
    lcd.drawText(x, y, "rx rssi", CUSTOM_COLOR)  
    lcd.drawNumber(x+80, y, LStats.rx_rssi_inst, CUSTOM_COLOR)
    lcd.drawText(x, y+20, "rx LQ ser", CUSTOM_COLOR)  
    lcd.drawNumber(x+80, y+20, LStats.rx_LQ_serial, CUSTOM_COLOR)
    
    if LStats.rx_receive_antenna == 0 then
        lcd.drawText(x+5, y+50, "a1", CUSTOM_COLOR)  
    else    
        lcd.drawText(x+5, y+50, "a2", CUSTOM_COLOR)  
    end    
    if LStats.rx_transmit_antenna == 0 then
        lcd.drawText(x+5, y+70, "a1", CUSTOM_COLOR)  
    else    
        lcd.drawText(x+5, y+70, "a2", CUSTOM_COLOR)  
    end    
    
    local t_retry = (100 - LStats.LQ_serial_transmitted)/2
    local r_retry = (LStats.LQ_valid_received - LStats.LQ_serial_received)/2
    
    x = 186;
    y = y + 35;
    lcd.drawText(x, y, "Bps", CUSTOM_COLOR)  
    lcd.drawNumber(x+55, y, LStats.byte_rate_transmitted*41, CUSTOM_COLOR) -- transmit BW
    --lcd.drawText(x, y-20, "retry", CUSTOM_COLOR)  
    --lcd.drawNumber(x+55, y-20, t_retry, CUSTOM_COLOR)
    y = y + 50;
    lcd.drawText(x, y, "Bps", CUSTOM_COLOR)  
    lcd.drawNumber(x+55, y, LStats.byte_rate_received*41, CUSTOM_COLOR) -- receive BW
    --lcd.drawText(x, y+20, "retry", CUSTOM_COLOR)  
    --lcd.drawNumber(x+55, y+20, r_retry, CUSTOM_COLOR)
  
    -- RSI spektrum graph
    local LRssi = mbridge.getRssiLists()
    if LRssi == nil then return end
    
    x = 70
    y = 260
    lcd.setColor(CUSTOM_COLOR, p.LIGHTGREY)
    lcd.drawLine(x - 10, y, x + 23*15 + 10, y, SOLID, CUSTOM_COLOR)
    lcd.drawLine(x - 10, y - (110 - 90), x + 23*15 + 10, y - (110 - 90), SOLID, CUSTOM_COLOR)
    lcd.drawLine(x - 10, y - (110 - 50), x + 23*15 + 10, y - (110 - 50), SOLID, CUSTOM_COLOR)
    lcd.drawText(x-35, y-10, "-110", CUSTOM_COLOR+SMLSIZE)
    lcd.drawText(x-35, y-10-20, "-90", CUSTOM_COLOR+SMLSIZE)
    lcd.drawText(x-35, y-10-60, "-50", CUSTOM_COLOR+SMLSIZE)
    
    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    for i = 0,LRssi.fhss_cnt-1 do
      local r = LRssi.rssi1[i]
      if r > 120 then 
        lcd.drawFilledRectangle(x + i*15 - 1, y - 1, 3, 5, CUSTOM_COLOR+SOLID)
      else
        if r > -40 then r = -40 end
        r = 110 + r 
        lcd.drawLine(x + i*15, y, x + i*15, y - r, SOLID, CUSTOM_COLOR)
      end  
    end      
    
    lcd.setColor(CUSTOM_COLOR, p.RED)
    for i = 0,LRssi.fhss_cnt-1 do
      local r = LRssi.rssi2[i]
      if r > 120 then 
        lcd.drawFilledRectangle(x+3 + i*15 - 1, y - 1, 3, 5, CUSTOM_COLOR+SOLID)
      else 
        if r > -40 then r = -40 end
        r = 110 + r 
        lcd.drawLine(x+3 + i*15, y, x+3 + i*15, y - r, SOLID, CUSTOM_COLOR)
      end  
    end

--[[    
    for i = 0,LRssi.fhss_cnt-1 do
      if LRssi.rx_antenna[i] == 0 then
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
      else
        lcd.setColor(CUSTOM_COLOR, p.RED)
      end 
      local r = LRssi.rx_rssi[i]
      if r > 120 then 
        lcd.drawFilledRectangle(x + i*15 - 1, y - 1, 3, 5, CUSTOM_COLOR+SOLID)
      else 
        if r > -40 then r = -40 end
        r = 110 + r 
        lcd.drawLine(x + i*15, y, x + i*15, y - r, SOLID, CUSTOM_COLOR)
      end  
    end      
]]  
  
--[[  
    x = 40;
    y = 180;
    lcd.drawText(x, y, "LQ serial", CUSTOM_COLOR)  
    lcd.drawNumber(x+80, y, LStats.LQ_serial_received, CUSTOM_COLOR)
    lcd.drawText(x, y+20, "LQ valid", CUSTOM_COLOR)  
    lcd.drawNumber(x+80, y+20, LStats.LQ_valid_received, CUSTOM_COLOR)
    lcd.drawText(x, y+40, "LQ rec", CUSTOM_COLOR)  
    lcd.drawNumber(x+80, y+40, LStats.LQ_frames_received, CUSTOM_COLOR)
    
    local pitch = mavsdk.getAttPitchDeg()
    local roll = mavsdk.getAttRollDeg()
  
    local minY = 180
    local maxY = 180 + 60
    local minX = 300
    local maxX = 300 + 100

    lcd.setColor(CUSTOM_COLOR, p.HUD_SKY)
    lcd.drawFilledRectangle(minX, minY, maxX-minX, maxY-minY, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.HUD_EARTH)
    lcd.drawHudRectangle(pitch, roll, minX, maxX, minY, maxY, CUSTOM_COLOR)
]]    
    
--[[  
    local ox, oy
    local cx, cy
    if roll == 0 or math.abs(roll) == 180 then
        ox = (minX+maxX)/2
        oy = (minY+maxY)/2 + pitch * 1.85
        cx = 0
        cy = 21
    else
        ox = (minX+maxX)/2 + math.sin(math.rad(roll)) * pitch
        oy = (minY+maxY)/2 + math.cos(math.rad(roll)) * pitch * 1.85
        cx = -math.sin(math.rad(roll)) * 21
        cy = math.cos(math.rad(roll)) * 21
    end

    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    for i = 1,8 do
        apdraw:TiltedLineWithClipping(
            ox - i*cx, oy + i*cy,
            -roll,
            (i % 2 == 0 and 40 or 20), minX + 2, maxX - 2, minY + 10, maxY - 2,
            DOTTED, CUSTOM_COLOR)
        apdraw:TiltedLineWithClipping(
            ox + i*cx, oy - i*cy,
            -roll,
            (i % 2 == 0 and 40 or 20), minX + 2, maxX - 2, minY + 10, maxY - 2,
            DOTTED, CUSTOM_COLOR)
    end

    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawFilledRectangle((minX+maxX)/2-15, (minY+maxY)/2, 30, 2, CUSTOM_COLOR)
]]  
  
--[[  
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
]]  
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
