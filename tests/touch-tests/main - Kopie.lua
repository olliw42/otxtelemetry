----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
--
-- Version: see versionStr
-- requires MAVLink-OpenTx version: v30 (@)
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
local versionStr = "0.30.5 2021-07-06"


----------------------------------------------------------------------
-- Widget Configuration
----------------------------------------------------------------------
-- Please feel free to set these configuration options as you desire

local config_g = {
    -- Set to true if you want to see the Action page, else set to false
    showActionPage = false,
    
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
  
  TOUCH_PAGE_PREVIOUS = TEVT_WIPE_RIGHT,
  TOUCH_PAGE_NEXT     = TEVT_WIPE_LEFT,
  TOUCH_PAGE_DOWN     = TEVT_WIPE_DOWN,
  TOUCH_PAGE_UP       = TEVT_WIPE_UP,
}

local ver, flavor = getVersion()
local event_g = event_t16
local tx16color = false
if flavor == "tx16s" then 
    event_g = event_tx16s 
    tx16color = true
end


----------------------------------------------------------------------
-- General
----------------------------------------------------------------------

local soundsPath = "/SOUNDS/OlliwTel/"


local function play(file)
    if config_g.disableSound then return end
    if isInMenu() then return end
    playFile(soundsPath.."en/"..file..".wav")
end

local function playForce(file)
    if isInMenu() then return end
    playFile(soundsPath.."en/"..file..".wav")
end


local function playIntro() end --play("intro") end
local function playMavTelemNotEnabled() end --play("nomtel") end

local function playTelemOk() play("telok") end    
local function playTelemNo() play("telno") end    
local function playTelemRecovered() play("telrec") end
--local function playTelemRecovered() if not mavsdk.optionIsRssiEnabled() then play("telrec") end end
local function playTelemLost() play("tellost") end
--local function playTelemLost() if not mavsdk.optionIsRssiEnabled() then play("tellost") end end

local function playArmed() play("armed") end    
local function playDisarmed() play("disarmed") end    

local function playPositionFix() play("posfix") end    

local function playVideoMode() play("modvid") end    
local function playPhotoMode() play("modpho") end    
local function playModeChangeFailed() play("modko") end    
local function playVideoOn() play("vidon") end    
local function playVideoOff() play("vidoff") end    
local function playTakePhoto() play("photo") end    

local function playNeutral() play("gneut") end
local function playRcTargeting() play("grctgt") end    
local function playMavlinkTargeting() play("gmavtgt") end
local function playGpsPointTargeting() play("ggpspnt") end
local function playSysIdTargeting() play("gsysid") end

local function playQShotDefault() play("xsdef") end
local function playQShotNeutral() play("xsneut") end
local function playQShotRcControl() play("xsrcctrl") end
local function playQShotPOI() play("xsroi") end
local function playQShotCableCam() play("xscable") end

local function playThrottleWarning() playForce("wthr") end


-- calling lcd. outside of function or inside inits makes ZeroBrain to complain, so per hand, nasty
local p = {
    WHITE = 0xFFFF,         --WHITE
    BLACK = 0x0000,         --BLACK
    --RED = 0xF800, 
    RED = RED,              --RED RGB(229, 32, 30)
    DARKRED = DARKRED,      --RGB(160, 0, 6)
    --GREEN = 0x07E0,  
    GREEN = 0x1CA6,         --otx GREEN = RGB(25, 150, 50) = 0x1CA6
    BLUE = BLUE,            --RGB(0x30, 0xA0, 0xE0)
    YELLOW = YELLOW,        --RGB(0xF0, 0xD0, 0x10)
    GREY = GREY,            --RGB(96, 96, 96)
    DARKGREY = DARKGREY,    --RGB(64, 64, 64)
    LIGHTGREY = LIGHTGREY,  --RGB(180, 180, 180)
    SKYBLUE = 0x867D,       --lcd.RGB(135,206,235)
    OLIVEDRAB = 0x6C64,     --lcd.RGB(107,142,35)
    YAAPUBROWN = 0x6180,    --lcd.RGB(0x63, 0x30, 0x00) 
    YAAPUBLUE = 0x0AB1      -- = 0x08, 0x54, 0x88 
}    
p.HUD_SKY = p.SKYBLUE
p.HUD_EARTH = p.OLIVEDRAB
p.BACKGROUND = p.YAAPUBLUE
p.CAMERA_BACKGROUND = p.YAAPUBLUE
p.GIMBAL_BACKGROUND = p.YAAPUBLUE

local event = 0
local touch = nil

local function touchEvent(e)
    if touch == nil then return false end
    if touch.extEvent == e then return true end
    return false
end

local function touchEventTap(rect)
    if touch == nil then return false end
    if touch.extEvent == TEVT_TAP and
       touch.x >= rect.x and touch.x <= rect.x + rect.w and 
       touch.y >= rect.y and touch.y <= rect.y + rect.h then return true end
    return false
end

local pageAutopilotEnabled = true
local pageActionEnabled = config_g.showActionPage
local pageCameraEnabled = config_g.showCameraPage
local pageGimbalEnabled = config_g.showGimbalPage
local pageDebugEnabled = config_g.showDebugPage

local page = 1
local page_min = 1
local page_max = 0

local page_updown = 0 -- 0, 1, 2, 3

local cPageIdAutopilot = 1
local cPageIdAction = 2
local cPageIdCamera = 3
local cPageIdGimbal = 4
local cPageIdDebug = 10

local pages = {}
if pageDebugEnabled then page_max = page_max+1; pages[page_max] = cPageIdDebug end
if pageActionEnabled then page_max = page_max+1; pages[page_max] = cPageIdAction end
if pageAutopilotEnabled then page_max = page_max+1; pages[page_max] = cPageIdAutopilot; page = page_max end
if pageCameraEnabled then page_max = page_max+1; pages[page_max] = cPageIdCamera end
if pageGimbalEnabled then page_max = page_max+1; pages[page_max] = cPageIdGimbal end


local function getVehicleClassStr()
    local vc = mavsdk.getVehicleClass();
    if vc == mavsdk.VEHICLECLASS_COPTER then
        return "COPTER"
    elseif vc == mavsdk.VEHICLECLASS_PLANE then    
        return "PLANE"
    end    
    return nil
end    


