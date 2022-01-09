----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
--
-- Version: see versionStr
-- requires MAVLink-OpenTx version: v31
--
-- Documentation:
--
-- Discussion:
-- https://www.rcgroups.com/forums/showthread.php?3532969-MAVLink-for-OpenTx-and-Telemetry-Script
--
-- Acknowledgements:
-- The design of the autopilot page is much inspired by the
-- Yaapu FrSky Telemetry script. THX!
-- https://github.com/yaapu/FrskyTelemetryScript
----------------------------------------------------------------------
local versionStr = "0.32.0 2022-01-09"


-- libraries: tplay, tutils, tobject, tvehicle, tautopilot, tgimbal, tcamera, taction, tdebug


----------------------------------------------------------------------
-- Widget Configuration
----------------------------------------------------------------------
-- Please feel free to set these configuration options as you desire

local config_g = {
    -- Set to true if you want to see the Action page, else set to false
    showActionPage = false, --true,
    
    -- Set to true if you want to see the Camera page, else set to false
    showCameraPage = true,
    
    -- Set to true if you want to see the Gimbal page, else set to false
    showGimbalPage = true,
    
    -- Set to a (toggle) source if you want control videoon/of & take photo with a switch,
    -- else set to ""
    cameraShootSwitch = "sh",
    
    -- Set to true if camera should be included in overall prearm check, else set to false
    cameraPrearmCheck = false,
    
    -- Set to a source if you want control the gimbal pitch, else set to ""
    gimbalPitchSlider = "rs",
    
    -- Set to the appropriate value if you want to start teh gimbal in a given targeting mode, 
    -- else set to nil
    -- 2: MAVLink Targeting, 3: RC Targeting, 4: GPS Point Targeting, 5: SysId Targeting
    gimbalDefaultTargetingMode = 3,
    
    -- Set to true if gimbal should be included in overall prearm check, else set to false
    gimbalPrearmCheck = false,
    
    -- Set to true if you use a gimbal and the ArduPilot flight stack,
    -- else set to false (e.g. if you use BetaPilot ;))
    -- only relevant if gimbalUseGimbalManager = false
    gimbalAdjustForArduPilotBug = false,
    
    -- Set to true for STorM32 gimbal protocol, else false for old gimbal protocol v1
    gimbalUseGimbalManager = true,

    -- Set to a source if you want control the gimbal yaw,
    -- else set to "", which also disables gimbal yaw control
    -- only relevant if gimbalUseGimbalManager = true
    gimbalYawSlider = "", --"ls",
    
    -- Set to true if you do not want to hear any voice, else set to false
    disableSound = false,
    
    -- not for you ;)
    disableEvents = false, -- not needed, just to have it safe
    
    -- Set to true if you want to see the Debug page, else set to false
    showDebugPage = true,
}


----------------------------------------------------------------------
-- general Widget Options
----------------------------------------------------------------------
-- NOT USED CURRENTLY, JUST DUMMY

