----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
--
-- Version: see versionStr
-- requires MAVLink-OpenTx or MAVLink-EdgeTx version: v30
-- (script works for both OpenTx & EdgeTx)
--
-- Documentation:
--
-- Discussion:
--
-- Acknowledgements:
-- The design of the autopilot page is much inspired by the
-- Yaapu FrSky Telemetry script. THX!
-- https://github.com/yaapu/FrskyTelemetryScript
----------------------------------------------------------------------
local versionStr = "0.31.01 2021-11-14"


-- libraries: tobject.lua, tvehicle.lua


----------------------------------------------------------------------
-- Widget Configuration
----------------------------------------------------------------------
-- Please feel free to set these configuration options as you desire

local config_g = {
    -- Set to true if you want to see the Action page, else set to false
    showActionPage = true, --false,
    
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
    showDebugPage = false,
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
    WHITE = lcd.RGB(0xFF,0xFF,0xFF),
    BLACK = lcd.RGB(0,0,0),
    RED = RED,              --RED RGB(229, 32, 30)
    DARKRED = DARKRED,      --RGB(160, 0, 6)
    GREEN = lcd.RGB(25,150,50), --otx GREEN = RGB(25, 150, 50)
    BLUE = BLUE,            --RGB(0x30, 0xA0, 0xE0)
    YELLOW = YELLOW,        --RGB(0xF0, 0xD0, 0x10)
    GREY = GREY,            --RGB(96, 96, 96)
    DARKGREY = DARKGREY,    --RGB(64, 64, 64)
    LIGHTGREY = LIGHTGREY,  --RGB(180, 180, 180)
    SKYBLUE = lcd.RGB(135,206,235),
    OLIVEDRAB = lcd.RGB(107,142,35),
    YAAPUBROWN = lcd.RGB(0x63,0x30,0x00),
    YAAPUBLUE = lcd.RGB(0x08,0x54,0x88),
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
--  MAVLink Api Extension
----------------------------------------------------------------------

--[[
local function str2tab(s)
  local t = {}
  for i=1,string.len(s) do t[i] = string.byte(string.sub(s,i,i)) end
  return t
end

local function tab2str(t)
  local s = ""
  for i=1,#t do
    if t[i] and t[i] > 0 then s = s..string.char(t[i]) else break end
  end
  return s
end

local function ap_request_param(id)
    local ap_sysid, ap_compid = mavlink.getAutopilotIds()
    mavlink.sendMessage({
        msgid = mavlink.M_PARAM_REQUEST_READ,
        target_sysid = ap_sysid,
        target_compid = ap_compid,
        param_id = str2tab(id),
    })
end

local function ap_set_param(id,value)
    local ap_sysid, ap_compid = mavlink.getAutopilotIds()
    mavlink.sendMessage({
        msgid = mavlink.M_PARAM_SET,
        target_sysid = ap_sysid,
        target_compid = ap_compid,
        param_id = str2tab(id),
        param_value = value,
    })
end

local function cam_request_param(id)
    local cam_sysid, cam_compid = mavlink.getCameraIds()
    mavlink.sendMessage({
        msgid = mavlink.M_PARAM_REQUEST_READ,
        target_sysid = cam_sysid,
        target_compid = cam_compid,
        param_id = str2tab(id),
    })
end

local function cam_set_param(id,value)
    local cam_sysid, cam_compid = mavlink.getCameraIds()
    mavlink.sendMessage({
        msgid = mavlink.M_PARAM_SET,
        target_sysid = cam_sysid,
        target_compid = cam_compid,
        param_id = str2tab(id),
        param_value = mavlink.memcpyToNumber(value),
        param_type = mavlink.PARAM_TYPE_UINT32,
    })
end
]]


----------------------------------------------------------------------
-- Play Functions
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


--local play = loadLib("tobject.lua",fplay, fplayForce) ???? attempt to call method Intro, a nil value ???

local play = {}

function play:Intro() end --fplay("intro") end
function play:MavTelemNotEnabled() end --fplay("nomtel") end

function play:TelemOk() fplay("telok") end    
function play:TelemNo() fplay("telno") end    
function play:TelemRecovered() fplay("telrec") end
--local function playTelemRecovered() if not mavsdk.optionIsRssiEnabled() then fplay("telrec") end end
function play:TelemLost() fplay("tellost") end
--local function playTelemLost() if not mavsdk.optionIsRssiEnabled() then fplay("tellost") end end

function play:Armed() fplay("armed") end    
function play:Disarmed() fplay("disarmed") end    

function play:PositionFix() fplay("posfix") end    

function play:VideoMode() fplay("modvid") end    
function play:PhotoMode() fplay("modpho") end    
function play:ModeChangeFailed() fplay("modko") end    
function play:VideoOn() fplay("vidon") end    
function play:VideoOff() fplay("vidoff") end    
function play:TakePhoto() fplay("photo") end    

function play:Neutral() fplay("gneut") end
function play:RcTargeting() fplay("grctgt") end    
function play:MavlinkTargeting() fplay("gmavtgt") end
function play:GpsPointTargeting() fplay("ggpspnt") end
function play:SysIdTargeting() fplay("gsysid") end

function play:QShotDefault() fplay("xsdef") end
function play:QShotNeutral() fplay("xsneut") end
function play:QShotRcControl() fplay("xsrcctrl") end
function play:QShotPOI() fplay("xsroi") end
function play:QShotSysid() fplay("xssys") end
function play:QShotCableCam() fplay("xscable") end
function play:QShotTargetMe() fplay("xstme") end

function play:ThrottleWarning() fplayForce("wthr") end

function play:ThrottleTooLow() end
function play:ThrottleTooHigh() end
function play:TakeOff() fplay("takeoff") end    
function play:MagCalibrationStarted() fplay("mcalsrt") end
function play:MagCalibrationFinished() fplay("mcalend") end


----------------------------------------------------------------------
-- General
----------------------------------------------------------------------

local page = {
    autopilotEnabled = true,
    actionEnabled = config_g.showActionPage,
    cameraEnabled = config_g.showCameraPage,
    gimbalEnabled = config_g.showGimbalPage,
    debugEnabled = config_g.showDebugPage,
    
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
if page.debugEnabled then page.max = page.max+1; pages[page.max] = page.IdDebug end
if page.actionEnabled then page.max = page.max+1; pages[page.max] = page.IdAction end
if page.autopilotEnabled then page.max = page.max+1; pages[page.max] = page.IdAutopilot; page.idx = page.max end
if page.cameraEnabled then page.max = page.max+1; pages[page.max] = page.IdCamera end
if page.gimbalEnabled then page.max = page.max+1; pages[page.max] = page.IdGimbal end


local function timeToStr(time_s)
    local hours = math.floor(time_s/3600)
    local mins = math.floor(time_s/60 - hours*60)
    local secs = math.floor(time_s - hours*3600 - mins *60)
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end


----------------------------------------------------------------------
-- Vehicle specific
----------------------------------------------------------------------

local 
  getVehicleClassStr,
  getGimbalIdStr,
  getCameraIdStr,
  isCopter,
  isPlane,
  apCopterFlightMode,
  getFlightModeStr,
  getFlightModeSound,
  getGpsFixStr,
  getGps2FixStr,
  clearStatustext,
  getStatustextCount,
  addStatustext,
  printStatustext,
  printStatustextLast,
  printStatustextAt
  = loadLib("tvehicle.lua", p)

local function playFlightModeSound()
    local fmsound = getFlightModeSound()
    if fmsound == nil or fmsound == "" then return end
    fplay(fmsound)
end

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


-- see AP_Arming.h
local apPrearmChecks = {}
apPrearmChecks[0]   = { "All", 1 }
apPrearmChecks[1]   = { "Barometer", 2 }
apPrearmChecks[2]   = { "Compass", 4 }
apPrearmChecks[3]   = { "GPS Lock", 8 }
apPrearmChecks[4]   = { "INS", 16 }
apPrearmChecks[5]   = { "Parameters", 32 }
apPrearmChecks[6]   = { "RC Channels", 64 }
apPrearmChecks[7]   = { "Board Voltage", 128 }
apPrearmChecks[8]   = { "Battery Level", 256 }
apPrearmChecks[9]   = { "Airspeed", 512 }
apPrearmChecks[10]  = { "Logging", 1024 }
apPrearmChecks[11]  = { "Saftey Switch", 2048 }
apPrearmChecks[12]  = { "GPS Config", 4096 }
apPrearmChecks[13]  = { "System", 8192 }
apPrearmChecks[14]  = { "Mission", 16384 }
apPrearmChecks[15]  = { "Rangefinder", 32768 }
apPrearmChecks[16]  = { "Camera", 65536 }
apPrearmChecks[17]  = { "Aux Authent", 131072 }
apPrearmChecks[18]  = { "Vision", 262144 }
apPrearmChecks[19]  = { "FFT", 524288 }


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
-- Draw Helper
----------------------------------------------------------------------

local function drawTiltedLineWithClipping(ox, oy, angle, len, xmin, xmax, ymin, ymax, style, color)
    local xx = math.cos(math.rad(angle)) * len * 0.5
    local yy = math.sin(math.rad(angle)) * len * 0.5
  
    local x0 = ox - xx
    local x1 = ox + xx
    local y0 = oy - yy
    local y1 = oy + yy    
  
    lcd.drawLineWithClipping(x0, y0, x1, y1, xmin, xmax, ymin, ymax, style, color)
end


----------------------------------------------------------------------
-- Draw Class
----------------------------------------------------------------------

local draw = {
    xsize = 480, -- LCD_W
    ysize = 272, -- LCD_H
    xmid = 480/2,
    ymid = 272/2,
  
    hudY = 22, hudHeight = 146,
    compassRibbonY = 22,
    groundSpeedY = 80,
    altitudeY = 80, 
    verticalSpeedY = 150,
    statusBar2Y = 200,
    
    compassTicks = {"N",nil,"NE",nil,"E",nil,"SE",nil,"S",nil,"SW",nil,"W",nil,"NW",nil},
}


local function drawWarningBox(warningStr)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawFilledRectangle(draw.xmid-160-2, 74, 320+4, 84, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawFilledRectangle(draw.xmid-160, 76, 320, 80, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(draw.xmid, 85, warningStr, CUSTOM_COLOR+DBLSIZE+CENTER)
end


local function drawNoTelemetry()
    if not mavsdk.mavtelemIsEnabled() then
        drawWarningBox("telemetry disabled")
    elseif not mavsdk.isReceiving() then
        drawWarningBox("no telemetry data")
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
    local vehicleClassStr = getVehicleClassStr()
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
-- Page Autopilot Draw Class
----------------------------------------------------------------------

local function drawHud()
    local pitch = mavsdk.getAttPitchDeg()
    local roll = mavsdk.getAttRollDeg()
  
    local minY = draw.hudY
    local maxY = draw.hudY + draw.hudHeight
    local minX = 120
    local maxX = 360

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
        cx = -math.sin(math.rad(roll)) * 21 --math.cos(math.rad(90 + roll)) * 21
        cy = math.cos(math.rad(roll)) * 21 --math.sin(math.rad(90 + roll)) * 21
    end

    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    for i = 1,8 do
        drawTiltedLineWithClipping(
            ox - i*cx, oy + i*cy,
            -roll,
            (i % 2 == 0 and 80 or 40), minX + 2, maxX - 2, minY + 10, maxY - 2,
            DOTTED, CUSTOM_COLOR)
        drawTiltedLineWithClipping(
            ox + i*cx, oy - i*cy,
            -roll,
            (i % 2 == 0 and 80 or 40), minX + 2, maxX - 2, minY + 10, maxY - 2,
            DOTTED, CUSTOM_COLOR)
    end
    
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawFilledRectangle((minX+maxX)/2-25, (minY+maxY)/2, 50, 2, CUSTOM_COLOR)
end


local function drawCompassRibbon()
    local heading = mavsdk.getAttYawDeg() --getVfrHeadingDeg()
    local y = draw.compassRibbonY
    -- compass ribbon
    -- this piece of code is based on Yaapu FrSky Telemetry Script, much improved
    local minX = draw.xmid - 110 -- make it smaller than hud by at least one char size
    local maxX = draw.xmid + 110 
    local tickNo = 3 --number of ticks on one side
    local stepWidth = (maxX - minX -24)/(2*tickNo)
    local closestHeading = math.floor(heading/22.5) * 22.5
    local closestHeadingX = draw.xmid + (closestHeading - heading)/22.5 * stepWidth
    local tickIdx = (closestHeading/22.5 - tickNo) % 16
    local tickX = closestHeadingX - tickNo*stepWidth   
    for i = 1,12 do
        if tickX >= minX and tickX < maxX then
            if draw.compassTicks[tickIdx+1] == nil then
                lcd.setColor(CUSTOM_COLOR, p.BLACK)
                lcd.drawLine(tickX, y, tickX, y+10, SOLID, CUSTOM_COLOR)
            else
                lcd.setColor(CUSTOM_COLOR, p.BLACK)
                lcd.drawText(tickX, y-3, draw.compassTicks[tickIdx+1], CUSTOM_COLOR+CENTER)
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
    lcd.drawFilledRectangle(draw.xmid - (w/2), y, w, 28, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawNumber(draw.xmid, y-6, heading, CUSTOM_COLOR+DBLSIZE+CENTER)
end


local function drawGroundSpeed()
    local groundSpeed = mavsdk.getVfrGroundSpeed()
    local y = draw.groundSpeedY
    local x = draw.xmid - 120
    
    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawText(x, y-17+2, "SPD", CUSTOM_COLOR+SMLSIZE)
    
    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawFilledRectangle(x, y, 70, 28, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.GREEN)
    if (math.abs(groundSpeed) >= 10) then
        lcd.drawNumber(x+2, y-6, groundSpeed, CUSTOM_COLOR+DBLSIZE+LEFT)
    else
        lcd.drawNumber(x+2, y-6, groundSpeed*10, CUSTOM_COLOR+DBLSIZE+LEFT+PREC1)
    end
end


local function drawAltitude()
    local altitude = mavsdk.getPositionAltitudeRelative() --getVfrAltitudeMsl()
    local y = draw.altitudeY
    local x = draw.xmid + 120

    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawText(x, y-17+2, "ALT", CUSTOM_COLOR+SMLSIZE+RIGHT)

    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawFilledRectangle(x - 70, y, 70, 28, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.GREEN)
    if math.abs(altitude) > 99 or altitude < -99 then
        lcd.drawNumber(x-2, y, altitude, CUSTOM_COLOR+MIDSIZE+RIGHT)
    elseif math.abs(altitude) >= 10 then
        lcd.drawNumber(x-2, y-6, altitude, CUSTOM_COLOR+DBLSIZE+RIGHT)
    else
        lcd.drawNumber(x-2, y-6, altitude*10, CUSTOM_COLOR+DBLSIZE+RIGHT+PREC1)
    end
end    


local function drawVerticalSpeed()
    local verticalSpeed = mavsdk.getVfrClimbRate()
    local y = draw.verticalSpeedY

    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawFilledRectangle(draw.xmid - 30, y, 60, 20, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)  
    local w = 3
    if math.abs(verticalSpeed) > 999 then w = 4 end
    if verticalSpeed < 0 then w = w + 1 end
    lcd.drawNumber(draw.xmid, y-5, verticalSpeed*10, CUSTOM_COLOR+MIDSIZE+CENTER+PREC1)
end


local function drawGpsStatusAt(gpsId, x, y, dy)
    local gpsfix, gpssat, hdop
    if gpsId == 1 then
        gpsfix = mavsdk.getGpsFix()
        gpssat = mavsdk.getGpsSat()
        hdop = mavsdk.getGpsHDop()
    elseif gpsId == 2 then
        gpsfix = mavsdk.getGps2Fix()
        gpssat = mavsdk.getGps2Sat()
        hdop = mavsdk.getGps2HDop()
    else
        return
    end  
    -- GPS fix
    if gpsfix >= mavlink.GPS_FIX_TYPE_3D_FIX then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
    end  
    lcd.drawText(x, y+8, getGpsFixStr(), CUSTOM_COLOR+MIDSIZE+LEFT)
    -- Sat
    if gpssat > 99 then gpssat = 0 end
    if gpssat > 5 and gpsfix >= mavlink.GPS_FIX_TYPE_3D_FIX then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
    end
    lcd.drawNumber(x+3, y+30+dy, gpssat, CUSTOM_COLOR+DBLSIZE)
    -- HDop
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if hdop >= 10 then
        if hdop > 99 then hdop = 99 end
        lcd.drawNumber(x+53, y+30+dy, hdop, CUSTOM_COLOR+DBLSIZE)
    else  
        lcd.drawNumber(x+53, y+30+dy, hdop*10, CUSTOM_COLOR+DBLSIZE+PREC1)
    end
end  


local function drawGpsStatus()
    if not mavsdk.isGps2Available() then drawGpsStatusAt(1, 2,30, 5); return end  
    drawGpsStatusAt(1, 2,13, 0);
    drawGpsStatusAt(2, 2,73, 0);
end  


local function drawTxGpsStatusAt(x,y)
    local gps = getTxGPS()
    local gpsfix = gps.fix --mavsdk.txGpsHasPosIntFix()
    local gpssat = gps.numsat
    local hdop = gps.hdop*0.01 -- 5.0 == 500
    if gpsfix then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        if mavsdk.txGpsHasPosIntFix() then
            lcd.drawText(x, y+8, "POS FIX", CUSTOM_COLOR+LEFT)
        else    
            lcd.drawText(x, y+8, "3D FIX", CUSTOM_COLOR+LEFT)
        end    
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(x, y+8, "No FIX", CUSTOM_COLOR+LEFT)
    end
    if gpssat > 99 then gpssat = 0 end
    if gpssat > 5 and gpsfix then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
    end
    lcd.drawNumber(x+3, y+30, gpssat, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if hdop >= 10 then
        if hdop > 99 then hdop = 99 end
        lcd.drawNumber(x+53, y+30, hdop, CUSTOM_COLOR)
    else  
        lcd.drawNumber(x+53, y+30, hdop*10, CUSTOM_COLOR+PREC1)
    end
end  

local function drawTxGpsStatus()
    if not mavsdk.isTxGpsAvailable() then return end
    local y = 115
    if mavsdk.isGps2Available() then y = y+20 end  
    drawTxGpsStatusAt(2, y)
end  


local function drawSpeedsAt(x, y)
    local groundSpeed = mavsdk.getVfrGroundSpeed()
    local airSpeed = mavsdk.getVfrAirSpeed()
    lcd.setColor(CUSTOM_COLOR, p.WHITE) 
    local gs = string.format("GS %.1f m/s", groundSpeed)
    lcd.drawText(x, y, gs, CUSTOM_COLOR)
    local as = string.format("AS %.1f m/s", airSpeed)
    lcd.drawText(x, y+24, as, CUSTOM_COLOR)
end

local function drawSpeeds()
    if mavsdk.isTxGpsAvailable() then return end
    local y = 115
    if mavsdk.isGps2Available() then y = y + 32 end  
    drawSpeedsAt(2, y)
end


local function drawBatteryStatus()
    local voltage = mavsdk.getBatVoltage()
    local current = mavsdk.getBatCurrent()
    local remaining = mavsdk.getBatRemaining()
    local charge = mavsdk.getBatChargeConsumed()
    local y = 30
    -- voltage
    lcd.setColor(CUSTOM_COLOR, p.WHITE) 
    lcd.drawNumber(draw.xsize-18, y, voltage*100, CUSTOM_COLOR+DBLSIZE+RIGHT+PREC2)
    lcd.drawText(draw.xsize-2, y +14, "V", CUSTOM_COLOR+RIGHT)
    -- current
    if current ~= nil then
        lcd.setColor(CUSTOM_COLOR, p.WHITE) 
        lcd.drawNumber(draw.xsize-18, y+35, current*10, CUSTOM_COLOR+DBLSIZE+RIGHT+PREC1)
        lcd.drawText(draw.xsize-2, y+35 +14, "A", CUSTOM_COLOR+RIGHT)
    end
    -- remaining
    if remaining ~= nil then
        lcd.setColor(CUSTOM_COLOR, p.WHITE) 
        lcd.drawNumber(draw.xsize-18, y+70, remaining, CUSTOM_COLOR+DBLSIZE+RIGHT)
        lcd.drawText(draw.xsize-2, y+70 +14, "%", CUSTOM_COLOR+RIGHT)
    end
    -- charge
    if charge ~= nil then
        lcd.setColor(CUSTOM_COLOR, p.WHITE) 
        lcd.drawNumber(draw.xsize-40, y+105 +7, charge, CUSTOM_COLOR+MIDSIZE+RIGHT)
        lcd.drawText(draw.xsize-1, y+105 +14, "mAh", CUSTOM_COLOR+RIGHT)
    end
end


local function drawStatusBar2()
    local y = draw.statusBar2Y
    -- arming state
    if mavsdk.isArmed() then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawText(draw.xmid, y-26, "ARMED", CUSTOM_COLOR+MIDSIZE+CENTER)
    else    
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        lcd.drawText(draw.xmid, y-26, "DISARMED", CUSTOM_COLOR+MIDSIZE+CENTER)
    end    
    
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
    local timeStr = timeToStr(status_g.flight_time_10ms/100)
    lcd.drawText(draw.xsize-3, y-2, timeStr, CUSTOM_COLOR+DBLSIZE+RIGHT)
end      

local function drawIsInitializing()
    if mavsdk.isReceiving() and not mavsdk.isInitialized() then
        drawWarningBox("is initializing")
    end
end

local function drawStatusText()
    for i=1,3 do
        printStatustextAt(i, 3, 5, 230+(i-1)*13, SMLSIZE)
    end    
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

    drawHud()
    drawCompassRibbon()
    drawGroundSpeed()
    drawAltitude()
    drawVerticalSpeed()
    
    drawGpsStatus()
    drawTxGpsStatus()
    drawSpeeds()
    
    drawBatteryStatus()
    drawStatusBar2()
    drawStatusText()
    
    drawIsInitializing()
end  


----------------------------------------------------------------------
-- Page Camera Draw Class
----------------------------------------------------------------------

local function tcamerabutton_draw(button)
    if not button.visible then return end
    local r = button.rect
    local xmid = r.x + r.w/2
    local ymid = r.y + r.h/2
    local radius = r.w/2
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawCircle(xmid, ymid, radius, CUSTOM_COLOR)
    if button.pressed then
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawFilledRectangle(xmid-0.6*radius, ymid-0.6*radius, 1.2*radius, 1.2*radius, CUSTOM_COLOR+SOLID)
    else
        lcd.setColor(CUSTOM_COLOR, p.DARKRED)
        lcd.drawFilledCircle(xmid, ymid, 0.87*radius, CUSTOM_COLOR)
    end
end

local function tcamerabutton_init(button)
    if not button.initialized then
        tobject.init(button)
        button.pressed = false
    end    
end

local function tcamerabutton_handle(button)
    if not button.visible then return end
    if not tobjstate.isFocusable() then return end --tobject_has_focus then return end
    if touchEventTap(button.rect) then button.click_func() end
end  


local function drawNoCamera()
    if mavsdk.isReceiving() and not mavsdk.cameraIsReceiving() then
        drawWarningBox("no camera")
        return true
    end
    return false
end

local camera = {
    shoot_switch_triggered = false,
    shoot_switch_last = 0,

    video_timer_start_10ms = 0,
    video_timer_10ms = 0,
    photo_counter = 0,

    isshooting = nil,

    initialized = false,
    status_last = nil,

    param_registered = false,
    params_initialized = false,
    params_last = 0,
    params_tries = 0,
}


local function cameraShoot()
    local status = mavsdk.cameraGetStatus()
    if status.mode == mavlink.CAMERA_MODE_VIDEO then
        if status.video_on then 
            mavsdk.cameraStopVideo(); play:VideoOff()
        else 
            mavsdk.cameraStartVideo(); play:VideoOn()
            camera.video_timer_start_10ms = getTime()
        end
    elseif status.mode == mavlink.CAMERA_MODE_IMAGE then
        mavsdk.cameraTakePhoto(); play:TakePhoto()
        camera.photo_counter = camera.photo_counter + 1
    end
end

local function camera_menu_click(menu, idx)
    if not mavsdk.cameraIsInitialized() then return end
    if idx == 1 then
        mavsdk.cameraSendVideoMode()
        --play:VideoMode()
    elseif idx == 2 then
        mavsdk.cameraSendPhotoMode()
        --play:PhotoMode()
    end
end

local camera_menu = { 
    rect = { x = draw.xmid - 60, y = 45, w = 120, h = 37 },
    min = 1, max = 2, default = 1, 
    option = { "Video", "Photo" },
    click_func = camera_menu_click;
}

local camera_button = { 
    rect = { x = draw.xmid - 45, y = 105, w = 90, h = 90 },
    click_func = cameraShoot,
}


local function camera_settings_menu_click(menu, idx)
    menu.idx = -1
--    cam_set_param(menu.cmd, menu.gp[idx])
--    cam_request_param(menu.cmd)
    mavlink.sendParamSet(menu.handle, mavlink.memcpyToNumber(menu.gp[idx]))
    mavlink.sendParamRequest(menu.handle)
end


local VIDRES_menu = { 
    rect = { x = 360, y = 25, w = 120, h = 37 },
    min = 1, max = 4, default = 2, 
    option = { "4K", "2.7K", "2.7K 4:3", "1440" },
    click_func = camera_settings_menu_click,
    gp = { 1, 4, 6, 7 },
    cmd = "CAM_VIDRES",
    --cmd = "DUMMY",
}

local VIDFPS_menu = { 
    rect = { x = 360, y = 65, w = 120, h = 37 },
    min = 1, max = 2, default = 1, 
    option = { "30 fps", "60 fps" },
    click_func = camera_settings_menu_click,
    gp = { 8, 5 },
    cmd = "CAM_VIDFPS",
    --cmd = "DUMMY2",
}

local VIDFOV_menu = { 
    rect = { x = 360, y = 105, w = 120, h = 37 },
    min = 1, max = 4, default = 3, 
    option = { "wide", "medium", "linear", "narrow" },
    click_func = camera_settings_menu_click,
    gp = { 0, 1, 4, 2 },
    cmd = "CAM_VIDFOV",
}

local VIDEV_menu = { 
    rect = { x = 360, y = 145, w = 120, h = 37 },
    min = 1, max = 9, default = 5, 
    option = { "+2.0", "+1.5", "+1.0", "+0.5", "+-0", "-0.5", "-1.0", "-1.5", "-2.0" },
    click_func = camera_settings_menu_click,
    popup_text_size = 0, popup_text_height = 27,
    gp = { 0, 1, 2, 3, 4, 5, 6, 7, 8 },
    cmd = "CAM_VIDEV",
}

local VIDSPD_menu = { 
    rect = { x = 360, y = 185, w = 120, h = 37 },
    min = 1, max = 8, default = 1, 
    option = { "auto", "1/30", "1/60", "1/120", "1/180", "1/240", "1/360", "1/480" },
    click_func = camera_settings_menu_click,
    popup_text_size = 0, popup_text_height = 28,
    gp = { 0, 5, 8, 13, 15, 18, 20, 22 },
    cmd = "CAM_VIDSHUTSPD",
}

local VIDEIS_menu = { 
    rect = { x = 360, y = 225, w = 120, h = 37 },
    min = 1, max = 2, default = 1, 
    option = { "EIS off", "EIS on" },
    click_func = camera_settings_menu_click,
    gp = { 0, 1 },
    cmd = "VID_EIS",
}

local PHOFOV_menu = { 
    rect = { x = 360, y = 25, w = 120, h = 37 },
    min = 1, max = 4, default = 1, 
    option = { "wide", "medium", "linear", "narrow" },
    click_func = camera_settings_menu_click,
    gp = { 0, 8, 10, 9 },
    cmd = "CAM_PHOFOV",
}

local PHOEV_menu = { 
    rect = { x = 360, y = 65, w = 120, h = 37 },
    min = 1, max = 9, default = 5, 
    option = { "+2.0", "+1.5", "+1.0", "+0.5", "+-0", "-0.5", "-1.0", "-1.5", "-2.0" },
    click_func = camera_settings_menu_click,
    popup_text_size = 0, popup_text_height = 27,
    gp = { 0, 1, 2, 3, 4, 5, 6, 7, 8 },
    cmd = "CAM_PHOEV",
}

local PHOSPD_menu = { 
    rect = { x = 360, y = 105, w = 120, h = 37 },
    min = 1, max = 6, default = 1, 
    option = { "auto", "1/125", "1/250", "1/500", "1/1000", "1/2000" },
    click_func = camera_settings_menu_click,
    popup_text_size = 0, popup_text_height = 27,
    gp = { 0, 1, 2, 3, 4, 5, 6 },
    cmd = "CAM_PHOSHUTSPD",
}

local VID_menu_list = {
    VIDRES_menu, VIDFPS_menu, VIDFOV_menu, VIDEV_menu, VIDSPD_menu, VIDEIS_menu,
}  

local PHO_menu_list = {
    PHOFOV_menu, PHOSPD_menu, PHOEV_menu,
}  

local camera_menu_list = {}  

local function camera_register_params()
    if camera.param_registered then return end
    local cam_sysid, cam_compid = mavlink.getCameraIds()
    for i = 1, #camera_menu_list do
        local menu = camera_menu_list[i]
        menu.handle = mavlink.registerParam(cam_sysid, cam_compid, menu.cmd, mavlink.PARAM_TYPE_UINT32)
    end    
    camera.param_registered = true
end


local function camera_menu_set_by_gpidx(menu, gp_idx)
    for i = 1, #menu.option do
      if menu.gp[i] == gp_idx then menu.idx = i; return end
    end
--    cam_set_param(menu.cmd, menu.gp[menu.default])
    mavlink.sendParamSet(menu.handle, mavlink.memcpyToNumber(menu.gp[menu.default]))
end    


local function cameraDoAlways()
    if not mavsdk.cameraIsReceiving() then
      camera.status_last = nil
      camera.params_initialized = false
      camera.params_tries = 0
      for i = 1, #camera_menu_list do camera_menu_list[i].idx = -10 end
    end
    if not mavsdk.cameraIsInitialized() then return end

    if not camera.param_registered then -- must be done only once
        camera_menu_list = {}
        for i = 1, #VID_menu_list do camera_menu_list[i] = VID_menu_list[i] end
        for i = 1, #PHO_menu_list do camera_menu_list[#VID_menu_list+i] = PHO_menu_list[i] end
        camera_register_params()
    end

    if not camera.initialized then
        camera.initialized = true
        tcamerabutton_init(camera_button)
        tmenu.init(camera_menu)
        for i = 1, #camera_menu_list do 
          tmenu.init(camera_menu_list[i])
          camera_menu_list[i].idx = -10 
        end
    end

    local status = mavsdk.cameraGetStatus()
    
    if status_g.camera_changed_to_receiving then -- is this working ???
        -- here one needs to get all camera settings and adjust things accordingly !!
    end
    
    if camera.status_last == nil then
        camera.status_last = status
        if status.mode == mavlink.CAMERA_MODE_VIDEO then 
            camera_menu.idx = 1
        end
        if status.mode == mavlink.CAMERA_MODE_IMAGE then 
            camera_menu.idx = 2
        end
    end    
    
    camera_button.pressed = status.video_on or status.photo_on
    if camera.status_last.mode ~= status.mode then
        if status.mode == mavlink.CAMERA_MODE_VIDEO then 
            play:VideoMode() 
            camera_menu.idx = 1
        end
        if status.mode == mavlink.CAMERA_MODE_IMAGE then 
            play:PhotoMode() 
            camera_menu.idx = 2
        end
    end
    camera.status_last = status
    
    if not camera.params_initialized and camera.params_tries < 50 then
        local tnow = getTime()
        local ok = true
        for i = 1, #camera_menu_list do
            local menu = camera_menu_list[i]
            if menu.idx < 0 then
                if menu.idx == -10 or (tnow - camera.params_last) > 100 then
                    menu.idx = -9
                    camera.params_last = tnow
                    camera.params_tries = camera.params_tries + 1
--                    cam_request_param(menu.cmd)
                    mavlink.sendParamRequest(menu.handle)
                end
              ok = false
              break  
            end    
        end
        camera.params_initialized = ok
    end
--[[
    local cam_sysid, cam_compid = mavlink.getCameraIds()
    local msg = mavlink.getMessage(mavlink.M_PARAM_VALUE, cam_sysid, cam_compid) --22
    if msg ~= nil and msg.updated then
        local id = tab2str(msg.param_id)
        for i = 1, #camera_menu_list do
            if id == camera_menu_list[i].cmd then
                local val = mavlink.memcpyToInteger(msg.param_value)
                camera_menu_set_by_gpidx(camera_menu_list[i], val)
                break
            end
        end    
    end
]]
    for i = 1, #camera_menu_list do
        local res = mavlink.getParamValue(camera_menu_list[i].handle)
        if res.updated then
            local val = mavlink.memcpyToInteger(res.param_value)
            camera_menu_set_by_gpidx(camera_menu_list[i], val)
        end    
    end    

    camera.shoot_switch_triggered = false
    local shoot_switch = getValue(config_g.cameraShootSwitch)
    if shoot_switch ~= nil then
        if shoot_switch > 500 and camera.shoot_switch_last < 500 then camera.shoot_switch_triggered = true end
        camera.shoot_switch_last = shoot_switch
    end    
    
    if camera.shoot_switch_triggered then
        cameraShoot()
    end
end


local function doPageCamera()
    if drawNoCamera() then return end
    
    local info = mavsdk.cameraGetInfo()
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    local cameraStr = string.format("%s %d", string.upper(getCameraIdStr(info.compid)), info.compid)
    lcd.drawText(1, 20, cameraStr, CUSTOM_COLOR)
    if not mavsdk.cameraIsInitialized() then
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(LCD_W/2, 120, "camera module is initializing...", CUSTOM_COLOR+MIDSIZE+CENTER)
        return
    end  
    local model_str
    if string.find(info.model_name, "STorM32", 1, 7) then
        model_str = string.sub(info.model_name,9)
    else    
        model_str = info.model_name     
    end        
    lcd.drawText(1, 36, model_str, CUSTOM_COLOR)--info.model_name, CUSTOM_COLOR)
    
    local cam_sysid, cam_compid = mavlink.getCameraIds()
    local status = mavsdk.cameraGetStatus()
    
    -- Handler 
    local shooting = status.video_on or status.photo_on
    if camera.isshooting == nil or shooting ~= camera.isshooting then
        camera.isshooting = shooting
        tobject.enable(camera_menu, not shooting)
        for i = 1, #camera_menu_list do tobject.enable(camera_menu_list[i], not shooting) end
    end    
    
    tcamerabutton_handle(camera_button)
    if not status.video_on and not status.photo_on then
    if info.has_video and info.has_photo then
        tmenu.handle(camera_menu)
    end
    if info.has_video and camera.params_initialized and status.mode == mavlink.CAMERA_MODE_VIDEO then 
        for i = 1, #VID_menu_list do 
            tmenu.handle(VID_menu_list[i]) 
        end    
    end    
    if info.has_photo and camera.params_initialized and status.mode == mavlink.CAMERA_MODE_IMAGE then 
        for i = 1, #PHO_menu_list do 
            tmenu.handle(PHO_menu_list[i]) 
        end    
    end
    end
    
    -- DISPLAY
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if status.mode == mavlink.CAMERA_MODE_VIDEO then 
        if status.video_on then
            camera.video_timer_10ms = (getTime() - camera.video_timer_start_10ms)/100
        end    
        local timeStr = timeToStr(camera.video_timer_10ms)
        lcd.drawText(draw.xmid, 215, timeStr, CUSTOM_COLOR+MIDSIZE+CENTER)
    elseif status.mode == mavlink.CAMERA_MODE_IMAGE then 
        local countStr = string.format("%04d", camera.photo_counter)
        lcd.drawText(draw.xmid, 215, countStr, CUSTOM_COLOR+MIDSIZE+CENTER)
    end
    
    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    if status.video_on then
        lcd.drawText(draw.xmid, 240, "video recording...", CUSTOM_COLOR+MIDSIZE+CENTER+BLINK)
    end
    if status.photo_on then
        lcd.drawText(draw.xmid, 240, "photo shooting...", CUSTOM_COLOR+MIDSIZE+CENTER+BLINK)
    end
    
    local x = 10
    local y = 120
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if status.available_capacity ~= nil then
        lcd.drawText(x, y, "capacity", CUSTOM_COLOR)
        local capacityStr
        if status.available_capacity >= 1024 then 
            capacityStr = string.format("%.2f GB", status.available_capacity/1024)
        else
            capacityStr = string.format("%.2f MB", status.available_capacity)
        end    
        lcd.drawText(x+10, y+20, capacityStr, CUSTOM_COLOR+MIDSIZE)
        y = y+50
    end
    if status.battery_remainingpct ~= nil then
        lcd.drawText(x, y, "battery level", CUSTOM_COLOR)
        local remainingStr = string.format("%d%%", status.battery_remainingpct)
        if status.battery_remainingpct < 15 then
            lcd.setColor(CUSTOM_COLOR, p.RED)
            lcd.drawText(x+10, y+20, remainingStr, CUSTOM_COLOR+MIDSIZE)
            lcd.setColor(CUSTOM_COLOR, p.WHITE)
        else  
            lcd.drawText(x+10, y+20, remainingStr, CUSTOM_COLOR+MIDSIZE)
        end    
        y = y+50
    end
    if status.battery_voltage ~= nil then
        lcd.drawText(x, y, "battery voltage", CUSTOM_COLOR)
        local voltageStr = string.format("%.1f v", status.battery_voltage)
        lcd.drawText(x+10, y+20, voltageStr, CUSTOM_COLOR)
    end
  
    tcamerabutton_draw(camera_button)
    if info.has_video and info.has_photo then
        tmenu.draw(camera_menu)
    elseif info.has_video then
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawText(draw.xmid, 70, "Video", CUSTOM_COLOR+DBLSIZE+CENTER)
    elseif info.has_photo then
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawText(draw.xmid, 70, "Photo", CUSTOM_COLOR+DBLSIZE+CENTER)
    end
    
    if info.has_video and camera.params_initialized and status.mode == mavlink.CAMERA_MODE_VIDEO then 
        for i = 1, #VID_menu_list do
            tmenu.draw(VID_menu_list[i])
        end
    end
    if info.has_photo and camera.params_initialized and status.mode == mavlink.CAMERA_MODE_IMAGE then 
        for i = 1, #PHO_menu_list do
            tmenu.draw(PHO_menu_list[i])
        end
    end
    
--[[    
    for i=1,#camera_menu_list do
        lcd.drawNumber(10, 10+i*20, camera_menu_list[i].handle, CUSTOM_COLOR)
        lcd.drawText(100, 10+i*20, camera_menu_list[i].cmd, CUSTOM_COLOR)
    end    
]]
end  


----------------------------------------------------------------------
-- Page Gimbal Draw Class
----------------------------------------------------------------------

local function drawNoGimbal()
    if mavsdk.isReceiving() and not mavsdk.gimbalIsReceiving() then
        drawWarningBox("no gimbal")
        return true
    end
    return false
end

local gimbal = {
    pitch_cntrl_deg = nil,
    yaw_cntrl_deg = 0,
    qshot_mode = nil,
    qshot_status_last_10ms = 0,
    qshot_init_cnt = 0,
    debug = true, --false,
}    

local function gimbalSetQShotMode_idx(idx, sound_flag)
    if idx == 1 then
        gimbal.qshot_mode = mavsdk.QSHOT_MODE_DEFAULT
        mavsdk.qshotSendCmdConfigure(gimbal.qshot_mode, 0)
        if sound_flag then play:QShotDefault() end
    elseif idx == 2 then
        gimbal.qshot_mode = mavsdk.QSHOT_MODE_NEUTRAL
        mavsdk.qshotSendCmdConfigure(gimbal.qshot_mode, 0)
        if sound_flag then play:QShotNeutral() end
    elseif idx == 3 then
        gimbal.qshot_mode = mavsdk.QSHOT_MODE_RC_CONTROL
        mavsdk.qshotSendCmdConfigure(gimbal.qshot_mode, 0)
        if sound_flag then play:QShotRcControl() end
    elseif idx == 4 or idx == 5 then
        gimbal.qshot_mode = mavsdk.QSHOT_MODE_SYSID
        mavsdk.qshotSendCmdConfigure(gimbal.qshot_mode, 0)
        if sound_flag then play:QShotTargetMe() end
--[[        
    elseif idx == 4 then
        gimbal.qshot_mode = mavsdk.QSHOT_MODE_POI
        mavsdk.qshotSendCmdConfigure(gimbal.qshot_mode, 0)
        if sound_flag then play:QShotPOI() end
    elseif idx == 5 then
        gimbal.qshot_mode = mavsdk.QSHOT_MODE_CABLECAM
        mavsdk.qshotSendCmdConfigure(gimbal.qshot_mode, 0)
        if sound_flag then play:QShotCableCam() end
]]        
    end
end  

local function gimbalSendRoiSysId()
    local ap_sysid, ap_compid = mavlink.getAutopilotIds()
    local my_sysid = 254 --TODO: mavlink.getMyIds()[1]
    --local my_sysid = mavlink.getMyIds()[1]
    mavlink.sendMessage({
        msgid = mavlink.M_COMMAND_LONG,
        target_sysid = ap_sysid,
        target_compid = ap_compid,
        command = mavlink.CMD_DO_SET_ROI_SYSID,
        param1 = my_sysid,
        param2 = 0, --gimbal device id, ignored by ArduPilot
    })
end

local function gimbal_menu_click(menu, idx)
    gimbalSetQShotMode_idx(idx, true)
end

local gimbal_menu = {
    rect = { x = draw.xmid - 240/2, y = 235, w = 240, h = 34 },
    click_func = gimbal_menu_click,
    min = 1, max = 5, default = 1, 
--    option = { "Default", "Neutral", "RC Control", "POI Targeting", "Cable Cam" },
    option = { "Default", "Neutral", "RC Control", "Target Me", "Target Me w/nudge" },
}


-- this is a wrapper, to account for gimbalAdjustForArduPilotBug
-- if V1, calling mavsdk.gimbalSendPitchYawDeg() sets mode implicitely to MAVLink targeting
local function gimbalSetPitchYawDeg_idx(idx, pitch, yaw)
    if not config_g.gimbalUseGimbalManager or not mavsdk.gimbalIsProtocolV2() then
        yaw = 0.0 -- clear yaw since it would turn the copter ! In RC Targeting it doesn't matter anyway
        if config_g.gimbalAdjustForArduPilotBug then 
            mavsdk.gimbalSendPitchYawDeg(pitch*100, yaw*100)
        else    
            mavsdk.gimbalSendPitchYawDeg(pitch, yaw)
        end
    else
        if config_g.gimbalYawSlider == "" then
            yaw = 0.0
        end
        mavsdk.gimbalClientSetNeutral(0)
        if idx == 1 then
            mavsdk.gimbalClientSetFlags(mavsdk.GMFLAGS_GCS_ACTIVE)
        elseif idx == 2 then
            mavsdk.gimbalClientSetNeutral(1)
            mavsdk.gimbalClientSetFlags(0)
        elseif idx == 3 then
            mavsdk.gimbalClientSetFlags(mavsdk.GMFLAGS_RC_ACTIVE)
        elseif idx == 4 then
            mavsdk.gimbalClientSetFlags(mavsdk.GMFLAGS_AUTOPILOT_ACTIVE)
        elseif idx == 5 then
            mavsdk.gimbalClientSetFlags(mavsdk.GMFLAGS_GCS_ACTIVE+mavsdk.GMFLAGS_AUTOPILOT_ACTIVE)
            --we correct pitch to be in +-20° range
            local pitch_cntrl = getValue(config_g.gimbalPitchSlider)
            gimbal.pitch_cntrl_deg = 0
            if pitch_cntrl ~= nil then 
                gimbal.pitch_cntrl_deg = -pitch_cntrl/1008*20
            end
            pitch = gimbal.pitch_cntrl_deg
        end
--        mavsdk.gimbalClientSendCmdPitchYawDeg(pitch, yaw)
        mavsdk.gimbalClientSendPitchYawDeg(pitch, yaw)
    end    
end


local function gimbalDoAlways()
    if config_g.gimbalUseGimbalManager then 
        mavsdk.gimbalSetProtocolV2(1)
    else    
        mavsdk.gimbalSetProtocolV2(0)
    end
    if not mavsdk.gimbalIsReceiving() then return end
  
    tmenu.init(gimbal_menu)
  
    -- set gimbal into default MAVLink targeting mode upon connection
    if status_g.gimbal_changed_to_receiving then
        gimbal_menu.idx = gimbal_menu.default
        gimbal.qshot_init_cnt = 6  -- send qshotmode and then roi sysid 3 times, to be sure it is received
    end  
    if gimbal.qshot_init_cnt > 0 then
        gimbal.qshot_init_cnt = gimbal.qshot_init_cnt - 1
        if gimbal.qshot_init_cnt >= 3 then
            gimbalSetQShotMode_idx(gimbal_menu.idx, false)
        else  
            gimbalSendRoiSysId()
        end    
    end
    
    -- pitch control slider
    local pitch_cntrl = getValue(config_g.gimbalPitchSlider)
    if pitch_cntrl ~= nil then 
        gimbal.pitch_cntrl_deg = -(pitch_cntrl+1008)/1008*45
        if gimbal.pitch_cntrl_deg > 0 then gimbal.pitch_cntrl_deg = 0 end
        if gimbal.pitch_cntrl_deg < -90 then gimbal.pitch_cntrl_deg = -90 end
    end
    -- yaw control slider
    local yaw_cntrl = getValue(config_g.gimbalYawSlider)
    if yaw_cntrl ~= nil then 
        gimbal.yaw_cntrl_deg = yaw_cntrl/1008*75
        if gimbal.yaw_cntrl_deg > 75 then gimbal.yaw_cntrl_deg = 75 end
        if gimbal.yaw_cntrl_deg < -75 then gimbal.yaw_cntrl_deg = -75 end
    end
    
    gimbalSetPitchYawDeg_idx(gimbal_menu.idx, gimbal.pitch_cntrl_deg, gimbal.yaw_cntrl_deg)
    
    --send qshot status every 1 sec
    local tnow = getTime()
    if (tnow - gimbal.qshot_status_last_10ms) >= 100 then --100 = 1000ms
        gimbal.qshot_status_last_10ms = gimbal.qshot_status_last_10ms + 100
        mavsdk.qshotSendStatus(gimbal.qshot_mode, 0)
    end
    
end


local function doPageGimbal()
    if drawNoGimbal() then return end
    local x = 0
    local y = 0
    
    -- MENU HANDLING
    tmenu.handle(gimbal_menu)
    
    -- DISPLAY
    local info =  mavsdk.gimbalGetInfo()
    local compid =  info.compid
    local gimbalStr = string.format("%s %d", string.upper(getGimbalIdStr(compid)), compid)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(1, 20, gimbalStr, CUSTOM_COLOR)
if not gimbal.debug then
    local modelStr = info.model_name
    lcd.drawText(1, 35, modelStr, CUSTOM_COLOR)
    local versionStr = info.firmware_version
    lcd.drawText(1, 50, versionStr, CUSTOM_COLOR)
end    
    
if gimbal.debug then
    local modelStr = info.model_name
    lcd.drawText(LCD_W-1, 20, modelStr, CUSTOM_COLOR+RIGHT)
    local vendorStr = info.vendor_name
    lcd.drawText(LCD_W-1, 35, vendorStr, CUSTOM_COLOR+RIGHT)
    local versionStr = info.firmware_version
    lcd.drawText(LCD_W-1, 50, versionStr, CUSTOM_COLOR+RIGHT)
--    local customStr = info.custom_name
--    lcd.drawText(LCD_W-1, 65, customStr, CUSTOM_COLOR+RIGHT)
if config_g.gimbalUseGimbalManager and mavsdk.gimbalIsProtocolV2() then
    if mavsdk.gimbalClientIsInitialized() then
        lcd.drawText(1, 35, "client initialized", CUSTOM_COLOR)
    elseif mavsdk.gimbalClientIsReceiving() then
        lcd.drawText(1, 35, "client is receiving", CUSTOM_COLOR)
    else
        lcd.drawText(1, 35, "client is waiting...", CUSTOM_COLOR)
    end    
    local clientInfo = mavsdk.gimbalClientGetInfo()
    if clientInfo.gimbal_manager_id > 0 then
        local s = string.format("manager %d", clientInfo.gimbal_manager_id)
        lcd.drawText(1, 50, s, CUSTOM_COLOR)
    end

    y = 208
    local gm_supervisor = mavsdk.gimbalClientGetStatus().supervisor
    local gd_flags = mavsdk.gimbalClientGetStatus().device_flags
    local gm_flags = mavsdk.gimbalClientGetStatus().manager_flags
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(1, y, "CC:", CUSTOM_COLOR)
    if gm_supervisor == mavsdk.GMCLIENT_ONBOARD then
        lcd.drawText(50, y, "c", CUSTOM_COLOR)
        if bit32.btest(gm_flags, mavsdk.GMFLAGS_ONBOARD_ACTIVE) then
            lcd.drawText(60, y, "a", CUSTOM_COLOR)
        end  
    elseif bit32.btest(gm_flags, mavsdk.GMFLAGS_ONBOARD_ACTIVE) then
        lcd.drawText(50, y, "a", CUSTOM_COLOR)
    else    
        lcd.drawText(50, y, "-", CUSTOM_COLOR)
    end    
    y = y + 15
    lcd.drawText(1, y, "GCS:", CUSTOM_COLOR)
    if gm_supervisor == mavsdk.GMCLIENT_GCS then
        lcd.drawText(50, y, "c", CUSTOM_COLOR)
        if bit32.btest(gm_flags, mavsdk.GMFLAGS_GCS_ACTIVE) then
            lcd.drawText(60, y, "a", CUSTOM_COLOR)
        end  
    elseif bit32.btest(gm_flags, mavsdk.GMFLAGS_GCS_ACTIVE) then
        lcd.drawText(50, y, "a", CUSTOM_COLOR)
    else    
        lcd.drawText(50, y, "-", CUSTOM_COLOR)
    end    
    y = y + 15
    lcd.drawText(1, y, "A:", CUSTOM_COLOR)
    if gm_supervisor == mavsdk.GMCLIENT_AUTOPILOT then
        lcd.drawText(50, y, "c", CUSTOM_COLOR)
        if bit32.btest(gm_flags, mavsdk.GMFLAGS_AUTOPILOT_ACTIVE) then
            lcd.drawText(60, y, "a", CUSTOM_COLOR)
        end  
    elseif bit32.btest(gm_flags, mavsdk.GMFLAGS_AUTOPILOT_ACTIVE) then
        lcd.drawText(50, y, "a", CUSTOM_COLOR)
    else    
        lcd.drawText(50, y, "-", CUSTOM_COLOR)
    end    
    y = y + 15
    lcd.drawText(1, y, "RC:", CUSTOM_COLOR)
    if bit32.btest(gm_flags, mavsdk.GMFLAGS_RC_ACTIVE) then
        lcd.drawText(50, y, "a", CUSTOM_COLOR)
    else    
        lcd.drawText(50, y, "-", CUSTOM_COLOR)
    end
end    
end
    
    local is_armed = mavsdk.gimbalGetStatus().is_armed
    local prearm_ok = mavsdk.gimbalGetStatus().prearm_ok
    if is_armed then 
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawText(draw.xmid, 20-4, "ARMED", CUSTOM_COLOR+DBLSIZE+CENTER)
    elseif prearm_ok then     
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        lcd.drawText(draw.xmid, 20, "Prearm Checks Ok", CUSTOM_COLOR+MIDSIZE+CENTER)
    else  
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        lcd.drawText(draw.xmid, 20, "Initializing", CUSTOM_COLOR+MIDSIZE+CENTER)
    end
    
    x = 10
    y = 95
    local pitch = mavsdk.gimbalGetAttPitchDeg()
    local roll = mavsdk.gimbalGetAttRollDeg()
    local yaw = mavsdk.gimbalGetAttYawDeg()
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, "Pitch:", CUSTOM_COLOR+MIDSIZE)
    lcd.drawNumber(x+80, y, pitch*100, CUSTOM_COLOR+MIDSIZE+PREC2)
    lcd.drawText(x, y+35, "Roll:", CUSTOM_COLOR+MIDSIZE)
    lcd.drawNumber(x+80, y+35, roll*100, CUSTOM_COLOR+MIDSIZE+PREC2)
    lcd.drawText(x, y+70, "Yaw:", CUSTOM_COLOR+MIDSIZE)
    lcd.drawNumber(x+80, y + 70, yaw*100, CUSTOM_COLOR+MIDSIZE+PREC2)

    x = 220
    y = y + 15
    local r = 80
    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    lcd.drawCircleQuarter(x, y, r, 4, CUSTOM_COLOR)    
    
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if gimbal.pitch_cntrl_deg ~= nil then
        local cangle = gimbal.pitch_cntrl_deg
        lcd.drawCircle(x + (r-10)*math.cos(math.rad(cangle)), y - (r-10)*math.sin(math.rad(cangle)), 7, CUSTOM_COLOR)
    end    
    if gimbal.pitch_cntrl_deg ~= nil then
        lcd.drawNumber(400, y, gimbal.pitch_cntrl_deg, CUSTOM_COLOR+XXLSIZE+CENTER)
    end    
    if gimbal.yaw_cntrl_deg ~= nil and config_g.gimbalYawSlider ~= "" then
        lcd.drawNumber(400, y+60, gimbal.yaw_cntrl_deg, CUSTOM_COLOR+CENTER)
    end    
    
    lcd.setColor(CUSTOM_COLOR, p.RED)
    local gangle = pitch
    if gangle > 10 then gangle = 10 end
    if gangle < -100 then gangle = -100 end
    lcd.drawFilledCircle(x + (r-10)*math.cos(math.rad(gangle)), y - (r-10)*math.sin(math.rad(gangle)), 5, CUSTOM_COLOR)

    -- MENU DISPLAY
    tmenu.draw(gimbal_menu)
end  


----------------------------------------------------------------------
-- Page Action Draw Class
----------------------------------------------------------------------

-- take off button class
local function ttakeoffbutton_draw(button)
    if not button.visible then return end
    local r = button.rect
    local xmid = r.x + r.w/2
    local ymid = r.y + r.h/2
    local radius = r.w/2
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawCircle(xmid, ymid, radius, CUSTOM_COLOR)
    if not button.enabled then 
        lcd.setColor(CUSTOM_COLOR, p.GREY)
        lcd.drawFilledCircle(xmid, ymid, 0.87*radius, CUSTOM_COLOR)
    elseif button.clicked then 
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawFilledRectangle(xmid-0.6*radius, ymid-0.6*radius, 1.2*radius, 1.2*radius, CUSTOM_COLOR+SOLID)
    elseif button.pressed then
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawFilledCircle(xmid, ymid, 0.87*radius, CUSTOM_COLOR)
        local dt = getTime() - button.press_start
        local secs = 0
        if dt < 100 then secs = 5 
        elseif dt < 200 then secs = 4 
        elseif dt < 300 then secs = 3 
        elseif dt < 400 then secs = 2 
        elseif dt < 500 then secs = 1 end
        -- secs = math.floor((500 - (getTime() - button.press_start))/100) + 1
        lcd.drawNumber(xmid+0.9*r.w, ymid-37, secs, CUSTOM_COLOR+XXLSIZE+CENTER)
    else
        lcd.setColor(CUSTOM_COLOR, p.DARKRED)
        lcd.drawFilledCircle(xmid, ymid, 0.87*radius, CUSTOM_COLOR)
    end
end

local function ttakeoffbutton_handle(button)
    local res = tbuttonlong.handle(button)
    if res then
        if not button.armed and (getTime() - button.press_start) >= button.arm_time then
            button.armed = true
            button.arm_func()
        end
    else    
        button.armed = false
    end  
end 

local function ttakeoffbutton_init(button)
    tbuttonlong.init(button)
    button.press_time = 500
    button.arm_time = 250
    button.armed = false
end    


local action = {
    initialized = false,
    
    takeoff_triggered = false,
    takeoff_cntdown = 0,
    display_takingoff_cntdown= 0,
    
    islanding = false,
    landing_flightmode_at_start = nil,
    landing_restore_flightmode_cntdown = 0,
    
    magcalibrationstarted = false,
    magiscalibrating = false,
    mag = {},
    
    follow_flightmode_at_start = nil,
}    
action.mag[0] = { completion_pct = 0, fitness = 0, cal_status = nil }
action.mag[1] = { completion_pct = 0, fitness = 0, cal_status = nil }
action.mag[2] = { completion_pct = 0, fitness = 0, cal_status = nil }

local function action_landing_reset()
    action.islanding = false
    action.landing_flightmode_at_start = nil
    action.landing_restore_flightmode_cntdown = 0
end

local function action_calibration_reset()
    action.magcalibrationstarted = false
    action.magiscalibrating = false
    for i = 0,2 do
        action.mag[i].completion_pct = 0
        action.mag[i].fitness = 0
        action.mag[i].cal_status = nil
    end    
end

--CMD_NAV_LAND
--CMD_NAV_RETURN_TO_LAUNCH
--CMD_NAV_TAKEOFF

local function action_takeoff_button_arm()
    local ap_sysid, ap_compid = mavlink.getAutopilotIds()
    mavlink.sendMessage({
        msgid = mavlink.M_COMMAND_LONG,
        target_sysid = ap_sysid,
        target_compid = ap_compid,
        command = mavlink.CMD_COMPONENT_ARM_DISARM,
        param1 = 1,
        param2 = 0,
    })
end

local function action_takeoff_button_click()
-- triggers do_user_takeoff()
-- requires armed
-- requires it is landed
-- requires flight mode which allows it: PosHold, Guided, Loiter, if not must_navigate: AltHold, FlowHold, Sport
    -- we start a loop which waits for vehiclke to be armed before sending takeoff
    action.takeoff_triggered = true
    action.takeoff_cntdown = 0
end

local function action_send_cmd_takeoff()
-- triggers do_user_takeoff()
-- requires armed
-- requires it is landed
-- requires flight mode which allows it: PosHold, Guided, Loiter, if not must_navigate: AltHold, FlowHold, Sport
    local ap_sysid, ap_compid = mavlink.getAutopilotIds()
    mavlink.sendMessage({
        msgid = mavlink.M_COMMAND_LONG,
        target_sysid = ap_sysid,
        target_compid = ap_compid,
        command = mavlink.CMD_NAV_TAKEOFF,
        param3 = 0,
        param7 = 1.5,
    })
    play:TakeOff()
end

local action_takeoff_button = { 
    rect = { x = draw.xmid - 45, y = 175, w = 90, h = 90 },
    arm_func = action_takeoff_button_arm,
    click_func = action_takeoff_button_click,
}


local function action_land_button_click()
    action.landing_flightmode_at_start = mavsdk.getFlightMode()
    local ap_sysid, ap_compid = mavlink.getAutopilotIds()
    mavlink.sendMessage({
        msgid = mavlink.M_COMMAND_LONG,
        target_sysid = ap_sysid,
        target_compid = ap_compid,
        command = mavlink.CMD_NAV_LAND,
        param5 = 0,
        param6 = 0,
    })
    action.islanding = true
end

local action_land_button = {
    rect = { x = 10, y = 60 +2*40+20, w = 120, h = 34 },
    txt = "Land",
    click_func = action_land_button_click,
}

local function action_arm_button_click()
    local p1 = 0
    if not mavsdk.isArmed() then p1 = 1 end
    local ap_sysid, ap_compid = mavlink.getAutopilotIds()
    mavlink.sendMessage({
        msgid = mavlink.M_COMMAND_LONG,
        target_sysid = ap_sysid,
        target_compid = ap_compid,
        command = mavlink.CMD_COMPONENT_ARM_DISARM,
        param1 = p1,
        param2 = 0,
    })
end

local function action_arm_button_case()
    if mavsdk.isArmed() then return 2 end
    return 1
end  

local action_arm_button = {
    rect = { x = 10, y = 60+4*40, w = 120, h = 34 },
    txt = "Arm", txt2 = "Disarm",
    click_func = action_arm_button_click,
    case_func = action_arm_button_case,
}

local function compass_start_button_click()
    local ap_sysid, ap_compid = mavlink.getAutopilotIds()
    mavlink.sendMessage({
        msgid = mavlink.M_COMMAND_LONG,
        target_sysid = ap_sysid,
        target_compid = ap_compid,
        command = mavlink.CMD_DO_START_MAG_CAL,
        param1 = 0, -- mask, 0 = all
        param2 = 1, -- retry
        param3 = 1, -- autosave, 1 = true
        param4 = 0, -- delay
        param5 = 0, -- autoreboot, 0 = false
    })
    action.magiscalibrating = true
    play:MagCalibrationStarted()
end

local function compass_cancel_button_click()
    local ap_sysid, ap_compid = mavlink.getAutopilotIds()
    mavlink.sendMessage({
        msgid = mavlink.M_COMMAND_LONG,
        target_sysid = ap_sysid,
        target_compid = ap_compid,
        command = mavlink.CMD_DO_CANCEL_MAG_CAL,
        param1 = 0, -- mask, 0 = all
    })
    action.magiscalibrating = false
end

local action_compass_start_button = {
    rect = { x = 290, y = 60, w = 180, h = 34 },
    txt = "Compass Cal.",
    click_func = compass_start_button_click,
}

local action_compass_cancel_button = {
    rect = { x = 290, y = 100, w = 180, h = 34 },
    txt = "Cancel",
    click_func = compass_cancel_button_click,
}

local follow = {
    param_registered = false,
    params_initialized = false,
    params_last = 0,
    params_tries = 0,
    param_list = {
        { param_id = "FOLL_OFS_TYPE", idx = -10, handle = nil, val = nil, desired_val = 0 },
        { param_id = "FOLL_YAW_BEHAVE", idx = -10, handle = nil, val = nil, desired_val = 0 },
        { param_id = "FOLL_ENABLE", idx = -10, handle = nil, val = nil, desired_val = 1 },
        { param_id = "FOLL_ALT_TYPE", idx = -10, handle = nil, val = nil, desired_val = 1 },
        { param_id = "FOLL_SYSID", idx = -10, handle = nil, val = nil, desired_val = 254 },
        { param_id = "FOLL_OFS_X", idx = -10, handle = nil, val = nil, desired_val = 0 },
        { param_id = "FOLL_OFS_Y", idx = -10, handle = nil, val = nil, desired_val = 0 },
        { param_id = "FOLL_OFS_Z", idx = -10, handle = nil, val = nil, desired_val = 0 },
        --{ param_id = "FOLL_DIST_MAX", idx = -10, handle = nil, val = nil, desired_val = 100 },
        --{ param_id = "FOLL_POS_P", idx = -10, handle = nil, val = nil, desired_val = 0 }
    }
}  

local function action_follow_menu_click(menu, idx)
    local p1 = 0
    local p2 = 0
    if idx == 2 then p1 = 0; p2 = 1
    elseif idx == 3 then p1 = 1; p2 = 0
    elseif idx == 4 then p1 = 1; p2 = 1 end
    local param_OFS_TYPE = follow.param_list[1]
    local param_YAW_BEHAVE = follow.param_list[2]
    param_OFS_TYPE.desired_val = p1
    param_YAW_BEHAVE.desired_val = p2
    mavlink.sendParamSet(param_OFS_TYPE.handle, param_OFS_TYPE.desired_val)
    mavlink.sendParamSet(param_YAW_BEHAVE.handle, param_YAW_BEHAVE.desired_val)
    --menu.idx = -1
    -- we should innvalidate and listen to the PARAM_VALUE, and set the menu to what actually has been achieved
    -- instead we simply send twice, and again then follow mode is set
    mavlink.sendParamSet(param_OFS_TYPE.handle, param_OFS_TYPE.desired_val)
    mavlink.sendParamSet(param_YAW_BEHAVE.handle, param_YAW_BEHAVE.desired_val)
end    

local action_follow_menu = {
    rect = { x = 10, y = 60, w = 180, h = 34 },
    min = 1, max = 4, default = 1, 
    option = { "NED - none", "NED - face me", "REL - none", "REL - face me" },
    click_func = action_follow_menu_click,
}

local function action_follow_button_click()
    if mavsdk.getFlightMode() == apCopterFlightMode.Follow then
        if action.follow_flightmode_at_start == nil then --shoudl not happen, but play it safe
            action.follow_flightmode_at_start = apCopterFlightMode.PosHold
        end    
        mavsdk.apSetFlightMode(action.follow_flightmode_at_start)
        action.follow_flightmode_at_start = nil
    else    
        action_follow_menu_click(action_follow_menu, action_follow_menu.idx)
        action.follow_flightmode_at_start = mavsdk.getFlightMode()
        mavsdk.apSetFlightMode(apCopterFlightMode.Follow)
    end    
end

local function action_follow_button_case()
    if mavsdk.getFlightMode() == apCopterFlightMode.Follow then return 2 end
    return 1
end  

local action_follow_button = {
    rect = { x = 10, y = 100, w = 180, h = 34 },
    txt = "Follow", txt2 = "Stop Follow", 
    click_func = action_follow_button_click,
    case_func = action_follow_button_case,
}


local function follow_register_params()
    if follow.param_registered then return end
    local ap_sysid, ap_compid = mavlink.getAutopilotIds()
    for i = 1, #follow.param_list do
        local param = follow.param_list[i]
        param.handle = mavlink.registerParam(ap_sysid, ap_compid, param.param_id, mavlink.PARAM_EXT_TYPE_REAL32)
        --param.handle = mavlink.registerParam(0, 0, param.param_id, mavlink.PARAM_EXT_TYPE_REAL32)
    end
    follow.param_registered = true
end

local function follow_set_params_start()
    follow.params_initialized = false
    follow.params_last = 0
    for i = 1, #follow.param_list do
        local param = follow.param_list[i]
        param.idx = -10
    end
end

local function follow_set_params_to_desired()
    local ok = true
    for i = 1, #follow.param_list do
        local param = follow.param_list[i]
        if param.idx < -9 then -- not yet send out
            tnow = getTime()
            if tnow - follow.params_last >= 10 then --decimate to 100ms
                param.idx = -9
                follow.params_last = tnow
                mavlink.sendParamSet(param.handle, param.desired_val)
            end    
            ok = false --not all send out
            break
        end    
    end
    return ok
end

local function follow_params_check()
    local failed_i = 0
    for i = 1, #follow.param_list do
        local res = mavlink.getParamValue(follow.param_list[i].handle)
        if res.updated then
            local val = res.param_value --mavlink.memcpyToInteger(res.param_value)
            follow.param_list[i].val = val
            if (follow.param_list[i].desired_val ~= val) then 
                failed_i = i
            else
                follow.param_list[i].idx = i --validate
            end
        end
    end
    return failed_i
end


local tlast = 0

local function actionDoAlways()
    if not mavsdk.isReceiving() then 
        action.takeoff_triggered = false
        action.takeoff_cntdown = 0
        action_landing_reset()
        action_calibration_reset()
        action.follow_flightmode_at_start = nil
    end
    if not mavsdk.isReceiving() then return end
    
    if not follow.param_registered then -- must be done only once
        follow_register_params()
    end
    
    if not action.initialized then
        action.initialized = true
        tbuttonlong.init(action_land_button)
        tbuttonlong.init(action_arm_button)
        tbuttonlong.init(action_compass_start_button)
        tbutton.init(action_compass_cancel_button)
        ttakeoffbutton_init(action_takeoff_button)
        tmenu.init(action_follow_menu)
        tbuttonlong.init(action_follow_button)
    end
    
    if not follow.params_initialized then
        if follow_set_params_to_desired() then -- all set send out, so we can check
            local failed_i = follow_params_check()
            if failed_i == 0 then -- all good
                follow.params_initialized = true 
            else
                follow.param_list[failed_i].idx = -10 -- resend set for it
            end
        end   
    end

    if action.takeoff_triggered then
        action.display_takingoff_cntdown = getTime() + 100
        if action.takeoff_cntdown == 0 and mavsdk.isArmed() then
            action.takeoff_cntdown = getTime() + 75
        end
        if action.takeoff_cntdown > 0 and getTime() > action.takeoff_cntdown then
            action.takeoff_cntdown = 0
            action.takeoff_triggered = false
            action_send_cmd_takeoff()
        end  
    end    
    
    if action.islanding and mavsdk.getFlightMode() == apCopterFlightMode.Land then
        if not mavsdk.isArmed() then
            --copter has landed and disarmed
            action.islanding = false
            action.landing_restore_flightmode_cntdown = getTime() + 100
        end  
    end
    if action.landing_restore_flightmode_cntdown > 0 then 
        if getTime() > action.landing_restore_flightmode_cntdown then
            action.landing_restore_flightmode_cntdown = 0
            mavsdk.apSetFlightMode(action.landing_flightmode_at_start)
            action.landing_flightmode_at_start = nil
        end
    end    
    
  if action.magiscalibrating then
    action.magcalibrationstarted = true
    
    mag_cal_progress = mavlink.getMessage(mavlink.M_MAG_CAL_PROGRESS, mavlink.getAutopilotIds());
    if mag_cal_progress ~= nil then
        for i = 0,2 do
            if mag_cal_progress.compass_id == i then 
                action.mag[i].completion_pct = mag_cal_progress.completion_pct 
                action.mag[i].cal_status = mag_cal_progress.cal_status
            end
        end    
    end    
    
    mag_cal_report = mavlink.getMessage(mavlink.M_MAG_CAL_REPORT, mavlink.getAutopilotIds());
    if mag_cal_report ~= nil then
        for i = 0,2 do
            if mag_cal_report.compass_id == i then 
                action.mag[i].fitness = mag_cal_report.fitness 
                action.mag[i].cal_status = mag_cal_report.cal_status
            end
        end
    end
    
    if (action.mag[0].cal_status ~= nil or action.mag[1].cal_status ~= nil or action.mag[2].cal_status ~= nil)
       and  (action.mag[0].cal_status == nil or action.mag[0].cal_status >= 4) and
            (action.mag[1].cal_status == nil or action.mag[1].cal_status >= 4) and
            (action.mag[2].cal_status == nil or action.mag[2].cal_status >= 4) then
        action.magiscalibrating = false
        --compass_cancel_button_click()
        play:MagCalibrationFinished()
    end  
  end
end  

local function doPageAction()
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(draw.xmid, 20-4, "ACTIONS", CUSTOM_COLOR+DBLSIZE+CENTER)
--[[    
    if mavsdk.isReceiving() then
        local tnow = getTime()
        if tnow - tlast > 100 then 
            tlast = tnow
            mavlink.sendParamSet(0, 1)
            lcd.drawText(draw.xmid, 20-4, "XXXXXXXXXXXXX", CUSTOM_COLOR+DBLSIZE+CENTER)
        end    
    end    ]]
        
    
    local isarmed = mavsdk.isArmed()
    tobject.enable(action_land_button, isarmed)
    tobject.enable(action_compass_start_button, not isarmed and not action.magcalibrationstarted)
    tobject.visible(action_compass_cancel_button, action.magiscalibrating)
    if action.magcalibrationstarted and not action.magiscalibrating then
        lcd.drawText(290+90, 120, "REBOOT the FC!", CUSTOM_COLOR+CENTER)
    end

    local istakeoffable = mavsdk.isReceiving() and
        status_g.posfix and
        isCopter() and (mavsdk.getFlightMode() ==  apCopterFlightMode.PosHold or
                        mavsdk.getFlightMode() ==  apCopterFlightMode.Guided or
                        mavsdk.getFlightMode() ==  apCopterFlightMode.Loiter)
    local thr = getValue("thr")
    local isthrok = (thr >= -75) and (thr <= 75)
--    tobject.enable(action_takeoff_button, isarmed and istakeoffable and isthrok)
--istakeoffable = true
--isthrok = true
    tobject.enable(action_takeoff_button, istakeoffable and isthrok)
    
    tobject.enable(action_follow_menu, follow.params_initialized)
    tobject.enable(action_follow_button, follow.params_initialized)
    
    tbuttonlong.handle(action_land_button)
    tbuttonlong.handle(action_arm_button)
    tbuttonlong.handle(action_compass_start_button)
    tbutton.handle(action_compass_cancel_button)
    ttakeoffbutton_handle(action_takeoff_button)
    tmenu.handle(action_follow_menu)
    tbuttonlong.handle(action_follow_button)
        
    if action.display_takingoff_cntdown > 0 then
        lcd.drawText(draw.xmid+60, 200, "TAKE OFF", CUSTOM_COLOR+DBLSIZE)
        if getTime() > action.display_takingoff_cntdown then action.display_takingoff_cntdown = 0 end
    elseif action_takeoff_button.armed then
        lcd.drawText(draw.xmid+60+50, 200, "ARM", CUSTOM_COLOR+DBLSIZE)
    end

    if action.magcalibrationstarted then
    for i = 0,2 do
      local y = 160 + i*20
      lcd.drawText(300, y, string.format("%d:", i), CUSTOM_COLOR)
      if action.mag[i].cal_status == nil then
      else
        if action.mag[i].cal_status == 0 then
        elseif action.mag[i].cal_status == 1 then
            lcd.drawText(320, y, "waiting", CUSTOM_COLOR)
        elseif action.mag[i].cal_status < 4 then
            lcd.drawText(320, y, "run", CUSTOM_COLOR)
            lcd.drawNumber(400, y, action.mag[i].completion_pct, CUSTOM_COLOR)
        elseif action.mag[i].cal_status == 4 then
            lcd.setColor(CUSTOM_COLOR, p.GREEN)
            lcd.drawText(320, y, "success", CUSTOM_COLOR)
            lcd.setColor(CUSTOM_COLOR, p.WHITE)
            lcd.drawNumber(400, y, 100*action.mag[i].fitness, CUSTOM_COLOR+PREC2)
        else
            lcd.setColor(CUSTOM_COLOR, p.RED)
            lcd.drawText(320, y, "failed", CUSTOM_COLOR)
        end  
      end
    end
    end
    
    tbuttonlong.draw(action_land_button)
    tbuttonlong.draw(action_arm_button)
    tbuttonlong.draw(action_follow_button)
    tbuttonlong.draw(action_compass_start_button)
    tbutton.draw(action_compass_cancel_button)
    ttakeoffbutton_draw(action_takeoff_button)
    
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if istakeoffable and not isarmed then
        if (thr < -75) then 
          lcd.drawText(draw.xmid, 175, "Throttle too LOW!", CUSTOM_COLOR+MIDSIZE+CENTER)
        end  
        if (thr > 75) then 
          lcd.drawText(draw.xmid, 175, "Throttle too HIGH!", CUSTOM_COLOR+MIDSIZE+CENTER)
        end  
    elseif not isarmed then
        lcd.drawText(draw.xmid, 175, "waiting", CUSTOM_COLOR+MIDSIZE+CENTER)
    end          
    --lcd.drawText(draw.xmid, 175, "Throttle too LOW!", CUSTOM_COLOR+MIDSIZE+CENTER)
    
    tmenu.draw(action_follow_menu)
    
--[[    
    for i=1,#follow.param_list do
        lcd.drawNumber(10, 10+i*20, follow.param_list[i].handle, CUSTOM_COLOR)
        lcd.drawText(100, 10+i*20, follow.param_list[i].param_id, CUSTOM_COLOR)
    end    
]]
end


----------------------------------------------------------------------
-- Page Debug Draw Class
----------------------------------------------------------------------

local function doPageDebug()
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
    
    if page.autopilotEnabled then autopilotDoAlways() end
    if page.cameraEnabled then cameraDoAlways() end
    if page.gimbalEnabled then gimbalDoAlways() end
    if page.actionEnabled then actionDoAlways() end
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
        camera.param_registered = false
        follow.param_registered = false
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