local function getGimbalIdStr(compid)
    if compid == mavlink.COMP_ID_GIMBAL then
        return "Gimbal1"
    elseif compid >= mavlink.COMP_ID_GIMBAL2 and compid <= mavlink.COMP_ID_GIMBAL6 then
        return "Gimbal"..tostring(compid - mavlink.COMP_ID_GIMBAL2 + 2)
    end
    return "Gimbal"
end    


local function getCameraIdStr(compid)
    if compid >= mavlink.COMP_ID_CAMERA and compid <= mavlink.COMP_ID_CAMERA6 then
        return "Camera"..tostring(compid - mavlink.COMP_ID_CAMERA + 1)
    end
    return "Camera"
end    


local function timeToStr(time_s)
    local hours = math.floor(time_s/3600)
    local mins = math.floor(time_s/60 - hours*60)
    local secs = math.floor(time_s - hours*3600 - mins *60)
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end


----------------------------------------------------------------------
-- Vehicle specific
----------------------------------------------------------------------

local apPlaneFlightModes = {}
apPlaneFlightModes[0]   = { "Manual",       "fmman" }
apPlaneFlightModes[1]   = { "Circle",       "fmcirc" }
apPlaneFlightModes[2]   = { "Stabilize",    "fmstab" }
apPlaneFlightModes[3]   = { "Training",     "fmtrain" }
apPlaneFlightModes[4]   = { "ACRO",         "fmacro" }
apPlaneFlightModes[5]   = { "Fly by Wire A", "fmfbwa" }
apPlaneFlightModes[6]   = { "Fly by Wire B", "fmfbwb" }
apPlaneFlightModes[7]   = { "Cruise",       "fmcruise" }
apPlaneFlightModes[8]   = { "Autotune",     "fmat" }
apPlaneFlightModes[10]  = { "Auto",         "fmat" }
apPlaneFlightModes[11]  = { "RTL",          "fmrtl" }
apPlaneFlightModes[12]  = { "Loiter",       "fmloit" }
apPlaneFlightModes[13]  = { "Take Off",     "fmtakeoff" }
apPlaneFlightModes[14]  = { "Avoid ADSB",   "fmavoid" }
apPlaneFlightModes[15]  = { "Guided",       "fmguid" }
apPlaneFlightModes[16]  = { "Initializing", "fminit" }
apPlaneFlightModes[17]  = { "QStabilize",   "fmqstab" }
apPlaneFlightModes[18]  = { "QHover",       "fmqhover" }
apPlaneFlightModes[19]  = { "QLoiter",      "fmqloit" }
apPlaneFlightModes[20]  = { "QLand",        "fmqland" }
apPlaneFlightModes[21]  = { "QRTL",         "fmqrtl" }
apPlaneFlightModes[22]  = { "QAutotune",    "fmqat" }
apPlaneFlightModes[23]  = { "QAcro",        "fmchanged" }

local apCopterFlightModes = {}
apCopterFlightModes[0]  = { "Stabilize",    "fmstab" }
apCopterFlightModes[1]  = { "Acro",         "fmacro" }
apCopterFlightModes[2]  = { "AltHold",      "fmalthld" }
apCopterFlightModes[3]  = { "Auto",         "fmauto" }
apCopterFlightModes[4]  = { "Guided",       "fmguid" }
apCopterFlightModes[5]  = { "Loiter",       "fmloit" }
apCopterFlightModes[6]  = { "RTL",          "fmrtl" }
apCopterFlightModes[7]  = { "Circle",       "fmcirc" }
apCopterFlightModes[9]  = { "Land",         "fmland" }
apCopterFlightModes[11] = { "Drift",        "fmdrift" }
apCopterFlightModes[13] = { "Sport",        "fmsport" }
apCopterFlightModes[14] = { "Flip",         "fmflip" }
apCopterFlightModes[15] = { "AutoTune",     "fmat" }
apCopterFlightModes[16] = { "PosHold",      "fmposhld" }
apCopterFlightModes[17] = { "Brake",        "fmbrake" }
apCopterFlightModes[18] = { "Throw",        "fmthrow" }
apCopterFlightModes[19] = { "Avoid ADSB",   "fmavoid" }
apCopterFlightModes[20] = { "Guided noGPS", "fmgnogps" }
apCopterFlightModes[21] = { "Smart RTL",    "fmsmrtrtl" }
apCopterFlightModes[22] = { "FlowHold",     "fmchanged" }
apCopterFlightModes[23] = { "Follow",       "fmchanged" }
apCopterFlightModes[24] = { "ZigZag",       "fmchanged" }
apCopterFlightModes[25] = { "SystemId",     "fmchanged" }
apCopterFlightModes[26] = { "Autorotate",   "fmchanged" }

local apCopterFlightModeAltHold = 2
local apCopterFlightModeAuto = 3
local apCopterFlightModeGuided = 4
local apCopterFlightModeLoiter = 5
local apCopterFlightModePosHold = 16

local function getFlightModeStr()
    local fm = mavsdk.getFlightMode();
    local vc = mavsdk.getVehicleClass();
    local fmstr
    if vc == mavsdk.VEHICLECLASS_COPTER then
        fmstr = apCopterFlightModes[fm][1]
    elseif vc == mavsdk.VEHICLECLASS_PLANE then    
        fmstr = apPlaneFlightModes[fm][1]
    end    
    if fmstr == nil then fmstr = "unknown" end
    return fmstr
end    

local function playFlightModeSound()
    local fm = mavsdk.getFlightMode();
    local vc = mavsdk.getVehicleClass();
    local fmsound = ""
    if vc == mavsdk.VEHICLECLASS_COPTER then
        fmsound = apCopterFlightModes[fm][2]
    elseif vc == mavsdk.VEHICLECLASS_PLANE then    
        fmsound = apPlaneFlightModes[fm][2]
    end
    if fmsound == nil or fmsound == "" then return end
    play(fmsound)
end


local gpsFixes = {}
gpsFixes[0]  = "No GPS"
gpsFixes[1]  = "No FIX"
gpsFixes[2]  = "2D FIX"
gpsFixes[3]  = "3D FIX"
gpsFixes[4]  = "DGPS"
gpsFixes[5]  = "RTK Float"
gpsFixes[6]  = "RTK Fixed"
gpsFixes[7]  = "Static"
gpsFixes[8]  = "PPP"

local function getGpsFixStr()
    local gf = mavsdk.getGpsFix();
    return gpsFixes[gf]
end    