local widgetOptions = {
    { "Switch",       SOURCE,  0 }, --getFieldInfo("sc").id },
    { "Baudrate",     VALUE,   57600, 115200, 115200 },
}
--widgetOptions[#widgetOptions+1] = {"menuSwitch", SOURCE, getFieldInfo("sc").id}


----------------------------------------------------------------------
-- Color Map
----------------------------------------------------------------------
local p = {
    WHITE =       lcd.RGB(0xFF,0xFF,0xFF),
    BLACK =       lcd.RGB(0,0,0),
    RED =         RED,        --RGB(229, 32, 30)
    DARKRED =     DARKRED,    --RGB(160, 0, 6)
    GREEN =       lcd.RGB(25,150,50),
    BLUE =        BLUE,       --RGB(0x30, 0xA0, 0xE0)
    YELLOW =      YELLOW,     --RGB(0xF0, 0xD0, 0x10)
    GREY =        GREY,       --RGB(96, 96, 96)
    DARKGREY =    DARKGREY,   --RGB(64, 64, 64)
    LIGHTGREY =   LIGHTGREY,  --RGB(180, 180, 180)
    SKYBLUE =     lcd.RGB(135,206,235),
    OLIVEDRAB =   lcd.RGB(107,142,35),
    YAAPUBROWN =  lcd.RGB(0x63,0x30,0x00),
    YAAPUBLUE =   lcd.RGB(0x08,0x54,0x88),
}    
p.HUD_SKY = p.SKYBLUE
p.HUD_EARTH = p.OLIVEDRAB
p.BACKGROUND = p.YAAPUBLUE
p.CAMERA_BACKGROUND = p.YAAPUBLUE
p.GIMBAL_BACKGROUND = p.YAAPUBLUE


----------------------------------------------------------------------
-- Events Map
----------------------------------------------------------------------
local event_t16 = {
  PAGE_PREVIOUS   = EVT_SYS_FIRST,
  PAGE_NEXT       = EVT_RTN_FIRST,
  BTN_A_LONG      = EVT_MODEL_LONG,
  BTN_A_REPT      = EVT_MODEL_REPT,
  BTN_B_LONG      = EVT_TELEM_LONG,
  BTN_B_REPT      = EVT_TELEM_REPT,
  BTN_ENTER_LONG  = EVT_ENTER_LONG,
  OPTION_PREVIOUS = EVT_VIRTUAL_DEC,
  OPTION_NEXT     = EVT_VIRTUAL_INC,
  OPTION_CANCEL   = EVT_RTN_FIRST,
}

local event_tx16s = {
  PAGE_PREVIOUS   = EVT_SYS_FIRST,
  PAGE_NEXT       = EVT_MODEL_FIRST,
  BTN_A_LONG      = EVT_RTN_LONG,
  BTN_A_REPT      = EVT_RTN_REPT,
  BTN_B_LONG      = EVT_TELEM_LONG,
  BTN_B_REPT      = EVT_TELEM_REPT,
  BTN_ENTER_LONG  = EVT_ENTER_LONG,
  OPTION_PREVIOUS = EVT_VIRTUAL_DEC,
  OPTION_NEXT     = EVT_VIRTUAL_INC,
  OPTION_CANCEL   = EVT_RTN_FIRST,
  
  TOUCH_PAGE_PREVIOUS = EVT_TOUCH_WIPE_RIGHT,
  TOUCH_PAGE_NEXT     = EVT_TOUCH_WIPE_LEFT,
  TOUCH_PAGE_DOWN     = EVT_TOUCH_WIPE_DOWN,
  TOUCH_PAGE_UP       = EVT_TOUCH_WIPE_UP,
}

local ver, flavor = getVersion()
local event_g = event_t16
local tx16color = false
if flavor == "tx16s" then 
    event_g = event_tx16s 
    tx16color = true
end


----------------------------------------------------------------------
-- Library Loader
----------------------------------------------------------------------
local sourcePath = "/WIDGETS/OlliwTel/"

local function loadLib(fname,...)
  local f = assert(loadScript(sourcePath..fname))
  collectgarbage()
  collectgarbage()
  return f(...)
end


----------------------------------------------------------------------
-- Touch & Events
----------------------------------------------------------------------
local event = 0
local touch = nil

local function touchEvent(e)
    if touch == nil then return false end
    if touch.extEvent == e then return true end
    return false
end

local function touchEventPressed(rect)
    if touch == nil then return false end
    if touch.event == EVT_TOUCH_DOWN and
       touch.x >= rect.x and touch.x <= rect.x + rect.w and 
       touch.y >= rect.y and touch.y <= rect.y + rect.h then return true end
    return false
end

local function touchEventTap(rect)
    if touch == nil then return false end
    if touch.extEvent == EVT_TOUCH_TAP and
       touch.x >= rect.x and touch.x <= rect.x + rect.w and 
       touch.y >= rect.y and touch.y <= rect.y + rect.h then return true end
    return false
end

local function touchIsNil()
    if touch == nil then return true end
    return false
end

local function touchClear()
    touch = nil
end

local function touchX()
    return touch.x
end

local function touchY()
    return touch.y
end


----------------------------------------------------------------------
-- Touch Object Library
----------------------------------------------------------------------
local ttouch = { 
   Event = touchEvent,
   EventPressed = touchEventPressed,
   EventTap = touchEventTap,
   isNil = touchIsNil,
   Clear = touchClear,
   x = touchX,
   y = touchY,
}   

local tobjstate, tobject, tbutton, tbuttonlong, tmenu = loadLib("tobject.lua", p, ttouch)


----------------------------------------------------------------------
-- Play Library
----------------------------------------------------------------------
local soundsPath = "/SOUNDS/OlliwTel/"

local function fplay(file)
    if not checkWidgetSetup() then return end
    if config_g.disableSound then return end
    playFile(soundsPath.."en/"..file..".wav")
end

local function fplayForce(file)
    if not checkWidgetSetup() then return end
    playFile(soundsPath.."en/"..file..".wav")
end

local play = loadLib("tplay.lua", fplay, fplayForce)


----------------------------------------------------------------------
-- Utils Library
----------------------------------------------------------------------
local utils = loadLib("tutils.lua")


----------------------------------------------------------------------
-- General
----------------------------------------------------------------------
config_g.showAutopilotPage = true

local page = {
    idx = 1,
    min = 1,
    max = 0,
    updown = 0, -- 0, 1, 2, 3
    
    IdAutopilot = 1,
    IdAction = 2,
    IdCamera = 3,
    IdGimbal = 4,
    IdDebug = 10
}    

local pages = {}
if config_g.showDebugPage then page.max = page.max+1; pages[page.max] = page.IdDebug end
if config_g.showActionPage then page.max = page.max+1; pages[page.max] = page.IdAction end
if config_g.showAutopilotPage then page.max = page.max+1; pages[page.max] = page.IdAutopilot; page.idx = page.max end
if config_g.showCameraPage then page.max = page.max+1; pages[page.max] = page.IdCamera end
if config_g.showGimbalPage then page.max = page.max+1; pages[page.max] = page.IdGimbal end


----------------------------------------------------------------------
-- Vehicle specific
----------------------------------------------------------------------
local 
  ap,
  getFlightModeStr,
  getFlightModeSound,
  playFlightModeSound,
  clearStatustext,
  getStatustextCount,
  addStatustext,
  printStatustext,
  printStatustextLast,
  printStatustextAt
  = loadLib("tvehicle.lua", p, fplay)

--so it is available in scope
local prearm_last_statustext = ""

local function prearmSetStatusText(txt)
    prearm_last_statustext = txt
end  

--so it is available in scope
local qshot_last_statustext = ""

local function qshotSetFromStatusText(txt)
    qshot_last_statustext = txt
end  


----------------------------------------------------------------------
-- Status Class
----------------------------------------------------------------------
local status_g = {
    mavtelemEnabled = nil, --allows to track changes
    receiving = nil, --allows to track changes
    flightmode = nil, --allows to track changes
    armed = false, --allows to track changes
    gpsstatus = nil, --allows to track changes
    posfix = nil, --allows to track changes
    
    haveposfix = false,
    
    flight_timer_start_10ms = 0,
    flight_time_10ms = 0,
    
    gimbal_receiving = nil,
    gimbal_changed_to_receiving = false,
    camera_receiving = nil,
    camera_changed_to_receiving = false,
}

-- this function is called always, also when there is no connection
local function checkStatusChanges()
    if status_g.mavtelemEnabled == nil or status_g.mavtelemEnabled ~= mavsdk.mavtelemIsEnabled() then
        status_g.mavtelemEnabled = mavsdk.mavtelemIsEnabled()
        if not mavsdk.mavtelemIsEnabled() then 
            status_g.recieving = nil
            status_g.armed = nil
            status_g.flightmode = nil
            status_g.posfix = nil
            status_g.gimbal_receiving = nil
            status_g.camera_receiving = nil
            play:MavTelemNotEnabled(); 
        end
    end
    if not mavsdk.mavtelemIsEnabled() then return end
    
    if status_g.recieving == nil or status_g.recieving ~= mavsdk.isReceiving() then -- first call or change
        if status_g.recieving == nil then -- first call
            if mavsdk.isReceiving() then play:TelemOk() else play:TelemNo() end
            clearStatustext()
        else -- change occured    
            if mavsdk.isReceiving() then 
                play:TelemRecovered()
                clearStatustext()
            else 
                play:TelemLost() 
            end
        end    
        status_g.recieving = mavsdk.isReceiving()
    end
  
    if status_g.armed == nil or status_g.armed ~= mavsdk.isArmed() then -- first call or change occured
        status_g.armed = mavsdk.isArmed()
        if status_g.armed then
            play:Armed()
            status_g.flight_timer_start_10ms = getTime() --if it was nil that's the best guess we can do
        else
            play:Disarmed()
        end    
    end
    if status_g.armed then
        status_g.flight_time_10ms = getTime() - status_g.flight_timer_start_10ms
    end    
    
    if status_g.flightmode == nil or status_g.flightmode ~= mavsdk.getFlightMode() then -- first call or change
        status_g.flightmode = mavsdk.getFlightMode()
        if mavsdk.isReceiving() then playFlightModeSound() end
    end
    
    if status_g.posfix == nil or status_g.posfix ~= status_g.haveposfix then -- first call or change
        status_g.posfix = status_g.haveposfix
        if status_g.haveposfix then play:PositionFix() end
    end
    
    status_g.gimbal_changed_to_receiving = false
    if status_g.gimbal_receiving == nil or status_g.gimbal_receiving ~= mavsdk.gimbalIsReceiving() then
        status_g.gimbal_receiving = mavsdk.gimbalIsReceiving()
        if mavsdk.gimbalIsReceiving() then status_g.gimbal_changed_to_receiving = true end
    end  
    
    status_g.camera_changed_to_receiving = false
    if status_g.camera_receiving == nil or status_g.camera_receiving ~= mavsdk.cameraIsReceiving() then
        status_g.camera_receiving = mavsdk.cameraIsReceiving()
        if mavsdk.cameraIsReceiving() then status_g.camera_changed_to_receiving = true end
    end
    
end


----------------------------------------------------------------------
-- General Drawers
----------------------------------------------------------------------
local draw = {
    xsize = 480, -- LCD_W
    ysize = 272, -- LCD_H
    xmid = 480/2,
    ymid = 272/2,
}

function draw:WarningBox(warningStr)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawFilledRectangle(draw.xmid-160-2, 74, 320+4, 84, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawFilledRectangle(draw.xmid-160, 76, 320, 80, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(draw.xmid, 85, warningStr, CUSTOM_COLOR+DBLSIZE+CENTER)
end


local function drawNoTelemetry()
    if not mavsdk.mavtelemIsEnabled() then
        draw:WarningBox("telemetry disabled")
    elseif not mavsdk.isReceiving() then
        draw:WarningBox("no telemetry data")
    end
end


local function drawIsInitializing()
    if mavsdk.isReceiving() and not mavsdk.isInitialized() then
        draw:WarningBox("is initializing")
    end
end


-- this is common to all pages
local function drawStatusBar()
    local x
    local y = -1
    lcd.setColor(CUSTOM_COLOR, p.BLACK)  
    lcd.drawFilledRectangle(0, 0, LCD_W, 19, CUSTOM_COLOR)
    -- Pager
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawLine(20, 2, 20, 17, SOLID, CUSTOM_COLOR)
    lcd.drawLine(LCD_W-21, 2, LCD_W-21, 17, SOLID, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    if page.idx > page.min then
        lcd.drawText(3, y-5, "<", CUSTOM_COLOR+MIDSIZE)
    end  
    if page.idx < page.max then
        lcd.drawText(LCD_W-2, y-5, ">", CUSTOM_COLOR+MIDSIZE+RIGHT)
    end  
    if page.updown > 0 then --0, 1, 2, 3
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawLine(40, 2, 40, 17, SOLID, CUSTOM_COLOR)
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        if page.updown == 1 or page.updown == 3 then 
            lcd.drawLine(24, 8, 30, 2, SOLID, CUSTOM_COLOR)
            lcd.drawLine(30, 2, 36, 8, SOLID, CUSTOM_COLOR)
        end
        if page.updown == 2 or page.updown == 3 then 
            lcd.drawLine(24, 11, 30, 17, SOLID, CUSTOM_COLOR)
            lcd.drawLine(30, 17, 36, 11, SOLID, CUSTOM_COLOR)
        end
    end  
    -- Vehicle type, model info
    local vehicleClassStr = utils:getVehicleClassStr()
    x = 26
    if page.updown > 0 then x = 46 end
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if tx16color then lcd.setColor(CUSTOM_COLOR, p.LIGHTGREY) end -- GRRR????
    if vehicleClassStr ~= nil then
        lcd.drawText(x, y, vehicleClassStr..":"..model.getInfo().name, CUSTOM_COLOR)
    else
        lcd.drawText(x, y, model.getInfo().name, CUSTOM_COLOR)
    end    
    -- RSSI & LQ
    x = 235
    if mavsdk.isReceiving() then
        local rssi = mavsdk.getRadioRssi()
        if rssi == nil then rssi = 0 end
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        if rssi < 50 then lcd.setColor(CUSTOM_COLOR, p.RED) end    
        lcd.drawText(x, y, "RS:", CUSTOM_COLOR)
        lcd.drawText(x + 42 -15, y, rssi, CUSTOM_COLOR+LEFT) --CENTER)  
        
        local radiostatus = mavsdk.getRadioStatus()
        if radiostatus ~= nil then 
            local LQ = radiostatus.rssi - radiostatus.noise
            local remLQ = radiostatus.remrssi - radiostatus.remnoise
            if remLQ < LQ then LQ = remLQ end
            lcd.setColor(CUSTOM_COLOR, p.GREEN)
            if LQ < 30 then lcd.setColor(CUSTOM_COLOR, p.RED) end  
            lcd.drawText(x+66, y, "LQ:", CUSTOM_COLOR)
            lcd.drawText(x+66 + 42 -15, y, LQ, CUSTOM_COLOR+LEFT) --CENTER)
        else    
            lcd.setColor(CUSTOM_COLOR, p.RED)    
            lcd.drawText(x+66, y, "LQ:--", CUSTOM_COLOR)
        end  
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)    
        lcd.drawText(x, y, "RS:--", CUSTOM_COLOR+BLINK)
        lcd.drawText(x+66, y, "LQ:--", CUSTOM_COLOR)
    end  
    -- TX voltage
    x = 394 --310
    local txvoltage = string.format("Tx:%.1fv", getValue(getFieldInfo("tx-voltage").id))
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if tx16color then lcd.setColor(CUSTOM_COLOR, p.LIGHTGREY) end -- GRRR????
    lcd.drawText(x, y, txvoltage, CUSTOM_COLOR)
    -- Time
--[[    
    x = LCD_W - 26
    local time = getDateTime()
    local timestr = string.format("%02d:%02d:%02d", time.hour, time.min, time.sec)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if tx16color then lcd.setColor(CUSTOM_COLOR, p.LIGHTGREY) end -- GRRR????
    lcd.drawText(x, y, timestr, CUSTOM_COLOR+RIGHT)  --SMLSIZE => 4
]]    
end


----------------------------------------------------------------------
-- Page Autopilot
----------------------------------------------------------------------
local apdraw = loadLib("tautopilot.lua", p, utils)

local function drawStatusBar2At(y)
    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawFilledRectangle(0, y, 480, draw.ysize-y, CUSTOM_COLOR)
    -- Flight mode
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    local flightModeStr = getFlightModeStr()
    if flightModeStr ~= nil then
        lcd.drawText(1, y-2, flightModeStr, CUSTOM_COLOR+DBLSIZE+LEFT)
    end
    -- Position Fix
    local haveposfix = true
    -- expecting 7 Sats would be quite ok in my area
    if mavsdk.getGpsFix() < mavlink.GPS_FIX_TYPE_3D_FIX then haveposfix = false end
    if mavsdk.getGpsSat() < 7 then haveposfix = false end
--    if mavsdk.getGpsHDop() > 1.5 then haveposfix = false end
    if mavsdk.isGps2Available() then 
        if mavsdk.getGps2Fix() < mavlink.GPS_FIX_TYPE_3D_FIX then haveposfix = false end
        if mavsdk.getGps2Sat() < 7 then haveposfix = false end
--        if mavsdk.getGps2HDop() > 1.5 then haveposfix = false end
    end  
    if not mavsdk.apPositionOk() then haveposfix = false end
    if haveposfix then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawText(draw.xmid, y-2, "POS FIX", CUSTOM_COLOR+DBLSIZE+CENTER)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(draw.xmid, y-2, "No FIX", CUSTOM_COLOR+DBLSIZE+CENTER)
    end  
    status_g.haveposfix = haveposfix -- to handle changes
    -- Flight time
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    local timeStr = utils:TimeToStr(status_g.flight_time_10ms/100)
    lcd.drawText(draw.xsize-3, y-2, timeStr, CUSTOM_COLOR+DBLSIZE+RIGHT)
end      

local function drawStatusTextAt(cnt, x,y)
    for i=1,cnt do
        printStatustextAt(i, cnt, x, y+(i-1)*13, SMLSIZE)
    end    
end

----------------------------------------------------------------------
-- you are welcome to modify this function to adapt the screen layout as you want it to be :)
----------------------------------------------------------------------
local function drawAutopilotPage()
    -- draw Hud
    apdraw:HudAt(draw.xmid, 22, 146)
    
    -- draw GPS status
    if not mavsdk.isGps2Available() then 
        apdraw:GpsStatusAt(1, 2,30, 5); -- 1 = Gps1
    else
        apdraw:GpsStatusAt(1, 2,13, 0); -- 1 = Gps1
        apdraw:GpsStatusAt(2, 2,73, 0); -- 2 = Gps2
    end    
    
    -- draw Tx GPS status (if you have one)
    if mavsdk.txGpsIsAvailable() then 
        if mavsdk.isGps2Available() then 
            apdraw:GpsStatusAt(0, 2,135, 0) -- 0 = txGps
        else 
            apdraw:GpsStatusAt(0, 2,115, 0) -- 0 = txGps
        end  
    end
    
    -- draw speeds
    if not mavsdk.txGpsIsAvailable() then
        if mavsdk.isGps2Available() then 
            apdraw:SpeedsAt(2,147) 
        else
            apdraw:SpeedsAt(2,115)
        end
    end    
    
    -- draw GPS coordinates in DMS format
    if not mavsdk.isGps2Available() then 
        apdraw:GpsCoordsAt(1, 2,165) -- 1 = Gps1
    end    
    
    -- draw Battery status
    apdraw:BatteryVoltageAt(draw.xsize, 30)
    apdraw:BatteryCurrentAt(draw.xsize, 65)
    apdraw:BatteryRemainingAt(draw.xsize, 100)
    apdraw:BatteryChargeAt(draw.xsize, 135)
      
    -- draw Arming status
    apdraw:ArmingStatusAt(draw.xmid, 174)
    
    -- draw some more status stuff (has black background color)
    drawStatusBar2At(200)
    
    -- draw some statustext at the bottom (has black background color)
    drawStatusTextAt(3, 5,230) -- 3 = three lines
