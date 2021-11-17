----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
----------------------------------------------------------------------
-- Page Autopilot
----------------------------------------------------------------------
local p, utils = ...


local apdraw = {}

 
----------------------------------------------------------------------
-- draw helpers
----------------------------------------------------------------------

function apdraw:TiltedLineWithClipping(ox, oy, angle, len, xmin, xmax, ymin, ymax, style, color)
    local xx = math.cos(math.rad(angle)) * len * 0.5
    local yy = math.sin(math.rad(angle)) * len * 0.5
    local x0 = ox - xx
    local x1 = ox + xx
    local y0 = oy - yy
    local y1 = oy + yy    
    lcd.drawLineWithClipping(x0, y0, x1, y1, xmin, xmax, ymin, ymax, style, color)
end


local hudCompassTicks = {"N",nil,"NE",nil,"E",nil,"SE",nil,"S",nil,"SW",nil,"W",nil,"NW",nil}


function apdraw:HudFrameAt(x,y,h)
    local pitch = mavsdk.getAttPitchDeg()
    local roll = mavsdk.getAttRollDeg()
  
    local minY = y --draw.hudY --22
    local maxY = y + h --draw.hudY + draw.hudHeight --22+146 = 168
    local minX = x - 120 --120
    local maxX = x + 120 --360

    --https://www.rapidtables.com/web/color/RGB_Color.html
    --corn flower blue 	#6495ED 	(100,149,237)
    --sky blue 	#87CEEB 	(135,206,235)
    lcd.setColor(CUSTOM_COLOR, p.HUD_SKY)
    
    lcd.drawFilledRectangle(minX, minY, maxX-minX, maxY-minY, CUSTOM_COLOR+SOLID)
    --lcd.setColor(CUSTOM_COLOR, lcd.RGB(0x63, 0x30, 0x00))
    --olive drab 	#6B8E23 	(107,142,35)
    --lcd.setColor(CUSTOM_COLOR, lcd.RGB(107,142,35))
    lcd.setColor(CUSTOM_COLOR, p.HUD_EARTH)
    
    -- this code part is partially from Yaapu FrSky Telemetry Script, thx!
    lcd.drawHudRectangle(pitch, roll, minX, maxX, minY, maxY, CUSTOM_COLOR)
    
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
            (i % 2 == 0 and 80 or 40), minX + 2, maxX - 2, minY + 10, maxY - 2,
            DOTTED, CUSTOM_COLOR)
        apdraw:TiltedLineWithClipping(
            ox + i*cx, oy - i*cy,
            -roll,
            (i % 2 == 0 and 80 or 40), minX + 2, maxX - 2, minY + 10, maxY - 2,
            DOTTED, CUSTOM_COLOR)
    end
    
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawFilledRectangle((minX+maxX)/2-25, (minY+maxY)/2, 50, 2, CUSTOM_COLOR)
end