local function getGps2FixStr()
    local gf = mavsdk.getGps2Fix();
    return gpsFixes[gf]
end    


local statustextSeverity = {}
statustextSeverity[0] = { "EMR", p.RED }
statustextSeverity[1] = { "ALR", p.RED }
statustextSeverity[2] = { "CRT", p.RED }
statustextSeverity[3] = { "ERR", p.RED }
statustextSeverity[4] = { "WRN", p.YELLOW }
statustextSeverity[5] = { "NOT", p.YELLOW }
statustextSeverity[6] = { "INF", p.WHITE }
statustextSeverity[7] = { "DBG", p.LIGHTGREY }

local statustext = {}
local statustext_idx = 0

local function clearStatustext()
    statustext = {}
    statustext_idx = 0
end

local function addStatustext(txt,sev)
    if statustext_idx > 0 and statustext[statustext_idx][1] == txt then -- this is the same as before
        statustext[statustext_idx][3] = statustext[statustext_idx][3] + 1
        return
    end  
    statustext_idx = (statustext_idx % 12) + 1 -- (((statustext_idx-1) + 1) % 10) + 1
    if statustext[statustext_idx] == nil then
        statustext[statustext_idx] = {}
    end
    statustext[statustext_idx][1] = txt
    statustext[statustext_idx][2] = sev
    statustext[statustext_idx][3] = 1
end    

local function printStatustext(idx, x, y, att)
    if idx < 1 or idx > #statustext then return end 
    local sev = statustext[idx][2]
    lcd.setColor(CUSTOM_COLOR, statustextSeverity[sev][2])
    if statustext[idx][3] > 1 then
        local txt = string.format("%s (%dx)", statustext[idx][1], statustext[idx][3])
        lcd.drawText(x, y, txt, CUSTOM_COLOR+att)
    else
        lcd.drawText(x, y, statustext[idx][1], CUSTOM_COLOR+att)
    end  
    
end    

local function printStatustextLast(x, y, att)
    if statustext_idx == 0 then return end 
    printStatustext(statustext_idx, x, y, att)
end

local function printStatustextAt(idx, cnt, x, y, att)
    if statustext_idx == 0 then return end 
    if cnt > #statustext then cnt = #statustext end
    if idx > cnt then return end
    idx = (statustext_idx - cnt + idx - 1) % 12 + 1 --idx = ((statustext_idx-1)-(cnt-1)+(idx-1)) % 12 + 1
    printStatustext(idx, x, y, att)
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
}


-- this function is called always, also when there is no connection
local function checkStatusChanges()
    if status_g.mavtelemEnabled == nil or status_g.mavtelemEnabled ~= mavsdk.mavtelemIsEnabled() then
        status_g.mavtelemEnabled = mavsdk.mavtelemIsEnabled()
        if not mavsdk.mavtelemIsEnabled() then playMavTelemNotEnabled(); end
    end
    if not mavsdk.mavtelemIsEnabled() then return end
    
    if status_g.recieving == nil or status_g.recieving ~= mavsdk.isReceiving() then -- first call or change
        if status_g.recieving == nil then -- first call
            if mavsdk.isReceiving() then playTelemOk() else playTelemNo() end
            clearStatustext()
        else -- change occured    
            if mavsdk.isReceiving() then 
                playTelemRecovered()
                clearStatustext()
            else 
                playTelemLost() 
            end
        end    
        status_g.recieving = mavsdk.isReceiving()
    end
  
    if status_g.armed == nil or status_g.armed ~= mavsdk.isArmed() then -- first call or change occured
        status_g.armed = mavsdk.isArmed()
        if status_g.armed then
            playArmed()
            status_g.flight_timer_start_10ms = getTime() --if it was nil that's the best guess we can do
        else
            playDisarmed()
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
        if status_g.haveposfix then playPositionFix() end
    end
    
    status_g.gimbal_changed_to_receiving = false
    if status_g.gimbal_receiving == nil or status_g.gimbal_receiving ~= mavsdk.gimbalIsReceiving() then
        status_g.gimbal_receiving = mavsdk.gimbalIsReceiving()
        if mavsdk.gimbalIsReceiving() then status_g.gimbal_changed_to_receiving = true end
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
    if page > page_min then
        lcd.drawText(3, y-5, "<", CUSTOM_COLOR+MIDSIZE)
    end  
    if page < page_max then
        lcd.drawText(LCD_W-2, y-5, ">", CUSTOM_COLOR+MIDSIZE+RIGHT)
    end  
    if page_updown > 0 then --0, 1, 2, 3
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawLine(40, 2, 40, 17, SOLID, CUSTOM_COLOR)
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        if page_updown == 1 or page_updown == 3 then 
            lcd.drawLine(24, 8, 30, 2, SOLID, CUSTOM_COLOR)
            lcd.drawLine(30, 2, 36, 8, SOLID, CUSTOM_COLOR)
        end
        if page_updown == 2 or page_updown == 3 then 
            lcd.drawLine(24, 11, 30, 17, SOLID, CUSTOM_COLOR)
            lcd.drawLine(30, 17, 36, 11, SOLID, CUSTOM_COLOR)
        end
    end  
    -- Vehicle type, model info
    local vehicleClassStr = getVehicleClassStr()
    x = 26
    if page_updown > 0 then x = 46 end
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if tx16color then lcd.setColor(CUSTOM_COLOR, p.LIGHTGREY) end -- GRRR????
    if vehicleClassStr ~= nil then
        lcd.drawText(x, y, vehicleClassStr..":"..model.getInfo().name, CUSTOM_COLOR)
    else
        lcd.drawText(x, y, model.getInfo().name, CUSTOM_COLOR)
    end    
    -- RSSI
    x = 235
    if mavsdk.isReceiving() then
        local rssi = mavsdk.getRadioRssi()
        if rssi == nil then rssi = 0 end
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        if rssi < 50 then lcd.setColor(CUSTOM_COLOR, p.RED) end    
        lcd.drawText(x, y, "RS:", CUSTOM_COLOR)
        lcd.drawText(x + 42, y, rssi, CUSTOM_COLOR+CENTER)  
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)    
        lcd.drawText(x, y, "RS:--", CUSTOM_COLOR+BLINK)
    end  
    -- TX voltage
    x = 310
    local txvoltage = string.format("Tx:%.1fv", getValue(getFieldInfo("tx-voltage").id))
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if tx16color then lcd.setColor(CUSTOM_COLOR, p.LIGHTGREY) end -- GRRR????
    lcd.drawText(x, y, txvoltage, CUSTOM_COLOR)
    -- Time
    x = LCD_W - 26
    local time = getDateTime()
    local timestr = string.format("%02d:%02d:%02d", time.hour, time.min, time.sec)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if tx16color then lcd.setColor(CUSTOM_COLOR, p.LIGHTGREY) end -- GRRR????
    lcd.drawText(x, y, timestr, CUSTOM_COLOR+RIGHT)  --SMLSIZE => 4
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