end  

local function drawAllStatusTextMessages()
    local cnt = getStatustextCount()
    for i=1,cnt do
        printStatustextAt(i, cnt, 10, 30+(i-1)*19, 0)
    end    
    if cnt == 0 then 
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawText(10, 30, "no statustext messages", CUSTOM_COLOR)
    end
end

local function drawPrearm()
    local sensors = mavsdk.getSystemStatusSensors()
    if sensors == nil then
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(draw.xmid, 20-4, "PREARM  FAIL", CUSTOM_COLOR+DBLSIZE+CENTER)
        return
    end    
    
    local xmid = draw.xmid
    local autopilot_ok = true
    local camera_ok = false
    local gimbal_ok = false
    
    local x = 10;
    local y = 60;
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, "Autopilot", CUSTOM_COLOR+MIDSIZE)
    lcd.drawText(x+20, y+25, "checks:", CUSTOM_COLOR+MIDSIZE)
    if bit32.btest(sensors.present, mavlink.SYS_STATUS_PREARM_CHECK) then
        if bit32.btest(sensors.enabled, mavlink.SYS_STATUS_PREARM_CHECK) then
            if bit32.btest(sensors.health, mavlink.SYS_STATUS_PREARM_CHECK) then
                lcd.setColor(CUSTOM_COLOR, p.GREEN)
                lcd.drawText(x+20+105, y+25, "OK", CUSTOM_COLOR+MIDSIZE)
            else    
                lcd.setColor(CUSTOM_COLOR, p.RED)
                lcd.drawText(x+20+105, y+25, "fail", CUSTOM_COLOR+MIDSIZE)    
                autopilot_ok = false
                lcd.drawText(10, 60+25 + 35, string.sub(prearm_last_statustext,9), CUSTOM_COLOR+SMLSIZE)
            end
        else
            lcd.drawText(x+20+105, y+25, "disabled", CUSTOM_COLOR+MIDSIZE)
        end    
    else
        lcd.drawText(x+20+105, y+25, "-", CUSTOM_COLOR+MIDSIZE)
    end
  
    y = 155
    x = 10
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, "Camera", CUSTOM_COLOR+MIDSIZE)
    lcd.drawText(x+20, y+25, "receiving:", CUSTOM_COLOR+MIDSIZE)    
    if mavsdk.isReceiving() and mavsdk.cameraIsReceiving() then    
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawText(x+20+130, y+25, "OK", CUSTOM_COLOR+MIDSIZE)
        camera_ok = true
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(x+20+130, y+25, "fail", CUSTOM_COLOR+MIDSIZE)    
    end
    
    y = 155
    x = xmid+20
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, "Gimbal", CUSTOM_COLOR+MIDSIZE)
    lcd.drawText(x+20, y+25, "receiving:", CUSTOM_COLOR+MIDSIZE)    
    lcd.drawText(x+20, y+50, "checks:", CUSTOM_COLOR+MIDSIZE)    
    lcd.drawText(x+20, y+75, "armed:", CUSTOM_COLOR+MIDSIZE)
    if mavsdk.isReceiving() and mavsdk.gimbalIsReceiving() then    
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawText(x+20+130, y+25, "OK", CUSTOM_COLOR+MIDSIZE)    
        if mavsdk.gimbalGetStatus().prearm_ok then
            lcd.setColor(CUSTOM_COLOR, p.GREEN)
            lcd.drawText(x+20+130, y+50, "OK", CUSTOM_COLOR+MIDSIZE)    
        else
            lcd.setColor(CUSTOM_COLOR, p.RED)
            lcd.drawText(x+20+130, y+50, "fail", CUSTOM_COLOR+MIDSIZE)    
        end  
        if mavsdk.gimbalGetStatus().is_armed then
            lcd.setColor(CUSTOM_COLOR, p.GREEN)
            lcd.drawText(x+20+130, y+75, "OK", CUSTOM_COLOR+MIDSIZE)    
        else
            lcd.setColor(CUSTOM_COLOR, p.RED)
            lcd.drawText(x+20+130, y+75, "fail", CUSTOM_COLOR+MIDSIZE)    
        end  
        if mavsdk.gimbalGetStatus().prearm_ok and mavsdk.gimbalGetStatus().is_armed then 
            gimbal_ok = true
        end    
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(x+20+130, y+25, "fail", CUSTOM_COLOR+MIDSIZE)    
        lcd.drawText(x+20+130, y+50, "fail", CUSTOM_COLOR+MIDSIZE)    
        lcd.drawText(x+20+130, y+75, "fail", CUSTOM_COLOR+MIDSIZE)    
    end
    
    if not config_g.cameraPrearmCheck then camera_ok = true end
    if not config_g.gimbalPrearmCheck then gimbal_ok = true end
    if autopilot_ok and camera_ok and gimbal_ok then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawText(draw.xmid, 20-4, "PREARM  OK", CUSTOM_COLOR+DBLSIZE+CENTER)
    else  
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(draw.xmid, 20-4, "PREARM  FAIL", CUSTOM_COLOR+DBLSIZE+CENTER)
    end