function apdraw:HudCompassRibbonAt(x,y)
    local heading = mavsdk.getAttYawDeg() --getVfrHeadingDeg()
    -- compass ribbon
    -- this piece of code is based on Yaapu FrSky Telemetry Script, much improved
    local minX = x - 110 -- make it smaller than hud by at least one char size
    local maxX = x + 110 
    local tickNo = 3 --number of ticks on one side
    local stepWidth = (maxX - minX -24)/(2*tickNo)
    local closestHeading = math.floor(heading/22.5) * 22.5
    local closestHeadingX = x + (closestHeading - heading)/22.5 * stepWidth
    local tickIdx = (closestHeading/22.5 - tickNo) % 16
    local tickX = closestHeadingX - tickNo*stepWidth   
    for i = 1,12 do
        if tickX >= minX and tickX < maxX then
            if hudCompassTicks[tickIdx+1] == nil then
                lcd.setColor(CUSTOM_COLOR, p.BLACK)
                lcd.drawLine(tickX, y, tickX, y+10, SOLID, CUSTOM_COLOR)
            else
                lcd.setColor(CUSTOM_COLOR, p.BLACK)
                lcd.drawText(tickX, y-3, hudCompassTicks[tickIdx+1], CUSTOM_COLOR+CENTER)
            end
        end
        tickIdx = (tickIdx + 1) % 16
        tickX = tickX + stepWidth
    end
    -- compass heading text box
    if heading < 0 then heading = heading + 360 end
    local w = 60 -- 3 digits width
    if heading < 10 then
        w = 20
    elseif heading < 100 then
        w = 40
    end
    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawFilledRectangle(x - (w/2), y, w, 28, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawNumber(x, y-6, heading, CUSTOM_COLOR+DBLSIZE+CENTER)
end


function apdraw:HudGroundSpeedAt(x,y)
    local groundSpeed = mavsdk.getVfrGroundSpeed()
    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawText(x, y-17+2, "SPD", CUSTOM_COLOR+SMLSIZE)
    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawFilledRectangle(x, y, 70, 28, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.GREEN)
    if (math.abs(groundSpeed) >= 10) then
        lcd.drawNumber(x+2, y-5, groundSpeed, CUSTOM_COLOR+DBLSIZE+LEFT)
    else
        lcd.drawNumber(x+2, y-5, groundSpeed*10, CUSTOM_COLOR+DBLSIZE+LEFT+PREC1)
    end
end


function apdraw:HudAltitudeAt(x,y)
    local altitude = mavsdk.getPositionAltitudeRelative() --getVfrAltitudeMsl()
    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawText(x, y-17+2, "ALT", CUSTOM_COLOR+SMLSIZE+RIGHT)
    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawFilledRectangle(x - 70, y, 70, 28, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.GREEN)
    if math.abs(altitude) > 99 or altitude < -99 then
        lcd.drawNumber(x-2, y, altitude, CUSTOM_COLOR+MIDSIZE+RIGHT)
    elseif math.abs(altitude) >= 10 then
        lcd.drawNumber(x-2, y-5, altitude, CUSTOM_COLOR+DBLSIZE+RIGHT)
    else
        lcd.drawNumber(x-2, y-5, altitude*10, CUSTOM_COLOR+DBLSIZE+RIGHT+PREC1)
    end
end    


function apdraw:HudVerticalSpeedAt(x,y)
    local verticalSpeed = mavsdk.getVfrClimbRate()
    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawFilledRectangle(x-30, y, 60, 20, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)  
    local w = 3
    if math.abs(verticalSpeed) > 999 then w = 4 end
    if verticalSpeed < 0 then w = w + 1 end
    lcd.drawNumber(x, y-4, verticalSpeed*10, CUSTOM_COLOR+MIDSIZE+CENTER+PREC1)
end


----------------------------------------------------------------------
-- "OSD" Element Drawer
----------------------------------------------------------------------

function apdraw:HudAt(x,y,h)
    apdraw:HudFrameAt(x, y, h)
    apdraw:HudCompassRibbonAt(x, y)
    apdraw:HudGroundSpeedAt(x - 120, y+58)
    apdraw:HudAltitudeAt(x + 120, y+58)
    apdraw:HudVerticalSpeedAt(x, y+h-20)
end    


-- gpsId 0: tx gps, 1: gps1, 2: gps2
function apdraw:GpsStatusAt(gpsId, x,y, dy)
    local gpsfix, gpssat, hdop
    local txtsize1 = MIDSIZE
    local txtsize2 = DBLSIZE
    if gpsId == 1 then
        gpsfix = mavsdk.getGpsFix()
        gpssat = mavsdk.getGpsSat()
        hdop = mavsdk.getGpsHDop()
    elseif gpsId == 2 then
        gpsfix = mavsdk.getGps2Fix()
        gpssat = mavsdk.getGps2Sat()
        hdop = mavsdk.getGps2HDop()
    elseif gpsId == 0 then -- local tx gps
        local gps = getTxGPS()
        if gps.fix then gpsfix = mavlink.GPS_FIX_TYPE_3D_FIX else gpsfix = 0 end -- is boolean 
        gpssat = gps.numsat
        hdop = gps.hdop*0.01 -- 5.0 == 500
        txtsize1 = 0; txtsize2 = 0
    else
        return
    end  
    -- GPS fix
    if gpsfix >= mavlink.GPS_FIX_TYPE_3D_FIX then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
    end
    if gpsId > 0 then
        lcd.drawText(x, y+8, utils:getGpsFixStr(gpsId), CUSTOM_COLOR+txtsize1+LEFT) --MIDSIZE+LEFT)
    else
        local fixstr = "No FIX"
        if gpsfix >= mavlink.GPS_FIX_TYPE_3D_FIX then
            if mavsdk.txGpsHasPosIntFix() then fixstr = "POS FIX" else fixstr = "3D FIX" end
        end    
        lcd.drawText(x, y+8, fixstr, CUSTOM_COLOR+txtsize1+LEFT) --MIDSIZE+LEFT)
    end
    -- Sat
    if gpssat > 99 then gpssat = 0 end
    if gpssat > 5 and gpsfix >= mavlink.GPS_FIX_TYPE_3D_FIX then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
    end
    lcd.drawNumber(x+3, y+30+dy, gpssat, CUSTOM_COLOR+txtsize2) --DBLSIZE)
    -- HDop
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if hdop >= 10 then
        if hdop > 99 then hdop = 99 end
        lcd.drawNumber(x+53, y+30+dy, hdop, CUSTOM_COLOR+txtsize2) --DBLSIZE)
    else  
        lcd.drawNumber(x+53, y+30+dy, hdop*10, CUSTOM_COLOR+txtsize2+PREC1) --DBLSIZE+PREC1)
    end