local function _draw_gps1()
    local y = 30
    -- GPS fix
    local gpsfix = mavsdk.getGpsFix()
    if gpsfix >= mavlink.GPS_FIX_TYPE_3D_FIX then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
    end  
    lcd.drawText(2, y+8, getGpsFixStr(), CUSTOM_COLOR+MIDSIZE+LEFT)
    -- Sat
    local gpssat = mavsdk.getGpsSat()
    if gpssat > 99 then gpssat = 0 end
    if gpssat > 5 and gpsfix >= mavlink.GPS_FIX_TYPE_3D_FIX then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
    end
    lcd.drawNumber(5, y+35, gpssat, CUSTOM_COLOR+DBLSIZE)
    -- HDop
    local hdop = mavsdk.getGpsHDop()
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if hdop >= 10 then
        if hdop > 99 then hdop = 99 end
        lcd.drawNumber(55, y+35, hdop, CUSTOM_COLOR+DBLSIZE)
    else  
        lcd.drawNumber(55, y+35, hdop*10, CUSTOM_COLOR+DBLSIZE+PREC1)
    end
end  


local function drawGpsStatus()
    if not mavsdk.isGps2Available() then _draw_gps1(); return end  
    
    local y = 13
    -- GPS fix
    local gpsfix = mavsdk.getGpsFix()
    if gpsfix >= mavlink.GPS_FIX_TYPE_3D_FIX then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
    end  
    lcd.drawText(2, y+8, getGpsFixStr(), CUSTOM_COLOR+MIDSIZE+LEFT)
    -- Sat
    local gpssat = mavsdk.getGpsSat()
    if gpssat > 99 then gpssat = 0 end
    if gpssat > 5 and gpsfix >= mavlink.GPS_FIX_TYPE_3D_FIX then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
    end
    lcd.drawNumber(5, y+30, gpssat, CUSTOM_COLOR+DBLSIZE)
    -- HDop
    local hdop = mavsdk.getGpsHDop()
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if hdop >= 10 then
        if hdop > 99 then hdop = 99 end
        lcd.drawNumber(55, y+30, hdop, CUSTOM_COLOR+DBLSIZE)
    else  
        lcd.drawNumber(55, y+30, hdop*10, CUSTOM_COLOR+DBLSIZE+PREC1)
    end
    
    y = y + 60
    -- GPS2 fix
    gpsfix = mavsdk.getGps2Fix()
    if gpsfix >= mavlink.GPS_FIX_TYPE_3D_FIX then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
    end  
    lcd.drawText(2, y+8, getGps2FixStr(), CUSTOM_COLOR+MIDSIZE+LEFT)
    -- GPS2 Sat
    gpssat = mavsdk.getGps2Sat()
    if gpssat > 99 then gpssat = 0 end
    if gpssat > 5 and gpsfix >= mavlink.GPS_FIX_TYPE_3D_FIX then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
    end
    lcd.drawNumber(5, y+30, gpssat, CUSTOM_COLOR+DBLSIZE)
    -- GPS2 HDop
    hdop = mavsdk.getGps2HDop()
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if hdop >= 10 then
        if hdop > 99 then hdop = 99 end
        lcd.drawNumber(55, y+30, hdop, CUSTOM_COLOR+DBLSIZE)
    else  
        lcd.drawNumber(55, y+30, hdop*10, CUSTOM_COLOR+DBLSIZE+PREC1)
    end
end  