end

local function autopilotDoAlways()
    if mavsdk.isStatusTextAvailable() then
        local sev, txt = mavsdk.getStatusText()
        
        --test if qshot statustext
        if string.find(txt,"QSHOT") == 1 then
          qshotSetFromStatusText(txt)
          return
        end
        
        --test if prearm statustext
        if string.find(txt,"PreArm:") == 1 then
          prearmSetStatusText(txt)
        end
        
        addStatustext(txt,sev)
    end     
end        

local autopilot_showstatustext = false
local autopilot_showprearm = false
local autopilot_showstatustext_tmo_10ms = 0
local autopilot_showprearm_tmo_10ms = 0

local function doPageAutopilot()
    if page.updown == 0 then -- page had been changed
        autopilot_showstatustext = false
        autopilot_showprearm = false
        autopilot_showstatustext_tmo_10ms = 0
        autopilot_showprearm_tmo_10ms = 0
    end  
    local tnow = getTime()
    if event == event_g.BTN_B_LONG or event == event_g.BTN_B_REPT then 
        autopilot_showstatustext = true
        autopilot_showstatustext_tmo_10ms = tnow
    end
    if event == event_g.BTN_A_LONG or event == event_g.BTN_A_REPT then 
        autopilot_showprearm = true
        autopilot_showprearm_tmo_10ms = tnow 
    end
    if autopilot_showstatustext_tmo_10ms > 0 and (tnow - autopilot_showstatustext_tmo_10ms) > 50 then 
        autopilot_showstatustext = false
        autopilot_showstatustext_tmo_10ms = 0
        return
    end    
    if autopilot_showprearm_tmo_10ms > 0 and (tnow - autopilot_showprearm_tmo_10ms) > 50 then 
        autopilot_showprearm = false
        autopilot_showprearm_tmo_10ms = 0
        return
    end
    if autopilot_showstatustext then
        if touchEvent(event_g.TOUCH_PAGE_DOWN) then 
            autopilot_showstatustext = false 
            touch = nil -- clear it so it is not eaten also by showprearm check
        end
    else  
        if touchEvent(event_g.TOUCH_PAGE_UP) and not autopilot_showprearm then 
            autopilot_showstatustext = true 
            touch = nil -- clear it so it is not eaten also by showprearm check
        end
    end  
    if autopilot_showprearm then
        if touchEvent(event_g.TOUCH_PAGE_UP) then autopilot_showprearm = false end
    else  
        if touchEvent(event_g.TOUCH_PAGE_DOWN) and not autopilot_showstatustext then
            autopilot_showprearm = true 
        end
    end  
    if autopilot_showstatustext then
        page.updown = 1
        drawAllStatusTextMessages()
        return
    end
    if autopilot_showprearm then
        page.updown = 2
        drawPrearm()
        return
    end
    
    page.updown = 3

    drawAutopilotPage()
    drawIsInitializing()