end


-- sourceId 0: tx gps, 1: gps1, 2: gps2, 3: pos int
function apdraw:GpsCoordsAt(sourceId, x,y)
    local source, lat, lon
    if sourceId == 1 then
        source = mavsdk.getGpsLatLonInt()
        lat = source.lat*1e-7; lon = source.lon*1e-7
    elseif sourceId == 2 then
        source = mavsdk.getGps2LatLonInt()
        lat = source.lat*1e-7; lon = source.lon*1e-7
    elseif sourceId == 3 then
        source = mavsdk.getPositionLatLonInt()
        lat = source.lat*1e-7; lon = source.lon*1e-7
    elseif sourceId == 0 then
        source = getTxGPS()
        lat = source.lat*1e-6; lon = source.lon*1e-6
    end  
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, utils:LatLonToDms(lat), CUSTOM_COLOR)
    lcd.drawText(x, y+16, utils:LatLonToDms(lon,lat), CUSTOM_COLOR)
end


function apdraw:SpeedsAt(x,y)
    local groundSpeed = mavsdk.getVfrGroundSpeed()
    local airSpeed = mavsdk.getVfrAirSpeed()
    lcd.setColor(CUSTOM_COLOR, p.WHITE) 
    local gs = string.format("GS %.1f m/s", groundSpeed)
    lcd.drawText(x, y, gs, CUSTOM_COLOR)
    local as = string.format("AS %.1f m/s", airSpeed)
    lcd.drawText(x, y+24, as, CUSTOM_COLOR)
end


function apdraw:BatteryVoltageAt(x,y)
    local voltage = mavsdk.getBatVoltage()
    lcd.setColor(CUSTOM_COLOR, p.WHITE) 
    lcd.drawNumber(x-18, y, voltage*100, CUSTOM_COLOR+DBLSIZE+RIGHT+PREC2)
    lcd.drawText(x-2, y +14, "V", CUSTOM_COLOR+RIGHT)
end


function apdraw:BatteryCurrentAt(x,y)
    local current = mavsdk.getBatCurrent()
    if current ~= nil then
        lcd.setColor(CUSTOM_COLOR, p.WHITE) 
        lcd.drawNumber(x-18, y, current*10, CUSTOM_COLOR+DBLSIZE+RIGHT+PREC1)
        lcd.drawText(x-2, y+14, "A", CUSTOM_COLOR+RIGHT)
    end
end


function apdraw:BatteryRemainingAt(x,y)
    local remaining = mavsdk.getBatRemaining()
    if remaining ~= nil then
        lcd.setColor(CUSTOM_COLOR, p.WHITE) 
        lcd.drawNumber(x-18, y, remaining, CUSTOM_COLOR+DBLSIZE+RIGHT)
        lcd.drawText(x-2, y+14, "%", CUSTOM_COLOR+RIGHT)
    end
end    


function apdraw:BatteryChargeAt(x,y)
    local charge = mavsdk.getBatChargeConsumed()
    if charge ~= nil then
        lcd.setColor(CUSTOM_COLOR, p.WHITE) 
        lcd.drawNumber(x-40, y+7, charge, CUSTOM_COLOR+MIDSIZE+RIGHT)
        lcd.drawText(x-1, y+14, "mAh", CUSTOM_COLOR+RIGHT)
    end
end


function apdraw:ArmingStatusAt(x,y)
    if mavsdk.isArmed() then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawText(x, y, "ARMED", CUSTOM_COLOR+MIDSIZE+CENTER)
    else    
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        lcd.drawText(x, y, "DISARMED", CUSTOM_COLOR+MIDSIZE+CENTER)
    end    
end


return apdraw