local function drawSpeeds()
    local groundSpeed = mavsdk.getVfrGroundSpeed()
    local airSpeed = mavsdk.getVfrAirSpeed()
    local y = 115
    if mavsdk.isGps2Available() then y = y + 32 end  

    lcd.setColor(CUSTOM_COLOR, p.WHITE) 
    local gs = string.format("GS %.1f m/s", groundSpeed)
    lcd.drawText(2, y, gs, CUSTOM_COLOR)
    local as = string.format("AS %.1f m/s", airSpeed)
    lcd.drawText(2, y+24, as, CUSTOM_COLOR)
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
    for i=1,#statustext do
        printStatustextAt(i, #statustext, 10, 30+(i-1)*19, 0)
    end    
    if #statustext == 0 then 
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
    if page_updown == 0 then -- page had been changed
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
        page_updown = 1
        drawAllStatusTextMessages()
        return
    end
    if autopilot_showprearm then
        page_updown = 2
        drawPrearm()
        return
    end
    
    page_updown = 3

    drawHud()
    drawCompassRibbon()
    drawGroundSpeed()
    drawAltitude()
    drawVerticalSpeed()
    drawGpsStatus()
    drawSpeeds()
    drawBatteryStatus()
    drawStatusBar2()
    drawStatusText()
    
    drawIsInitializing()
end  


----------------------------------------------------------------------
-- Page Camera Draw Class
----------------------------------------------------------------------

local function drawNoCamera()
    if mavsdk.isReceiving() and not mavsdk.cameraIsReceiving() then
        drawWarningBox("no camera")
        return true
    end
    return false
end

local camera_shoot_switch_triggered = false
local camera_shoot_switch_last = 0
local camera_mode_switch_last = 0

local camera_video_timer_start_10ms = 0
local camera_video_timer_10ms = 0
local camera_photo_counter = 0 


local camera_menu = { 
    active = false, idx = 3, initialized = false, m_idx = 3,
    min = 1, max = 2, default = 1, 
    option = { "Video", "Photo", "set mode" },
    rect = { x = draw.xmid - 105, y = 70, w = 211, h = 40 }
}

local function camera_menu_set()
    if not mavsdk.cameraIsInitialized() then return end
    if camera_menu.m_idx >= camera_menu.min and camera_menu.m_idx <= camera_menu.max then 
        camera_menu.idx = camera_menu.m_idx
    else    
        camera_menu.idx = camera_menu.max + 1 -- invalidate
    end    
    if camera_menu.idx == 1 then
        mavsdk.cameraSendVideoMode()
        playVideoMode()
    elseif camera_menu.idx == 2 then
        mavsdk.cameraSendPhotoMode()
        playPhotoMode()
    end
end

local function camera_menu_draw(mode)
    local r = camera_menu.rect
    lcd.setColor(CUSTOM_COLOR, p.BLUE)
    lcd.drawFilledRectangle(r.x, r.y, r.w, r.h, CUSTOM_COLOR+SOLID)
    
    local active_idx = camera_menu.max + 1
    if mode == mavlink.CAMERA_MODE_VIDEO then active_idx = 1 end
    if mode == mavlink.CAMERA_MODE_IMAGE then active_idx = 2 end
    
    if camera_menu.active then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawRectangle(r.x, r.y, r.w, r.h, CUSTOM_COLOR+SOLID)
    end
    
    for i = camera_menu.min, camera_menu.max do
        local color = p.GREY
        if camera_menu.active then
            if i == camera_menu.m_idx then color = p.WHITE end
        else
            if i == active_idx then color = p.WHITE end
        end  
        lcd.setColor(CUSTOM_COLOR, color)
        local x = r.x + r.w/4 + r.w/2*(i - camera_menu.min)
        lcd.drawText(x, r.y, camera_menu.option[i], CUSTOM_COLOR+DBLSIZE+CENTER)
    end  
   
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawLine(draw.xmid, r.y+6, draw.xmid, r.y+r.h-7, SOLID, CUSTOM_COLOR)
end

local function camera_menu_touch()
    if touch == nil then return end
    local r = camera_menu.rect
    for i = camera_menu.min, camera_menu.max do
        local x1 = r.x + r.w/2*(i - camera_menu.min)
        local x2 = r.x + r.w/2*(i - camera_menu.min + 1)
        if touch.x > x1 and touch.x < x2 then
            camera_menu.m_idx = i
            return
        end
    end  
end


local camera_button = { 
    active = false, pressed = false, initialized = false,
    rect = { x = draw.xmid - 45, y = 130, w = 90, h = 90 }
}

local function camera_button_draw()
    local r = camera_button.rect
    local xmid = r.x + r.w/2
    local ymid = r.y + r.h/2
    local radius = r.w/2
    lcd.drawCircle(xmid, ymid, radius, CUSTOM_COLOR)
    if camera_button.pressed then
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawFilledRectangle(xmid-0.6*radius, ymid-0.6*radius, 1.2*radius, 1.2*radius, CUSTOM_COLOR+SOLID)    
    else
        lcd.setColor(CUSTOM_COLOR, p.DARKRED)
        lcd.drawFilledCircle(xmid, ymid, 0.87*radius, CUSTOM_COLOR)
    end
end


local function cameraDoAlways(bkgrd)
    if not mavsdk.cameraIsInitialized() then return end

    camera_shoot_switch_triggered = false
    local shoot_switch = getValue(config_g.cameraShootSwitch)
    if shoot_switch ~= nil then
        if shoot_switch > 500 and camera_shoot_switch_last < 500 then camera_shoot_switch_triggered = true end
        camera_shoot_switch_last = shoot_switch
    end    
    
    if (pages[page] ~= cPageIdCamera or bkgrd > 0) and camera_shoot_switch_triggered then
        local status = mavsdk.cameraGetStatus()
        if status.mode == mavlink.CAMERA_MODE_VIDEO then
            if status.video_on then 
                mavsdk.cameraStopVideo(); playVideoOff()
            else 
                mavsdk.cameraStartVideo(); playVideoOn()
                camera_video_timer_start_10ms = getTime()
            end
        elseif status.mode == mavlink.CAMERA_MODE_IMAGE then
            mavsdk.cameraTakePhoto(); playTakePhoto()
            camera_photo_counter = camera_photo_counter + 1
        end
    end
end


local function doPageCamera()
    if drawNoCamera() then return end
    local info = mavsdk.cameraGetInfo()
    local status = mavsdk.cameraGetStatus()
    local cameraStr = string.format("%s %d", string.upper(getCameraIdStr(info.compid)), info.compid)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(1, 20, cameraStr, CUSTOM_COLOR)
    if not mavsdk.cameraIsInitialized() then
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(LCD_W/2, 120, "camera module is initializing...", CUSTOM_COLOR+MIDSIZE+CENTER)
        return
    end  
    --local vendorStr = info.vendor_name
    --lcd.drawText(0, 40, vendorStr, CUSTOM_COLOR)
    local modelStr = info.model_name
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(LCD_W-1, 20, modelStr, CUSTOM_COLOR+RIGHT)
    
    -- CAMERA SHOOT handling
    local camera_shoot = false
    if camera_shoot_switch_triggered then
        camera_shoot = true
    end
    if touchEventTap(camera_button.rect) or event == event_g.BTN_B_LONG then
        camera_shoot = true
    end  
    if not mavsdk.cameraIsInitialized() then
        camera_shoot = false
    end    
    
    if camera_shoot then 
        camera_shoot = false
        if status.mode == mavlink.CAMERA_MODE_VIDEO then
            if status.video_on then 
                mavsdk.cameraStopVideo(); playVideoOff()
            else 
                mavsdk.cameraStartVideo(); playVideoOn()
                camera_video_timer_start_10ms = getTime()
            end
        elseif status.mode == mavlink.CAMERA_MODE_IMAGE then
            mavsdk.cameraTakePhoto(); playTakePhoto()
            camera_photo_counter = camera_photo_counter + 1
        end
    end
    
    if info.has_video and info.has_photo and not status.video_on then
    if touchEventTap(camera_menu.rect) then
        if not camera_menu.initialized then
            camera_menu.idx = camera_menu.default
            camera_menu.initialized = true
        end
        camera_menu_touch()
        camera_menu.active = false
        camera_menu_set()
    elseif touchEvent(TEVT_TAP) then
        if camera_menu.active then
            touch = nil
            camera_menu.active = false
        end
    elseif event == event_g.BTN_ENTER_LONG then
        if not camera_menu.initialized then
            camera_menu.idx = camera_menu.default
            camera_menu.initialized = true
        end
        if not camera_menu.active then      
            camera_menu.active = true
            if status.mode == mavlink.CAMERA_MODE_VIDEO then
                camera_menu.m_idx = 1
            elseif status.mode == mavlink.CAMERA_MODE_IMAGE then
                camera_menu.m_idx = 2
            end    
        else
            camera_menu.active = false
            camera_menu_set()
        end
    elseif event == event_g.OPTION_PREVIOUS then
        if camera_menu.active then
            camera_menu.m_idx = camera_menu.m_idx - 1
            if camera_menu.m_idx < camera_menu.min then camera_menu.m_idx = camera_menu.min end
        end    
    elseif event == event_g.OPTION_NEXT then
        if camera_menu.active then
            camera_menu.m_idx = camera_menu.m_idx + 1
            if camera_menu.m_idx > camera_menu.max then camera_menu.m_idx = camera_menu.max end
        end    
    elseif event == event_g.OPTION_CANCEL then
        if camera_menu.active then      
            event = 0
            camera_menu.active = false
        end    
    elseif event == event_g.PAGE_PREVIOUS or event == event_g.PAGE_NEXT then -- must come last
        if camera_menu.active then event = 0 end
    end    
    end
   
    -- DISPLAY
    if info.has_video and info.has_photo then
        camera_menu_draw(status.mode)
    elseif info.has_video then
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawText(draw.xmid, 70, "Video", CUSTOM_COLOR+DBLSIZE+CENTER)
    elseif info.has_photo then
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawText(draw.xmid, 70, "Photo", CUSTOM_COLOR+DBLSIZE+CENTER)
    end
    
    camera_button.pressed = status.video_on or status.photo_on
    camera_button_draw()
    
    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    if status.video_on then
        lcd.drawText(draw.xmid, 240, "video recording...", CUSTOM_COLOR+MIDSIZE+CENTER+BLINK)
    end
    if status.photo_on then
        lcd.drawText(draw.xmid, 240, "photo shooting...", CUSTOM_COLOR+MIDSIZE+CENTER+BLINK)
    end  
    
    local x = 0
    local y = 20
    y = 120
    x = 10
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
        lcd.drawText(x+10, y+20, remainingStr, CUSTOM_COLOR+MIDSIZE)
        y = y+50
    end
    if status.battery_voltage ~= nil then
        lcd.drawText(x, y, "battery voltage", CUSTOM_COLOR)
        local voltageStr = string.format("%.1f v", status.battery_voltage)
        lcd.drawText(x+10, y+20, voltageStr, CUSTOM_COLOR)
    end
   
    y = 175-16
    x = 375
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if status.mode == mavlink.CAMERA_MODE_VIDEO then 
        if status.video_on then
            camera_video_timer_10ms = (getTime() - camera_video_timer_start_10ms)/100
        end    
        local timeStr = timeToStr(camera_video_timer_10ms)
        lcd.drawText(x, y, timeStr, CUSTOM_COLOR+MIDSIZE+CENTER)
    elseif status.mode == mavlink.CAMERA_MODE_IMAGE then 
        local countStr = string.format("%04d", camera_photo_counter)
        lcd.drawText(x, y, countStr, CUSTOM_COLOR+MIDSIZE+CENTER)
    end
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

local gimbal_pitch_cntrl_deg = nil
local gimbal_yaw_cntrl_deg = 0
local gimbal_qshot_mode = nil
local gimbal_qshot_status_last_10ms = 0

local function gimbalSetQShotMode(mode, sound_flag)
    if mode == 1 then
        gimbal_qshot_mode = mavsdk.QSHOT_MODE_DEFAULT
        mavsdk.qshotSendCmdConfigure(gimbal_qshot_mode, 0)
        if sound_flag then playQShotDefault() end
    elseif mode == 2 then
        gimbal_qshot_mode = mavsdk.QSHOT_MODE_NEUTRAL
        mavsdk.qshotSendCmdConfigure(gimbal_qshot_mode, 0)
        if sound_flag then playQShotNeutral() end
    elseif mode == 3 then
        gimbal_qshot_mode = mavsdk.QSHOT_MODE_RC_CONTROL
        mavsdk.qshotSendCmdConfigure(gimbal_qshot_mode, 0)
        if sound_flag then playQShotRcControl() end
    elseif mode == 4 then
        gimbal_qshot_mode = mavsdk.QSHOT_MODE_POI
        mavsdk.qshotSendCmdConfigure(gimbal_qshot_mode, 0)
        if sound_flag then playQShotPOI() end
    elseif mode == 5 then
        gimbal_qshot_mode = mavsdk.QSHOT_MODE_CABLECAM
        mavsdk.qshotSendCmdConfigure(gimbal_qshot_mode, 0)
        if sound_flag then playQShotCableCam() end
    end
end  


local gimbal_menu = {
    active = false, idx = 6, initialized = false, m_idx = 6,
    min = 1, max = 4, default = 1, 
    option = { "Default", "Neutral", "RC Control", "POI Trageting", "Cable Cam", 
               "set mode" },
    rect = { x = draw.xmid - 240/2, y = 236, w = 240, h = 34 }
}

local function gimbal_menu_set()
    if gimbal_menu.m_idx >= gimbal_menu.min and gimbal_menu.m_idx <= gimbal_menu.max then 
        gimbal_menu.idx = gimbal_menu.m_idx
        gimbalSetQShotMode(gimbal_menu.idx, true)
    else    
        gimbal_menu.idx = gimbal_menu.max + 1 -- invalidate
    end    
end

local function gimbal_menu_optionstr()
    return gimbal_menu.option[gimbal_menu.idx]
end

local function gimbal_menu_popup_draw()
    local w = gimbal_menu.rect.w
    local h = gimbal_menu.rect.h
    local ph = gimbal_menu.rect.h * (gimbal_menu.max - gimbal_menu.min + 1)
    local px = draw.xmid - w/2
    local py = draw.ymid - ph/2
    lcd.setColor(CUSTOM_COLOR, p.BLUE)
    lcd.drawFilledRectangle(px, py, w, ph, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.GREEN)
    lcd.drawFilledRectangle(px, py + h*(gimbal_menu.m_idx-1), w, h, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawRectangle(px, py, w, ph, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    for i = gimbal_menu.min, gimbal_menu.max do
        lcd.drawText(draw.xmid, py + 3 + h*(i-1), gimbal_menu.option[i], CUSTOM_COLOR+MIDSIZE+CENTER)
    end    
end

local function gimbal_menu_popup_rect()
  local ph = gimbal_menu.rect.h * (gimbal_menu.max - gimbal_menu.min + 1)
  return {
      x = draw.xmid - gimbal_menu.rect.w/2, 
      y = draw.ymid - ph/2,
      w = gimbal_menu.rect.w,
      h = ph
  }
end
  
local function gimbal_menu_popup_touch()
    if touch == nil then return end
    local h = gimbal_menu.rect.h
    local ph = gimbal_menu.rect.h * (gimbal_menu.max - gimbal_menu.min + 1)
    local py = draw.ymid - ph/2
    for i = gimbal_menu.min, gimbal_menu.max do
        if touch.y > py + h*(i-1) and touch.y < py + h*i then
            gimbal_menu.m_idx = i
            return
        end
    end  
end

local function gimbal_menu_draw()
    local r = gimbal_menu.rect
    lcd.setColor(CUSTOM_COLOR, p.BLUE)
    lcd.drawFilledRectangle(r.x, r.y, r.w, r.h, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(r.x + r.w/2, r.y + 3, gimbal_menu_optionstr(), CUSTOM_COLOR+MIDSIZE+CENTER)
    if gimbal_menu.active then
        gimbal_menu_popup_draw()
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawRectangle(r.x, r.y, r.w, r.h, CUSTOM_COLOR+SOLID)
    end
end


local gimbal_slider = {
    active = false, idx = 6, initialized = false,
    min = 0, max = -90, default = 0, 
    rect = { x = 350, y = 100, w = 20, h = 100 }
}

local function gimbal_slider_draw()
    local r = gimbal_slider.rect
    lcd.setColor(CUSTOM_COLOR, p.GREY)
    lcd.drawFilledRectangle(r.x, r.y, r.w, r.h, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawRectangle(r.x, r.y, r.w, r.h, CUSTOM_COLOR+SOLID)
    
    if gimbal_slider.active then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawRectangle(r.x, r.y, r.w, r.h, CUSTOM_COLOR+SOLID)
    end
end



-- this is a wrapper, to account for gimbalAdjustForArduPilotBug
-- if V1, calling mavsdk.gimbalSendPitchYawDeg() sets mode implicitely to MAVLink targeting
local function gimbalSetPitchYawDeg(pitch, yaw)
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
        if gimbal_qshot_mode == mavsdk.QSHOT_MODE_DEFAULT then
            mavsdk.gimbalClientSetFlags(mavsdk.GMFLAGS_GCS_ACTIVE)
        elseif gimbal_qshot_mode == mavsdk.QSHOT_MODE_NEUTRAL then
            mavsdk.gimbalClientSetNeutral(1)
            mavsdk.gimbalClientSetFlags(0)
        elseif gimbal_qshot_mode == mavsdk.QSHOT_MODE_RC_CONTROL then
            mavsdk.gimbalClientSetFlags(mavsdk.GMFLAGS_RC_ACTIVE)
        elseif gimbal_qshot_mode == mavsdk.QSHOT_MODE_POI then
            mavsdk.gimbalClientSetFlags(mavsdk.GMFLAGS_AUTOPILOT_ACTIVE)
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
    if not mavsdk.gimbalIsReceiving() then
        return
    end
  
    -- set gimbal into default MAVLink targeting mode upon connection
    if status_g.gimbal_changed_to_receiving then
        gimbal_menu.idx = gimbal_menu.default
        gimbal_menu.initialized = true;
        gimbalSetQShotMode(gimbal_menu.idx, false)
    end  
    
    -- pitch control slider
    local pitch_cntrl = getValue(config_g.gimbalPitchSlider)
    if pitch_cntrl ~= nil then 
        gimbal_pitch_cntrl_deg = -(pitch_cntrl+1008)/1008*45
        if gimbal_pitch_cntrl_deg > 0 then gimbal_pitch_cntrl_deg = 0 end
        if gimbal_pitch_cntrl_deg < -90 then gimbal_pitch_cntrl_deg = -90 end
    end
    -- yaw control slider
    local yaw_cntrl = getValue(config_g.gimbalYawSlider)
    if yaw_cntrl ~= nil then 
        gimbal_yaw_cntrl_deg = yaw_cntrl/1008*75
        if gimbal_yaw_cntrl_deg > 75 then gimbal_yaw_cntrl_deg = 75 end
        if gimbal_yaw_cntrl_deg < -75 then gimbal_yaw_cntrl_deg = -75 end
    end
    
    gimbalSetPitchYawDeg(gimbal_pitch_cntrl_deg, gimbal_yaw_cntrl_deg)
    
    --send qshot status every 1 sec
    local tnow = getTime()
    if (tnow - gimbal_qshot_status_last_10ms) >= 100 then --100 = 1000ms
        gimbal_qshot_status_last_10ms = gimbal_qshot_status_last_10ms + 100
        mavsdk.qshotSendStatus(gimbal_qshot_mode, 0)
    end
    
end


local function doPageGimbal()
    if drawNoGimbal() then return end
    local x = 0
    local y = 0
    
    -- MENU HANDLING
    if not gimbal_menu.active and touchEventTap(gimbal_menu.rect) then
        if not gimbal_menu.initialized then
            gimbal_menu.initialized = true
            gimbal_menu.idx = gimbal_menu.default
        end
        gimbal_menu.active = true
        gimbal_menu.m_idx = gimbal_menu.idx -- save current idx
    elseif gimbal_menu.active and touchEventTap(gimbal_menu_popup_rect()) then
        gimbal_menu_popup_touch()
        gimbal_menu.active = false
        gimbal_menu_set() -- take new idx
    elseif touch.myEvent == TEVT_TAP then
        if gimbal_menu.active then
            touch = nil
            gimbal_menu.active = false
        end
    elseif event == event_g.BTN_ENTER_LONG then
        if not gimbal_menu.initialized then
            gimbal_menu.initialized = true
            gimbal_menu.idx = gimbal_menu.default
        end
        if not gimbal_menu.active then      
            gimbal_menu.active = true
            gimbal_menu.m_idx = gimbal_menu.idx -- save current idx
        else
            gimbal_menu.active = false
            gimbal_menu_set() -- take new idx
        end
    elseif event == event_g.OPTION_PREVIOUS then
        if gimbal_menu.active then
            gimbal_menu.m_idx = gimbal_menu.m_idx - 1
            if gimbal_menu.m_idx < gimbal_menu.min then gimbal_menu.m_idx = gimbal_menu.min end
        end    
    elseif event == event_g.OPTION_NEXT then
        if gimbal_menu.active then
            gimbal_menu.m_idx = gimbal_menu.m_idx + 1
            if gimbal_menu.m_idx > gimbal_menu.max then gimbal_menu.m_idx = gimbal_menu.max end
        end    
    elseif event == event_g.OPTION_CANCEL then
        if gimbal_menu.active then      
            event = 0
            gimbal_menu.active = false
        end    
    elseif event == event_g.PAGE_PREVIOUS or event == event_g.PAGE_NEXT then -- must come last
        if gimbal_menu.active then event = 0 end
    end
    
    -- DISPLAY
    local info =  mavsdk.gimbalGetInfo()
    local compid =  info.compid
    local gimbalStr = string.format("%s %d", string.upper(getGimbalIdStr(compid)), compid)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(1, 20, gimbalStr, CUSTOM_COLOR)
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
    if gimbal_pitch_cntrl_deg ~= nil then
        local cangle = gimbal_pitch_cntrl_deg
        lcd.drawCircle(x + (r-10)*math.cos(math.rad(cangle)), y - (r-10)*math.sin(math.rad(cangle)), 7, CUSTOM_COLOR)
    end    
    if gimbal_pitch_cntrl_deg ~= nil then
        lcd.drawNumber(400, y, gimbal_pitch_cntrl_deg, CUSTOM_COLOR+XXLSIZE+CENTER)
    end    
    if gimbal_yaw_cntrl_deg ~= nil and config_g.gimbalYawSlider ~= "" then
        lcd.drawNumber(400, y+60, gimbal_yaw_cntrl_deg, CUSTOM_COLOR+CENTER)
    end    
    
    lcd.setColor(CUSTOM_COLOR, p.RED)
    local gangle = pitch
    if gangle > 10 then gangle = 10 end
    if gangle < -100 then gangle = -100 end
    lcd.drawFilledCircle(x + (r-10)*math.cos(math.rad(gangle)), y - (r-10)*math.sin(math.rad(gangle)), 5, CUSTOM_COLOR)

    -- MENU DISPLAY
    gimbal_menu_draw()
    --gimbal_slider_draw()
end  


----------------------------------------------------------------------
-- Page Action Draw Class
----------------------------------------------------------------------

local function doPageAction()
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


----------------------------------------------------------------------
-- Wrapper
----------------------------------------------------------------------
local playIntroSound = true

local function doAlways(bkgrd)
    mavsdk.radioDisableRssiVoice(1)
  
    if playIntroSound then    
        playIntroSound = false
        playIntro()
    end  

    checkStatusChanges()
    
    if pageAutopilotEnabled then autopilotDoAlways() end
    if pageCameraEnabled then cameraDoAlways(bkgrd) end
    if pageGimbalEnabled then gimbalDoAlways() end
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

local event_last = 0

local function widgetRefresh(widget)
    if widget.rect.h < 250 then 
        doPageNeedsFullSize(widget.rect)
        return res
    end
    if isInMenu() then 
        doPageInMenu()
        return res
    end
    lcd.resetBacklightTimeout()
    
    -- EVT_ENTER_xxx, EVT_TELEM_xx, EVT_MODEL_xxx, EVT_SYS_xxx, EVT_RTN_xxx
    -- EVT_VIRTUAL_DEC, EVT_VIRTUAL_INC
    if not config_g.disableEvents then
        event = getEvent(KEY_ENTER + KEY_MODEL + KEY_TELEM + KEY_SYS + KEY_RTN)
        touch = getTouchState()
    else
        event = 0
        touch = nil
    end    

    doAlways(0)
    
    if pages[page] == cPageIdAutopilot then
        lcd.setColor(CUSTOM_COLOR, p.BACKGROUND)
    elseif pages[page] == cPageIdCamera then   
        lcd.setColor(CUSTOM_COLOR, p.CAMERA_BACKGROUND)
    elseif pages[page] == cPageIdGimbal then   
        lcd.setColor(CUSTOM_COLOR, p.GIMBAL_BACKGROUND)
    else    
        lcd.setColor(CUSTOM_COLOR, p.BACKGROUND)
    end  
    lcd.clear(CUSTOM_COLOR)
    
    drawStatusBar()

    if pages[page] == cPageIdAutopilot then
        doPageAutopilot()
    elseif pages[page] == cPageIdCamera then   
        doPageCamera()
    elseif pages[page] == cPageIdGimbal then   
        doPageGimbal()
    elseif pages[page] == cPageIdAction then
        doPageAction()
    elseif pages[page] == cPageIdDebug then
        doPageDebug()
    end  
  
    -- do this post so that the pages can overwrite RTN & SYS use
    if event == event_g.PAGE_NEXT or touchEvent(event_g.TOUCH_PAGE_NEXT) then
        page = page + 1
        if page > page_max then page = page_max else page_updown = 0 end
    elseif event == event_g.PAGE_PREVIOUS or touchEvent(event_g.TOUCH_PAGE_PREVIOUS) then
        page = page - 1
        if page < page_min then page = page_min else page_updown = 0 end
    end
    
    if pages[page] ~= cPageIdDebug then
      drawNoTelemetry()
    end    
    
    -- y = 256 is the smallest for normal sized text ??? really ???, no, if there is undersling
    -- normal font is 13 pix height => 243, 256
    if pages[page] == cPageIdAutopilot and #statustext < 3 then
        lcd.setColor(CUSTOM_COLOR, p.GREY)
        lcd.drawText(LCD_W/2, 256, "OlliW Telemetry Script  "..versionStr.."  fw "..mavsdk.getVersion(), CUSTOM_COLOR+SMLSIZE+CENTER)
    end    
    
--    if mavsdk.getBatCapacity() ~= nil then
--        lcd.setColor(CUSTOM_COLOR, p.WHITE)
--        lcd.drawNumber(LCD_W/2, 100, mavsdk.getBatCapacity(), CUSTOM_COLOR+DBLSIZE+CENTER)
--    end  

--    lcd.drawNumber(LCD_W-1, 200, event, CUSTOM_COLOR+RIGHT)
--    if event > 0 then event_last = event end
--    lcd.drawNumber(LCD_W-1, 215, event_last, CUSTOM_COLOR+RIGHT)
end


return { 
    name="OlliwTel", 
    options=widgetOptions, 
    create=widgetCreate, update=widgetUpdate, background=widgetBackground, refresh=widgetRefresh 
}