end  


----------------------------------------------------------------------
-- Page Camera
----------------------------------------------------------------------
local camera, cameraDoAlways, doPageCamera

if config_g.showCameraPage then
    camera,
    cameraDoAlways,
    doPageCamera
    = loadLib("tcamera.lua", config_g, status_g, p, draw, play, utils, ttouch, tobjstate, tobject, tmenu)
end


----------------------------------------------------------------------
-- Page Gimbal
----------------------------------------------------------------------
local gimbalDoAlways, doPageGimbal

if config_g.showGimbalPage then
    gimbalDoAlways,
    doPageGimbal
    = loadLib("tgimbal.lua", config_g, status_g, p, draw, play, tmenu)
end    


----------------------------------------------------------------------
-- Page Action
----------------------------------------------------------------------
local action, follow, actionDoAlways, doPageAction

if config_g.showActionPage then
    action, follow,
    actionDoAlways,
    doPageAction
    = loadLib("taction.lua", status_g, p, draw, play, utils, tobject, tbutton, tbuttonlong, tmenu, ap)
end


----------------------------------------------------------------------
-- Page Debug
----------------------------------------------------------------------
local doPageDebug

if config_g.showDebugPage then
    doPageDebug = loadLib("tdebug.lua", p, utils)
end


----------------------------------------------------------------------
-- InMenu, FullSize Pages
----------------------------------------------------------------------

local function doPageInMenu()
    lcd.setColor(CUSTOM_COLOR, p.BACKGROUND)
    lcd.clear(CUSTOM_COLOR)
    event = 0
    drawStatusBar()
    doPageAutopilot()
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawFilledRectangle(88-25, 74+50, 304+50, 84+6, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    lcd.drawFilledRectangle(90-25, 76+50, 300+50, 80+6, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(LCD_W/2, 85+50, "OlliW Telemetry Script", CUSTOM_COLOR+DBLSIZE+CENTER)
    lcd.drawText(LCD_W/2, 125+50, "Version "..versionStr, CUSTOM_COLOR+MIDSIZE+CENTER)
end

local function doPageNeedsFullSize(rect)
    event = 0
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawFilledRectangle(rect.x+10, rect.y+10, rect.w-20, rect.h-20, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawFilledRectangle(rect.x+12, rect.y+12, rect.w-24, rect.h-24, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(rect.x+15, rect.y+15, "OlliW Telemetry Script", CUSTOM_COLOR)
    local opt = CUSTOM_COLOR
    if rect.h < 100 then opt = CUSTOM_COLOR+SMLSIZE end
    lcd.drawText(rect.x+15, rect.y+40, "REQUIRES FULL SCREEN", opt)
    lcd.drawText(rect.x+15, rect.y+65, "Please change widget", opt)
    lcd.drawText(rect.x+15, rect.y+85, "screen selection", opt)
end

local function doPageMainViewsCountToSmall(rect)
    event = 0
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawFilledRectangle(rect.x+10, rect.y+10, rect.w-20, rect.h-20, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawFilledRectangle(rect.x+12, rect.y+12, rect.w-24, rect.h-24, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(rect.x+15, rect.y+15, "OlliW Telemetry Script", CUSTOM_COLOR)
    local opt = CUSTOM_COLOR
    if rect.h < 100 then opt = CUSTOM_COLOR+SMLSIZE end
    lcd.drawText(rect.x+15, rect.y+40, "NOT FOR MAIN VIEW 1", opt)
    lcd.drawText(rect.x+15, rect.y+65, "Please add a", opt)
    lcd.drawText(rect.x+15, rect.y+85, "main view", opt)
end


----------------------------------------------------------------------
-- Wrapper
----------------------------------------------------------------------
local playIntroSound = true

local function doAlways(bkgrd)
    --mavsdk.radioDisableRssiVoice(1)
    mavsdk.radioDisableRssiVoice(true)
    --mavsdk.radioDisableRssiVoice(false)
  
    if playIntroSound then    
        playIntroSound = false
        play:Intro()
    end  

    checkStatusChanges()
    
    if config_g.showAutopilotPage then autopilotDoAlways() end
    if config_g.showCameraPage then cameraDoAlways() end
    if config_g.showGimbalPage then gimbalDoAlways() end
    if config_g.showActionPage then actionDoAlways() end
end


----------------------------------------------------------------------
-- Widget Main entry function, create(), update(), background(), refresh()
----------------------------------------------------------------------

local function widgetCreate(rect, options)
    local w = { rect = rect }
    return w
end

local function widgetUpdate(widget, options)
end

local function widgetBackground(widget)
    doAlways(1)
end

local te_last = 0;
local params_do_register = false

local function widgetRefresh(widget, events)
    if widget.rect.h < 250 then 
        doPageNeedsFullSize(widget.rect)
        return
    end
    local check = checkWidgetSetup()
    if bit32.btest(check,2) then
        doPageMainViewsCountToSmall(widget.rect)
        return
    end
    if bit32.btest(check,1) then
        doPageInMenu()
        return
    end
    lcd.resetBacklightTimeout()
    
    -- EVT_ENTER_xxx, EVT_TELEM_xx, EVT_MODEL_xxx, EVT_SYS_xxx, EVT_RTN_xxx
    -- EVT_VIRTUAL_DEC, EVT_VIRTUAL_INC
    if not config_g.disableEvents and events ~= nil then
        lockKeys(KEY_ENTER + KEY_MODEL + KEY_TELEM + KEY_SYS + KEY_RTN)
        event = events.event
        touch = events.touch
    else
        event = 0
        touch = nil
    end    

    mavlink.enableIn(1)
    --mavlink.enableOut(1) --implictely called with first sendMessage()
    --mvsdk.optionSetSendPosition(true)

    if not params_do_register then
        params_do_register = true
        if camera ~= nil then camera.param_registered = false end
        if follow ~= nil then follow.param_registered = false end
        mavlink.clearParamRegister()
    end

    doAlways(0)
    
    if pages[page.idx] == page.IdAutopilot then
        lcd.setColor(CUSTOM_COLOR, p.BACKGROUND)
    elseif pages[page.idx] == page.IdCamera then   
        lcd.setColor(CUSTOM_COLOR, p.CAMERA_BACKGROUND)
    elseif pages[page.idx] == page.IdGimbal then   
        lcd.setColor(CUSTOM_COLOR, p.GIMBAL_BACKGROUND)
    else    
        lcd.setColor(CUSTOM_COLOR, p.BACKGROUND)
    end  
    lcd.clear(CUSTOM_COLOR)
    
    drawStatusBar()

    if pages[page.idx] == page.IdAutopilot then
        doPageAutopilot()
    elseif pages[page.idx] == page.IdCamera then   
        doPageCamera()
    elseif pages[page.idx] == page.IdGimbal then   
        doPageGimbal()
    elseif pages[page.idx] == page.IdAction then
        doPageAction()
    elseif pages[page.idx] == page.IdDebug then
        doPageDebug()
    end  
  
    -- do this post so that the pages can overwrite RTN & SYS use
    if event == event_g.PAGE_NEXT or touchEvent(event_g.TOUCH_PAGE_NEXT) then
        page.idx = page.idx + 1
        if page.idx > page.max then page.idx = page.max else page.updown = 0 end
    elseif event == event_g.PAGE_PREVIOUS or touchEvent(event_g.TOUCH_PAGE_PREVIOUS) then
        page.idx = page.idx - 1
        if page.idx < page.min then page.idx = page.min else page.updown = 0 end
    end
    
    if pages[page.idx] ~= page.IdDebug then
      drawNoTelemetry()
    end    
    
    -- y = 256 is the smallest for normal sized text ??? really ???, no, if there is undersling
    -- normal font is 13 pix height => 243, 256
    if pages[page.idx] == page.IdAutopilot and getStatustextCount() < 3 then
        lcd.setColor(CUSTOM_COLOR, p.GREY)
        lcd.drawText(LCD_W/2, 256, "OlliW Telemetry Script  "..versionStr.."  fw "..mavsdk.getVersion(), CUSTOM_COLOR+SMLSIZE+CENTER)
    end    
end


return { 
    name="OlliwTel", 
    options=widgetOptions, 
    create=widgetCreate, update=widgetUpdate, background=widgetBackground, refresh=widgetRefresh 
}


