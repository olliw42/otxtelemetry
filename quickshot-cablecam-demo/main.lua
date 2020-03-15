----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
--
-- Version: 0.3.0, 2020-03-15
-- require MAVLink-OpenTx version: v03
--
-- Documentation:
--
-- Discussion:
--
-- Acknowledgements:
-- The design of the autopilot page is much inspired by the
-- Yaapu FrSky Telemetry script. Also, its HUD code is used here. THX!
-- https://github.com/yaapu/FrskyTelemetryScript
-- The draw circle codes were taken from Adafruit's GFX library. THX!
-- https://learn.adafruit.com/adafruit-gfx-graphics-library
----------------------------------------------------------------------


----------------------------------------------------------------------
-- Widget Configuration
----------------------------------------------------------------------
-- Please feel free to set these configuration options as you desire

local config_g = {
    -- Set to true if you want to see the Prearm page, else set to false
    showPrearmPage = true,
    
    -- Set to true if you want to see the Camera page, else set to false
    showCameraPage = true,
    
    -- Set to true if you want to see the Gimbal page, else set to false
    showGimbalPage = true,
    
    -- Set to a (toggle) source if you want control videoon/of & take photo with a switch,
    -- else set to ""
    cameraShootSwitch = "sh",
    
    -- Set to a source if you want control the gimbal pitch, else set to ""
    gimbalPitchSlider = "rs",
    
    -- Set to the appropriate value if you want to start teh gimbal in a given targeting mode, 
    -- else set to nil
    -- 2: MAVLink Targeting, 3: RC Targeting, 4: GPS Point Targeting, 5: SysId Targeting
    gimbalDefaultTargetingMode = 2,
    
    -- Set to true if you use a gimbal and the ArduPilot flight stack,
    -- else set to false (e.g. if you use BetaPilot ;))
    adjustForArduPilotBug = false,
    
    -- Set to true if you do not want to hear any voice, esle set to false
    disableSound = false,
    
    -- not for you ;)
    disableEvents = false, -- not needed, just to have it safe
}



----------------------------------------------------------------------
-- Version
----------------------------------------------------------------------

local versionStr = "0.3.0 2020-03-15"


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


local function playIntro() play("intro") end
local function playMavTelemNotEnabled() play("nomtel") end

local function playTelemOk() play("telok") end    
local function playTelemNo() play("telno") end    
local function playTelemRecovered() play("telrec") end    
local function playTelemLost() play("tellost") end    

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


local pageAutopilotEnabled = true
local pageCameraEnabled = config_g.showCameraPage
local pageGimbalEnabled = config_g.showGimbalPage
local pagePrearmEnabled = config_g.showPrearmPage
local pageQuickshotEnabled = true


local event = 0
local page = 1
local page_min = 1
local page_max = 0

local cPageIdAutopilot = 1
local cPageIdCamera = 2
local cPageIdGimbal = 3
local cPageIdPrearm = 4
local cPageIdQuickshot = 5

local pages = {}
--if pagePrearmEnabled then page_max = page_max+1; pages[page_max] = cPageIdPrearm end
if pageQuickshotEnabled then page_max = page_max+1; pages[page_max] = cPageIdQuickshot; end
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
    if compid == mavlink.MAV_COMP_ID_GIMBAL then
        return "Gimbal1"
    elseif compid >= mavlink.MAV_COMP_ID_GIMBAL2 and compid <= mavlink.MAV_COMP_ID_GIMBAL6 then
        return "Gimbal"..tostring(compid - mavlink.MAV_COMP_ID_GIMBAL2 + 2)
    end
    return "Gimbal"
end    


local function getCameraIdStr(compid)
    if compid >= mavlink.MAV_COMP_ID_CAMERA and compid <= mavlink.MAV_COMP_ID_CAMERA6 then
        return "Camera"..tostring(compid - mavlink.MAV_COMP_ID_CAMERA + 1)
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

apCopterFlightModeAltHold = 2
apCopterFlightModeAuto = 3
apCopterFlightModeGuided = 4
apCopterFlightModeLoiter = 5
apCopterFlightModePosHold = 16

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
statustextSeverity[7] = { "DBG", p.GREY }

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


----------------------------------------------------------------------
-- Status Class
----------------------------------------------------------------------

local status_g = {
    mavtelemEnabled = nil, --allows to track changes
    receiving = nil, --allows to track changes
    flightmode = nil, --allows to track changes
    armed = nil, --allows to track changes
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
        local play = (status_g.armed ~= nil)
        status_g.armed = mavsdk.isArmed()
        if status_g.armed then
            if play then playArmed() end
            status_g.flight_timer_start_10ms = getTime() --if it was nil that's the best guess we can do
        else
            if play then playDisarmed() end
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

local function hasbit(x, p)
    return x % (p + p) >= p       
end

-- THANKS to Adafruit and its GFX library ! 
-- https://learn.adafruit.com/adafruit-gfx-graphics-library

local function drawCircleQuarter(x0, y0, r, corners)
    local f = 1 - r
    local ddF_x = 1
    local ddF_y = -2 * r
    local x = 0
    local y = r
     if corners >= 15 then
        lcd.drawPoint(x0, y0 + r, CUSTOM_COLOR)
        lcd.drawPoint(x0, y0 - r, CUSTOM_COLOR)
        lcd.drawPoint(x0 + r, y0, CUSTOM_COLOR)
        lcd.drawPoint(x0 - r, y0, CUSTOM_COLOR)
    end    
    while x < y do
        if f >= 0 then
            y = y - 1
            ddF_y = ddF_y + 2
            f = f + ddF_y
        end
        x = x + 1
        ddF_x = ddF_x + 2
        f = f + ddF_x
        if hasbit(corners,4) then
            lcd.drawPoint(x0 + x, y0 + y, CUSTOM_COLOR)
            lcd.drawPoint(x0 + y, y0 + x, CUSTOM_COLOR)
        end
        if hasbit(corners,2) then
            lcd.drawPoint(x0 + x, y0 - y, CUSTOM_COLOR)
            lcd.drawPoint(x0 + y, y0 - x, CUSTOM_COLOR)
        end
        if hasbit(corners,8) then
            lcd.drawPoint(x0 - y, y0 + x, CUSTOM_COLOR)
            lcd.drawPoint(x0 - x, y0 + y, CUSTOM_COLOR)
        end
        if hasbit(corners,1) then
            lcd.drawPoint(x0 - y, y0 - x, CUSTOM_COLOR)
            lcd.drawPoint(x0 - x, y0 - y, CUSTOM_COLOR)
        end
    end
end

local function drawCircle(x0, y0, r)
    drawCircleQuarter(x0, y0, r, 15)
end

local function fillCircleQuarter(x0, y0, r, corners)
    local f = 1 - r
    local ddF_x = 1
    local ddF_y = -2 * r
    local x = 0
    local y = r
    local px = x
    local py = y
    if corners >= 3 then
        lcd.drawLine(x0, y0 - r, x0, y0 + r + 1, SOLID, CUSTOM_COLOR)
    end
    while x < y do
        if f >= 0 then
            y = y - 1
            ddF_y = ddF_y + 2
            f = f + ddF_y
        end
        x = x + 1
        ddF_x = ddF_x + 2
        f = f + ddF_x
        if x < (y + 1) then
            if hasbit(corners,1) then
                --writeFastVLine(x0 + x, y0 - y, 2 * y + delta, color);
                lcd.drawLine(x0 + x, y0 - y, x0 + x, y0 + y + 1, SOLID, CUSTOM_COLOR)
            end    
            if hasbit(corners,2) then
                --writeFastVLine(x0 - x, y0 - y, 2 * y + delta, color);
                lcd.drawLine(x0 - x, y0 - y, x0 - x, y0 + y + 1, SOLID, CUSTOM_COLOR)
            end    
        end
        if y ~= py then
            if hasbit(corners,1) then
                --writeFastVLine(x0 + py, y0 - px, 2 * px + delta, color);
                lcd.drawLine(x0 + py, y0 - px, x0 + py, y0 + px + 1, SOLID, CUSTOM_COLOR)
            end    
            if hasbit(corners,2) then
                --writeFastVLine(x0 - py, y0 - px, 2 * px + delta, color);
                lcd.drawLine(x0 - py, y0 - px, x0 - py, y0 + px + 1, SOLID, CUSTOM_COLOR)
            end    
            py = y
        end
        px = x
    end
end

local function fillCircle(x0, y0, r)
    fillCircleQuarter(x0, y0, r, 3)
end

local function drawTriangle(x0, y0, x1, y1, x2, y2)
    lcd.drawLine(x0, y0, x1, y1, SOLID, CUSTOM_COLOR)
    lcd.drawLine(x1, y1, x2, y2, SOLID, CUSTOM_COLOR)
    lcd.drawLine(x2, y2, x0, y0, SOLID, CUSTOM_COLOR)
end

-- code for drawLineWithClipping() is from Yaapu FrSky Telemetry Script, thx!
-- Cohen–Sutherland clipping algorithm
-- https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
local function computeOutCode(x, y, xmin, ymin, xmax, ymax)
    local code = 0;
    if x < xmin then
        code = bit32.bor(code,1);
    elseif x > xmax then
        code = bit32.bor(code,2);
    end
    if y < ymin then
        code = bit32.bor(code,8);
    elseif y > ymax then
        code = bit32.bor(code,4);
    end
    return code;
end

local function drawLineWithClippingXY(x0, y0, x1, y1, xmin, xmax, ymin, ymax, style, color)
    local outcode0 = computeOutCode(x0, y0, xmin, ymin, xmax, ymax);
    local outcode1 = computeOutCode(x1, y1, xmin, ymin, xmax, ymax);
    local accept = false;

    while true do
        if bit32.bor(outcode0,outcode1) == 0 then
            accept = true;
            break;
        elseif bit32.band(outcode0,outcode1) ~= 0 then
            break;
        else
            local x = 0
            local y = 0
            local outcodeOut = outcode0 ~= 0 and outcode0 or outcode1
            if bit32.band(outcodeOut,4) ~= 0 then --point is above the clip window
                x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0)
                y = ymax
            elseif bit32.band(outcodeOut,8) ~= 0 then --point is below the clip window
                x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0)
                y = ymin
            elseif bit32.band(outcodeOut,2) ~= 0 then --point is to the right of clip window
                y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0)
                x = xmax
            elseif bit32.band(outcodeOut,1) ~= 0 then --point is to the left of clip window
                y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0)
                x = xmin
            end
            if outcodeOut == outcode0 then
                x0 = x
                y0 = y
                outcode0 = computeOutCode(x0, y0, xmin, ymin, xmax, ymax)
            else
                x1 = x
                y1 = y
                outcode1 = computeOutCode(x1, y1, xmin, ymin, xmax, ymax)
            end
        end
    end
    if accept then
        lcd.drawLine(x0, y0, x1, y1, style, color)
    end
end

local function drawLineWithClipping(ox, oy, angle, len, xmin, xmax, ymin, ymax, style, color)
    local xx = math.cos(math.rad(angle)) * len * 0.5
    local yy = math.sin(math.rad(angle)) * len * 0.5
  
    local x0 = ox - xx
    local x1 = ox + xx
    local y0 = oy - yy
    local y1 = oy + yy    
  
    drawLineWithClippingXY(x0, y0, x1, y1, xmin, xmax, ymin, ymax, style, color)
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
    -- Vehicle type, model info
    local vehicleClassStr = getVehicleClassStr()
    x = 26
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if vehicleClassStr ~= nil then
        lcd.drawText(x, y, vehicleClassStr..":"..model.getInfo().name, CUSTOM_COLOR)
    else
        lcd.drawText(x, y, model.getInfo().name, CUSTOM_COLOR)
    end    
    -- RSSI
    x = 235
    if mavsdk.isReceiving() then
        local rssi = mavsdk.getRadioRssi()
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        if rssi >= 255 then rssi = 0 end
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
    lcd.drawText(x, y, txvoltage, CUSTOM_COLOR)
    -- Time
    x = LCD_W - 26
    local time = getDateTime()
    local timestr = string.format("%02d:%02d:%02d", time.hour, time.min, time.sec)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
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
    
    -- this code part is from Yaapu FrSky Telemetry Script, thx!
    local dx, dy
    local cx, cy
    if roll == 0 or math.abs(roll) == 180 then
        dx = 0
        dy = pitch * 1.85
        cx = 0
        cy = 21
    else
        dx = math.sin(math.rad(roll)) * pitch
        dy = math.cos(math.rad(roll)) * pitch * 1.85
        cx = math.cos(math.rad(90 + roll)) * 21
        cy = math.sin(math.rad(90 + roll)) * 21
    end

    local widthY = (maxY-minY)
    local ox = (minX+maxX)/2 + dx
    local oy = (minY+maxY)/2 + dy
    local angle = math.tan(math.rad(-roll))
    
    if roll == 0 then -- prevent divide by zero
        lcd.drawFilledRectangle(
          minX, math.max( minY, dy + minY + widthY/2 ),
          maxX - minX, math.min( widthY, widthY/2 - dy + (math.abs(dy) > 0 and 1 or 0) ),
          CUSTOM_COLOR)
  
    elseif math.abs(roll) >= 180 then
        lcd.drawFilledRectangle(
          minX, minY,
          maxX - minX, math.min( widthY, widthY/2 + dy ),
          CUSTOM_COLOR)
    else
        local inverted = math.abs(roll) > 90
        local fillNeeded = false
        local yRect = inverted and 0 or LCD_H
    
        local step = 2
        local steps = widthY/step - 1
        local yy = 0
    
        if 0 < roll and roll < 180 then -- sector ]0,180[
            for s = 0, steps do
                yy = minY + s*step
                xx = ox + (yy - oy)/angle
                if xx >= minX and xx <= maxX then
                    lcd.drawFilledRectangle(xx, yy, maxX-xx+1, step, CUSTOM_COLOR)
                elseif xx < minX then
                    yRect = inverted and math.max(yy,yRect)+step or math.min(yy,yRect)
                    fillNeeded = true
                end
            end
        elseif -180 < roll and roll < 0 then -- sector ]-180,0[
            for s = 0,steps do    
                yy = minY + s*step
                xx = ox + (yy - oy)/angle
                if xx >= minX and xx <= maxX then
                    lcd.drawFilledRectangle(minX, yy, xx-minX, step, CUSTOM_COLOR)
                elseif xx > maxX then
                    yRect = inverted and math.max(yy,yRect)+step or math.min(yy,yRect)
                    fillNeeded = true
                end
            end
        end
        
        if fillNeeded then
            local yMin = inverted and minY or yRect
            local height = inverted and yRect-minY or maxY-yRect
            lcd.drawFilledRectangle(minX, yMin, maxX-minX, height, CUSTOM_COLOR)
        end
    end
  
    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    for i = 1,8 do
        drawLineWithClipping(
            (minX+maxX)/2 + dx - i*cx, (minY+maxY)/2 + dy + i*cy,
            -roll,
            (i % 2 == 0 and 80 or 40), minX + 2, maxX - 2, minY + 10, maxY - 2,
            DOTTED, CUSTOM_COLOR)
        drawLineWithClipping(
            (minX+maxX)/2 + dx + i*cx, (minY+maxY)/2 + dy - i*cy,
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


local function autopilotDoAlways()
    if mavsdk.isStatusTextAvailable() then
        local sev, txt = mavsdk.getStatusText()
        addStatustext(txt,sev)
    end     
end        


local autopilot_showstatustext_tmo = 0

local function doPageAutopilot()
    local tnow = getTime()
    if event == EVT_TELEM_LONG or event == EVT_TELEM_REPT then 
        autopilot_showstatustext_tmo = tnow 
    end  
    if (tnow - autopilot_showstatustext_tmo) < 50 then 
        drawAllStatusTextMessages()
        return
    end    
  
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
local camera_video_timer = 0
local camera_photo_counter = 0 

local camera_menu = { active = false, idx = 0 }

local function camera_menu_set()
    if not mavsdk.cameraIsInitialized() then return end
    
    if camera_menu.idx == 1 then
        mavsdk.cameraSetPhotoMode()
        playPhotoMode()
    elseif camera_menu.idx == 0 then
        mavsdk.cameraSetVideoMode()
        playVideoMode()
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
    if event == EVT_TELEM_LONG then
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
    
    if info.has_video and info.has_photo then
    if event == EVT_ENTER_LONG then
        if not camera_menu.active then      
            camera_menu.active = true
            if status.mode == mavlink.CAMERA_MODE_VIDEO then
                camera_menu.idx = 0
            elseif status.mode == mavlink.CAMERA_MODE_IMAGE then
                camera_menu.idx = 1
            end    
        else
            camera_menu.active = false
            camera_menu_set()
        end
    elseif event == EVT_SYS_FIRST then
        if camera_menu.active then event = 0 end
    elseif event == EVT_RTN_FIRST then
        if camera_menu.active then      
            event = 0
            camera_menu.active = false
        end    
    elseif event == EVT_VIRTUAL_DEC then
        if camera_menu.active then
            camera_menu.idx = camera_menu.idx - 1
            if camera_menu.idx < 0 then camera_menu.idx = 0 end
        end    
    elseif event == EVT_VIRTUAL_INC then
        if camera_menu.active then
            camera_menu.idx = camera_menu.idx + 1
            if camera_menu.idx > 1 then camera_menu.idx = 1 end
        end    
    end    
    end
   
    -- DISPLAY
    local x = 0
    local y = 20
    local xmid = draw.xmid
    
    local video_color = p.GREY
    local photo_color = p.GREY
    if status.mode == mavlink.CAMERA_MODE_VIDEO then video_color = p.WHITE end
    if status.mode == mavlink.CAMERA_MODE_IMAGE then photo_color = p.WHITE end
    
    if camera_menu.active then
        if camera_menu.idx == 0 then
            video_color = p.WHITE
            photo_color = p.GREY
        elseif camera_menu.idx == 1 then
            video_color = p.GREY
            photo_color = p.WHITE
        end    
        lcd.setColor(CUSTOM_COLOR, p.BLUE)
        lcd.drawFilledRectangle(xmid-105, 70, 211, 40, CUSTOM_COLOR+SOLID)
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawRectangle(xmid-105, 70, 211, 40, CUSTOM_COLOR+SOLID)
    end  
  
    if info.has_video and info.has_photo then
        lcd.setColor(CUSTOM_COLOR, video_color)
        lcd.drawText(xmid-55, 70, "Video", CUSTOM_COLOR+DBLSIZE+CENTER)
        lcd.setColor(CUSTOM_COLOR, photo_color)
        lcd.drawText(xmid+55+1, 70, "Photo", CUSTOM_COLOR+DBLSIZE+CENTER)
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawLine(xmid, 76, xmid, 76+27, SOLID, CUSTOM_COLOR)
    elseif info.has_video then
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawText(xmid, 70, "Video", CUSTOM_COLOR+DBLSIZE+CENTER)
    elseif info.has_photo then
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawText(xmid+60, 70, "Photo", CUSTOM_COLOR+DBLSIZE+CENTER)
    end
    
    drawCircle(xmid, 175, 45)
    if status.photo_on or status.video_on then
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawFilledRectangle(xmid-27, 175-27, 54, 54, CUSTOM_COLOR+SOLID)    
    else
        lcd.setColor(CUSTOM_COLOR, p.DARKRED)
        fillCircle(xmid, 175, 39)
    end
    if status.photo_on then
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        lcd.drawText(xmid, 240, "photo shooting...", CUSTOM_COLOR+MIDSIZE+CENTER+BLINK)
    end  
    if status.video_on then
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        lcd.drawText(xmid, 240, "video recording...", CUSTOM_COLOR+MIDSIZE+CENTER+BLINK)
    end
    
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
            camera_video_timer = (getTime() - camera_video_timer_start_10ms)/100
        end    
        local timeStr = timeToStr(camera_video_timer)
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
local gimbal_mode = 6 -- using this to mark as invalid makes it easier to display
local gimbal_hascontrol = true -- used to disable domountcontrol, e.g. when in quickshots
local gimbal_controlispossible = false -- indicates if gimbal control is currently possible
local gimbal_controlisactive = false -- indicates if gimbal control is currently active

local function gimbalSetMode(mode, sound_flag)
    if mode == 1 then
        mavsdk.gimbalSetNeutralMode()
        gimbal_mode = 1
        if sound_flag then playNeutral() end
    elseif mode == 2 then
        mavsdk.gimbalSetMavlinkTargetingMode()
        gimbal_mode = 2
        if sound_flag then playMavlinkTargeting() end
    elseif mode == 3 then
        mavsdk.gimbalSetRcTargetingMode()
        gimbal_mode = 3
        if sound_flag then playRcTargeting() end
    elseif mode == 4 then
        mavsdk.gimbalSetGpsPointMode()
        gimbal_mode = 4
        if sound_flag then playGpsPointTargeting() end
    elseif mode == 5 then
        mavsdk.gimbalSetSysIdTargetingMode()
        gimbal_mode = 5
        if sound_flag then playSysIdTargeting() end
    end
end  

-- this is a wrapper, to account for adjustForArduPilotBug
-- calling mavsdk.gimbalSetPitchYawDeg() sets mode implicitely to MAVLink targeting
local function gimbalSetPitchYawDeg(pitch, yaw)
    if config_g.adjustForArduPilotBug then 
        mavsdk.gimbalSetPitchYawDeg(pitch*100, yaw*100)
    else    
        mavsdk.gimbalSetPitchYawDeg(pitch, yaw)
    end
    gimbal_mode = 2
end

local function gimbalHasControl(flag)
    gimbal_hascontrol = flag
end    

local gimbal_menu = {
    active = false, idx = 6, min = 1, max = 5, initialized = false, default = 3, idx_onenter = 6,
    option = { "Neutral", "MAVLink Targeting", "RC Targeting", "GPS Point", "SysId Targeting", 
               "set mode" },
    selector_width = 240, selector_height = 34,
}

local function gimbal_menu_set()
    if gimbal_menu.idx >= 1 and gimbal_menu.idx <= 5 then 
        gimbalSetMode(gimbal_menu.idx, true)
    else    
        gimbal_menu.idx = 6
    end    
end


local function gimbalDoAlways()
    if not mavsdk.gimbalIsReceiving() then
        return
    end    
  
    -- set gimbal into default MAVLink targeting mode upon connection
    if status_g.gimbal_changed_to_receiving then
        gimbalSetMode(config_g.gimbalDefaultTargetingMode, false)
        gimbal_menu.idx = config_g.gimbalDefaultTargetingMode
        gimbal_menu.initialized = true;
    end  
    
    -- pitch control slider
    local pitch_cntrl = getValue(config_g.gimbalPitchSlider)
    if pitch_cntrl ~= nil then 
        gimbal_pitch_cntrl_deg = -(pitch_cntrl+1008)/1008*45
        if gimbal_pitch_cntrl_deg > 0 then gimbal_pitch_cntrl_deg = 0 end
        if gimbal_pitch_cntrl_deg < -90 then gimbal_pitch_cntrl_deg = -90 end
    end
    
    -- control, but only if "allowed"
    gimbal_controlispossible = false
    gimbal_controlisactive = false
    -- skip if in auto or guided mode as do_mount_control may overwrite _fixed_yaw
    local fm = mavsdk.getFlightMode()
    if fm == apCopterFlightModeAuto or fm == apCopterFlightModeGuided then return end
    if not gimbal_hascontrol then return end
    gimbal_controlispossible = true
    if gimbal_mode == 2 then
        gimbalSetPitchYawDeg(gimbal_pitch_cntrl_deg, 0)
        gimbal_controlisactive = true
    end    
end  


local function doPageGimbal()
    if drawNoGimbal() then return end
    local compid =  mavsdk.gimbalGetInfo().compid
    local gimbalStr = string.format("%s %d", string.upper(getGimbalIdStr(compid)), compid)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(1, 20, gimbalStr, CUSTOM_COLOR)
    local x = 0;
    local y = 20;
    
    if gimbal_controlispossible then 
    if event == EVT_ENTER_LONG then
        if not gimbal_menu.initialized then
            gimbal_menu.initialized = true
            gimbal_menu.idx = gimbal_menu.min
        end
        if not gimbal_menu.active then      
            gimbal_menu.active = true
            gimbal_menu.idx_onenter = gimbal_menu.idx -- save current idx
        else
            gimbal_menu.active = false
            gimbal_menu_set() -- take new idx
        end
    elseif event == EVT_SYS_FIRST then
        if gimbal_menu.active then event = 0 end
    elseif event == EVT_RTN_FIRST then
        if gimbal_menu.active then      
            event = 0
            gimbal_menu.active = false
            gimbal_menu.idx = gimbal_menu.idx_onenter -- restore old idx
        end    
    elseif event == EVT_VIRTUAL_DEC then
        if gimbal_menu.active then
            gimbal_menu.idx = gimbal_menu.idx - 1
            if gimbal_menu.idx < gimbal_menu.min then gimbal_menu.idx = gimbal_menu.min end
        end    
    elseif event == EVT_VIRTUAL_INC then
        if gimbal_menu.active then
            gimbal_menu.idx = gimbal_menu.idx + 1
            if gimbal_menu.idx > gimbal_menu.max then gimbal_menu.idx = gimbal_menu.max end
        end    
    end
    end
    
    -- DISPLAY
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
    
    y = 85
    x = 10
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
    y = 100
    local r = 80
    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    drawCircleQuarter(x, y, r, 4)    
    
    if gimbal_controlisactive then
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        local cangle = gimbal_pitch_cntrl_deg
        drawCircle(x + (r-10)*math.cos(math.rad(cangle)), y - (r-10)*math.sin(math.rad(cangle)), 7)
    else
        lcd.setColor(CUSTOM_COLOR, p.GREY)
    end 
    if gimbal_pitch_cntrl_deg ~= nil then
        lcd.drawNumber(400, 100, gimbal_pitch_cntrl_deg, CUSTOM_COLOR+XXLSIZE+CENTER)
    end    
    
    lcd.setColor(CUSTOM_COLOR, p.RED)
    local gangle = pitch
    if gangle > 10 then gangle = 10 end
    if gangle < -100 then gangle = -100 end
    fillCircle(x + (r-10)*math.cos(math.rad(gangle)), y - (r-10)*math.sin(math.rad(gangle)), 5)
    
    y = 239
    if gimbal_menu.active then
        local w = gimbal_menu.selector_width
        local h = gimbal_menu.selector_height
        lcd.setColor(CUSTOM_COLOR, p.BLUE)
        lcd.drawFilledRectangle(draw.xmid-w/2, y-3, w, h, CUSTOM_COLOR+SOLID)
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawRectangle(draw.xmid-w/2, y-3, w, h, CUSTOM_COLOR+SOLID)
        lcd.drawText(draw.xmid, y, gimbal_menu.option[gimbal_menu.idx], CUSTOM_COLOR+MIDSIZE+CENTER)
    else
        if gimbal_controlispossible then
            lcd.setColor(CUSTOM_COLOR, p.WHITE)
        else    
            lcd.setColor(CUSTOM_COLOR, p.GREY)
        end    
        lcd.drawText(draw.xmid, y, gimbal_menu.option[gimbal_mode], CUSTOM_COLOR+MIDSIZE+CENTER)
    end
end  


----------------------------------------------------------------------
-- Page Prearm Draw Class
----------------------------------------------------------------------

local function doPagePrearm()
    if not mavsdk.isReceiving() then return end
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawText(draw.xmid, 20-4, "PREARM FAIL", CUSTOM_COLOR+DBLSIZE+CENTER)
    
    local xmid = draw.xmid
    local x = 10;
    local y = 60;
    
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, "Autopilot", CUSTOM_COLOR+MIDSIZE)
    
    y = 60
    x = xmid+10
    lcd.drawText(x, y, "Camera", CUSTOM_COLOR+MIDSIZE)
    lcd.drawText(x+20, y+25, "receiving:", CUSTOM_COLOR+MIDSIZE)    
    if mavsdk.isReceiving() and mavsdk.cameraIsReceiving() then    
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawText(x+20+140, y+25, "OK", CUSTOM_COLOR+MIDSIZE)    
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(x+20+140, y+25, "fail", CUSTOM_COLOR+MIDSIZE)    
    end
    
    y = 150
    x = xmid+10
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, "Gimbal", CUSTOM_COLOR+MIDSIZE)
    lcd.drawText(x+20, y+25, "receiving:", CUSTOM_COLOR+MIDSIZE)    
    lcd.drawText(x+20, y+50, "armed:", CUSTOM_COLOR+MIDSIZE)    
    lcd.drawText(x+20, y+75, "checks:", CUSTOM_COLOR+MIDSIZE)    
    if mavsdk.isReceiving() and mavsdk.gimbalIsReceiving() then    
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawText(x+20+140, y+25, "OK", CUSTOM_COLOR+MIDSIZE)    
        if mavsdk.gimbalGetStatus().is_armed then
            lcd.setColor(CUSTOM_COLOR, p.GREEN)
            lcd.drawText(x+20+140, y+50, "OK", CUSTOM_COLOR+MIDSIZE)    
        else
            lcd.setColor(CUSTOM_COLOR, p.RED)
            lcd.drawText(x+20+140, y+50, "fail", CUSTOM_COLOR+MIDSIZE)    
        end  
        if mavsdk.gimbalGetStatus().prearm_ok then
            lcd.setColor(CUSTOM_COLOR, p.GREEN)
            lcd.drawText(x+20+140, y+75, "OK", CUSTOM_COLOR+MIDSIZE)    
        else
            lcd.setColor(CUSTOM_COLOR, p.RED)
            lcd.drawText(x+20+140, y+75, "fail", CUSTOM_COLOR+MIDSIZE)    
        end  
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(x+20+140, y+25, "fail", CUSTOM_COLOR+MIDSIZE)    
        lcd.drawText(x+20+140, y+50, "fail", CUSTOM_COLOR+MIDSIZE)    
        lcd.drawText(x+20+140, y+75, "fail", CUSTOM_COLOR+MIDSIZE)    
    end
end  



----------------------------------------------------------------------
-- Page QuickShot Draw Class
----------------------------------------------------------------------
local debug = false
--debug = true

local cablecam_maxSpeed = 1.5
local cablecam_maxAcceleration = 1.0

local pointA = { lat = nil, lon = nil, yaw = nil, alt = nil, pitch = nil }
local pointB = { lat = nil, lon = nil, yaw = nil, alt = nil, pitch = nil }

local cablecam_max_speed = 2.0 -- m/s
local cablecam_state = 0 -- 0: not running
local cablecam_length = 0 -- m
local cablecam_flightmode_at_start = 0
local cablecam_throttle_at_start = 0

local function posDistance1(lat1,lon1,lat2,lon2)
    --haversine formula
    local R = 6371000
    local theta1 = math.rad(lat1 * 1.0e-7)
    local theta2 = math.rad(lat2 * 1.0e-7)
    local dTheta = math.rad((lat2-lat1) * 1.0e-7)
    local dPhi = math.rad((lon2-lon1) * 1.0e-7)
    local a = math.sin(dTheta*0.5) * math.sin(dTheta*0.5)
    a = a + math.cos(theta1) * math.cos(theta2) * math.sin(dPhi*0.5) * math.sin(dPhi*0.5)
    local c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0-a))
    return R * c
end  

local function dpos_to_m(dposint)
    -- flat earth math
    -- y = rad[(lon-lon0) * 1e-7] * R = pi/180 * 1e-7 * 6.371e6 * (lon-lon0) 
    return math.rad(0.6371) * dposint
end    

local function m_to_dpos(m)
    -- flat earth math
    -- lon-lon0 = 1e7 * deg(y/R) = 180/pi * 1e7 / 6.371e6 * y
    return math.deg(1.0/0.6371) * m
end    

local function posDistance(lat1,lon1,lat2,lon2)
    -- flat earth
    local xScale = math.cos(math.rad((lat1+lat2) * 1.0e-7) * 0.5)
    local x = dpos_to_m(lon2 - lon1) * xScale
    local y = dpos_to_m(lat2 - lat1)
    return math.sqrt(x*x + y*y) 
end  

local function pointAOk()
    -- check if point A is valid
    if pointA.lat == nil then return false end
    if pointA.lon == nil then return false end
    if pointA.alt == nil then return false end
    if pointA.yaw == nil then return false end
    if pointA.lat == 0 then return false end
    if pointA.lon == 0 then return false end
--    if pointA.alt < 1 then return false end
--    if pointA.alt > 4 then return false end
    return true
end

local function pointBOk()
    -- check if point B is valid
    if pointB.lat == nil then return false end
    if pointB.lon == nil then return false end
    if pointB.alt == nil then return false end
    if pointB.yaw == nil then return false end
    if pointB.lat == 0 then return false end
    if pointB.lon == 0 then return false end
--    if pointB.alt < 1 then return false end
--    if pointB.alt > 4 then return false end
    return true
end

local function pointsOk()
    if not pointAOk() then return false end
    if not pointBOk() then return false end
    local length = posDistance(pointB.lat,pointB.lon,pointA.lat,pointA.lon)
    if length < 0.5 then return false end
    return true
end


local function doPageQuickshotNotRunning()
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(5, 45, "A", CUSTOM_COLOR+LEFT+DBLSIZE)
    lcd.drawText(5, 190, "B", CUSTOM_COLOR+LEFT+DBLSIZE)
    if not pointsOk() then lcd.setColor(CUSTOM_COLOR, p.GREY) end
    lcd.drawText(draw.xsize-5, 190, "START", CUSTOM_COLOR+RIGHT+DBLSIZE)
    
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if pointAOk() then 
        lcd.drawNumber(40, 45-1, pointA.lat, CUSTOM_COLOR+LEFT)
        lcd.drawNumber(40, 45+20, pointA.lon, CUSTOM_COLOR+LEFT)
        lcd.drawNumber(40, 45+41, pointA.alt*10, CUSTOM_COLOR+LEFT+PREC1)
    else  
        lcd.drawText(40, 45+4, "---", CUSTOM_COLOR+LEFT+MIDSIZE)
    end  
    if pointBOk() then 
        lcd.drawNumber(40, 190-1, pointB.lat, CUSTOM_COLOR+LEFT)
        lcd.drawNumber(40, 190+20, pointB.lon, CUSTOM_COLOR+LEFT)
        lcd.drawNumber(40, 190+41, pointB.alt*10, CUSTOM_COLOR+LEFT+PREC1)
    else  
        lcd.drawText(40, 190+4, "---", CUSTOM_COLOR+LEFT+MIDSIZE)
    end  
    
    if pointsOk() then
        local length = posDistance(pointB.lat,pointB.lon,pointA.lat,pointA.lon)
        lcd.drawNumber(draw.xmid, 220, length*100, CUSTOM_COLOR+LEFT+PREC2)
    end  
    
    -- pitch control slider
    local pitch_slider = getValue(config_g.gimbalPitchSlider)
    if pitch_slider ~= nil then 
        local pitch_cntrl = -(pitch_slider+1008)/1008*45
        if pitch_cntrl > 0 then pitch_cntrl = 0 end
        if pitch_cntrl < -90 then pitch_cntrl = -90 end
        gimbalSetPitchYawDeg(pitch_cntrl, 0) --yaw is hopefully still ignored
    end    
    
    if event == EVT_MODEL_LONG then
        -- set point A
        pointA.lat = mavsdk.getPositionLatLonInt().lat
        pointA.lon = mavsdk.getPositionLatLonInt().lon
        pointA.alt = mavsdk.getPositionAltitudeRelative()
        pointA.yaw = mavsdk.getPositionHeadingDeg() --mavsdk.getAttYawDeg()
        if mavsdk.gimbalIsReceiving() then
            pointA.pitch = mavsdk.gimbalGetAttPitchDeg()
        else    
            pointA.pitch = 0
        end    
if debug then
  pointA = { lat = 480674167, lon = 78769399, yaw = 0, alt = 3.2, pitch = 0 }
end    
        playHaptic(10,0)
    elseif event == EVT_TELEM_LONG then
        -- set point B
        pointB.lat = mavsdk.getPositionLatLonInt().lat
        pointB.lon = mavsdk.getPositionLatLonInt().lon
        pointB.alt = mavsdk.getPositionAltitudeRelative()
        pointB.yaw = mavsdk.getPositionHeadingDeg()
        if mavsdk.gimbalIsReceiving() then
            pointB.pitch = mavsdk.gimbalGetAttPitchDeg()
        else    
            pointB.pitch = 0
        end    
if debug then
  pointB = { lat = 480673693, lon = 78770177, yaw = 90, alt = 4.2, pitch = 0 }
end
        playHaptic(10,0)
    elseif event == EVT_ENTER_LONG then
        if pointsOk() then --and
--           (mavsdk.getFlightMode() == apCopterFlightModeAltHold or
--           mavsdk.getFlightMode() == apCopterFlightModePosHold or
--           mavsdk.getFlightMode() == apCopterFlightModeLoiter) then
            cablecam_flightmode_at_start = mavsdk.getFlightMode()
            cablecam_throttle_at_start = getValue("thr")
            mavsdk.apSetFlightMode(apCopterFlightModeGuided) -- 4 = Guided
            cablecam_state = 1 -- start
            playHaptic(10,5);playHaptic(10,0)
        else
            playHaptic(5,5);playHaptic(5,5);playHaptic(10,0)
        end    
    end        
end


local cablecam_target = 0
local cablecam_speed = 0
local cablecam_tlast = 0
local cablecam_lat0 = 0
local cablecam_lon0 = 0
local cablecam_xScale = 0
local cablecam_tstart = 0
local cablecam_run = false


local function doPageQuickshotRunning()
    lcd.setColor(CUSTOM_COLOR, p.GREY)
    lcd.drawText(5, 45, "A", CUSTOM_COLOR+LEFT+DBLSIZE)
    lcd.drawText(5, 190, "B", CUSTOM_COLOR+LEFT+DBLSIZE)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(draw.xsize-5, 190, "EXIT", CUSTOM_COLOR+RIGHT+DBLSIZE)
    
    lcd.drawNumber(40, 45-1, pointA.lat, CUSTOM_COLOR+LEFT)
    lcd.drawNumber(40, 45+20, pointA.lon, CUSTOM_COLOR+LEFT)
    lcd.drawNumber(40, 190-1, pointB.lat, CUSTOM_COLOR+LEFT)
    lcd.drawNumber(40, 190+20, pointB.lon, CUSTOM_COLOR+LEFT)
    
    -- set display area
    local pA_x = draw.xmid-100
    local pA_y = 80
    local pB_x = draw.xmid+100
    local pB_y = 200
    
    -- draw cable
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(pA_x, pA_y-11, "x", CUSTOM_COLOR+CENTER)
    lcd.drawText(pB_x, pB_y-11, "x", CUSTOM_COLOR+CENTER)
    lcd.drawLine(pA_x, pA_y, pB_x, pB_y, SOLID, CUSTOM_COLOR)
    
    -- get current vehicle position
    local cur_lat = mavsdk.getPositionLatLonInt().lat
    local cur_lon = mavsdk.getPositionLatLonInt().lon
    local cur_alt = mavsdk.getPositionAltitudeRelative()
    local cur_yaw = mavsdk.getPositionHeadingDeg()
if debug then
  cur_lat = 480674000; cur_lon = 78770000; --cur_yaw = 72
end  
    
    -- read cable stick
    local v = getValue("ail")/1024
    if v > -0.01 and v < 0.01 then v = 0 else cablecam_state = 3 end
    local desiredSpeed = cablecam_maxSpeed * v
    
    local tnow = getTime()
    
    -- initialize, for approach to cable
    if cablecam_state <= 1 then
        cablecam_state = 2
        
        -- get the center position of the area
        cablecam_lat0 = (pointA.lat + pointB.lat) * 0.5
        cablecam_lon0 = (pointA.lon + pointB.lon) * 0.5
        cablecam_xScale = math.cos(math.rad( cablecam_lat0 * 1.0e-7 ))
        
        cablecam_length = posDistance(pointA.lat, pointA.lon, pointB.lat, pointB.lon)
        
        -- find closest path to cable
--[[        
        local xA = (pointA.lon - cablecam_lon0) * cablecam_xScale
        local yA = (pointA.lat - cablecam_lat0)
        local x3 = (cur_lon - cablecam_lon0) * cablecam_xScale
        local y3 = (cur_lat - cablecam_lat0)
        cablecam_target = ( (xA-x3)*(xA+xA) + (yA-y3)*(yA+yA) )/( (xA+xA)*(xA+xA) + (yA+yA)*(yA+yA) )
]]        
        local distToA = posDistance(pointA.lat, pointA.lon, cur_lat, cur_lon)
        local distToB = posDistance(pointB.lat, pointB.lon, cur_lat, cur_lon)
        if distToA > distToB then 
            cablecam_target = 1
        else
            cablecam_target = 0
        end  
        
        cablecam_speed = cablecam_maxSpeed

        cablecam_tlast = 0
        cablecam_tstart = tnow
        cablecam_run = false
    end  
    
    -- wait for guided mode, if we don't have it after 1 sec, jump out
    local getoutofhere = false
    if tnow - cablecam_tstart > 100 then
        if mavsdk.getFlightMode() ~= apCopterFlightModeGuided then getoutofhere = true end
    else
        if mavsdk.getFlightMode() == apCopterFlightModeGuided then cablecam_run = true end
    end 
   
    local doUpdate = false
    if cablecam_run and tnow - cablecam_tlast > 10 then --only every 100 ms
        doUpdate = true
   
        -- move on cable
        local dt = 0.01*(tnow - cablecam_tlast)
        
        --approach desired speed
        if desiredSpeed > cablecam_speed then
            cablecam_speed = cablecam_speed + cablecam_maxAcceleration * dt
            if cablecam_speed > desiredSpeed then cablecam_speed = desiredSpeed end
        elseif desiredSpeed < cablecam_speed then
            cablecam_speed = cablecam_speed - cablecam_maxAcceleration * dt
            if cablecam_speed < desiredSpeed then cablecam_speed = desiredSpeed end
        else    
            cablecam_speed = desiredSpeed
        end
        
        --chose target
        if cablecam_speed > 0.0 then 
            cablecam_target = 1 
        elseif cablecam_speed < 0.0 then  
            cablecam_target = 0 
        end
        
        cablecam_tlast = tnow
    end    
    
    local pCntrl_lat = (pointB.lat - pointA.lat) * cablecam_target + pointA.lat
    local pCntrl_lon = (pointB.lon - pointA.lon) * cablecam_target + pointA.lon
    local pCntrl_alt = pointA.alt
    local pCntrl_speed = cablecam_speed
    
    --local pCntrl_yaw = pointA.yaw
    local dist = posDistance(pointA.lat, pointA.lon, cur_lat, cur_lon) / cablecam_length
    if dist < 0.0 then dist = 0.0 end
    if dist > 1.0 then dist = 1.0 end
    local pCntrl_yaw = (pointB.yaw - pointA.yaw) * dist + pointA.yaw
    local pCntrl_pitch = (pointB.pitch - pointA.pitch) * dist + pointA.pitch
   
    -- draw simulated cable cam position
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawNumber(40, 100, pCntrl_lat, CUSTOM_COLOR+LEFT)
    lcd.drawNumber(40, 100+20, pCntrl_lon, CUSTOM_COLOR+LEFT)
    lcd.drawNumber(40, 100+40, pCntrl_alt*100, CUSTOM_COLOR+LEFT+PREC2)
    lcd.drawNumber(40, 100+60, pCntrl_yaw*10, CUSTOM_COLOR+LEFT+PREC1)
    
    lcd.drawNumber(draw.xmid, 220, pCntrl_speed*100, CUSTOM_COLOR+CENTER+PREC2)
    
    local pCntrl_x = (pB_x - pA_x) * cablecam_target + pA_x
    local pCntrl_y = (pB_y - pA_y) * cablecam_target + pA_y
    
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    drawCircle(pCntrl_x, pCntrl_y, 8)
    lcd.drawText(pCntrl_x, pCntrl_y-11, "x", CUSTOM_COLOR+CENTER)
    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    lcd.drawLine(pCntrl_x, pCntrl_y,
            pCntrl_x + 16*math.sin(math.rad(pCntrl_yaw)), pCntrl_y - 16*math.cos(math.rad(pCntrl_yaw)),
            SOLID, CUSTOM_COLOR)
          
    -- draw current vehicle positon
    local xA = (pointA.lon - cablecam_lon0) * cablecam_xScale
    local yA = pointA.lat - cablecam_lat0
    local xV = (cur_lon - cablecam_lon0) * cablecam_xScale
    local yV = cur_lat - cablecam_lat0
    
    local pV_x = (pB_x - pA_x) * (xA - xV)/(xA + xA) + pA_x 
    local pV_y = (pB_y - pA_y) * (yA - yV)/(yA + yA) + pA_y 
    if pV_x < draw.xmid-200 then pV_x = draw.xmid-200 end
    if pV_x > draw.xmid+200 then pV_x = draw.xmid+200 end
    if pV_y < draw.ymid-100 then pV_y = draw.ymid-100 end
    if pV_y > draw.ymid+100 then pV_y = draw.ymid+100 end
    
    lcd.setColor(CUSTOM_COLOR, p.DARKRED)
    fillCircle(pV_x, pV_y, 5)
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawLine(pV_x, pV_y,
                 pV_x + 16*math.sin(math.rad(cur_yaw)), pV_y - 16*math.cos(math.rad(cur_yaw)),
                 SOLID, CUSTOM_COLOR)
          
    -- move vehicle to cable position
    if doUpdate then
        --mavsdk.apGotoPosIntAltRelYawDeg(pCntrl_lat, pCntrl_lon, pCntrl_alt, pCntrl_yaw)
        --mavsdk.apGotoPosIntAltRel(pCntrl_lat, pCntrl_lon, pCntrl_alt)
        mavsdk.apSimpleGotoPosIntAltRel(pCntrl_lat, pCntrl_lon, pCntrl_alt)
        mavsdk.apSetGroundSpeed(pCntrl_speed)
        if mavsdk.gimbalIsReceiving() then
            gimbalSetPitchYawDeg(pCntrl_pitch, pCntrl_yaw)
        else
            mavsdk.apSetYawDeg(pCntrl_yaw)
        end
    end    
    
    if event == EVT_ENTER_LONG or getoutofhere then
        cablecam_state = 0 -- stop
        playHaptic(10,5);playHaptic(10,0)
        if cablecam_flightmode_at_start ~= apCopterFlightModeAltHold and
            cablecam_flightmode_at_start ~= apCopterFlightModePosHold and
            cablecam_flightmode_at_start ~= apCopterFlightModeLoiter then 
            cablecam_flightmode_at_start = apCopterFlightModeAltHold
        end    
        if not getoutofhere then
            mavsdk.apSetFlightMode(cablecam_flightmode_at_start)
        end  
    end        
end



local function doPageQuickshot()
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawText(draw.xmid, 20-4, "Cable Cam", CUSTOM_COLOR+DBLSIZE+CENTER)
    if not mavsdk.isReceiving() then return end
    
    -- Flight mode
    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    local flightModeStr = getFlightModeStr()
    if flightModeStr ~= nil then
        lcd.drawText(draw.xmid, 50, flightModeStr, CUSTOM_COLOR+MIDSIZE+CENTER)
    end
    
    -- cablecam
    if cablecam_state <= 0 then
        doPageQuickshotNotRunning()
    else
        doPageQuickshotRunning()
    end
    
    if debug then
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(draw.xmid, 238, "!! DEBUG !!", CUSTOM_COLOR+DBLSIZE+CENTER)
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


local function doPageNeedsFullSize(widget)
    event = 0
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawFilledRectangle(widget.zone.x+10, widget.zone.y+10, widget.zone.w-20, widget.zone.h-20, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawFilledRectangle(widget.zone.x+12, widget.zone.y+12, widget.zone.w-24, widget.zone.h-24, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(widget.zone.x+15, widget.zone.y+15, "OlliW Telemetry Script", CUSTOM_COLOR)
    local opt = CUSTOM_COLOR
    if widget.zone.h < 100 then opt = CUSTOM_COLOR+SMLSIZE end
    lcd.drawText(widget.zone.x+15, widget.zone.y+40, "REQUIRES FULL SCREEN", opt)
    lcd.drawText(widget.zone.x+15, widget.zone.y+65, "Please change widget", opt)
    lcd.drawText(widget.zone.x+15, widget.zone.y+85, "screen selection", opt)
end


----------------------------------------------------------------------
-- Wrapper
----------------------------------------------------------------------
local playIntroSound = true


local function doAlways(bkgrd)

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

local function widgetCreate(zone, options)
    local w = { zone = zone, options = options }
    return w
end


local function widgetUpdate(widget, options)
  widget.options = options
end


local function widgetBackground(widget)
    unlockKeys()
    doAlways(1)
end


local function widgetRefresh(widget)
    if widget.zone.h < 250 then 
        doPageNeedsFullSize(widget)
        return
    end
    if isInMenu() then 
        doPageInMenu()
        return
    end
    lcd.backlightOn()
    
    -- EVT_ENTER_xxx, EVT_TELEM_xx, EVT_MODEL_xxx, EVT_SYS_xxx, EVT_RTN_xxx
    -- EVT_VIRTUAL_DEC, EVT_VIRTUAL_INC
    if not config_g.disableEvents then
        lockKeys(KEY_ENTER + KEY_MODEL + KEY_TELEM + KEY_SYS + KEY_RTN)
        event = getEvent()
    else
        event = 0
    end    
    
    gimbalHasControl(pages[page] ~= cPageIdQuickshot) -- don't give it gimbal control during quickshots
    
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
    elseif pages[page] == cPageIdPrearm then
        doPagePrearm()
    elseif pages[page] == cPageIdQuickshot then
        doPageQuickshot()
    end  
  
    -- do this post so that the pages can overwrite RTN & SYS use
    if event == EVT_RTN_FIRST then
        page = page + 1
        if page > page_max then page = page_max end
    elseif event == EVT_SYS_FIRST then
        page = page - 1
        if page < page_min then page = page_min end
    end
    
    drawNoTelemetry()
    
    -- y = 256 is the smallest for normal sized text ??? really ???, no, if there is undersling
    -- normal font is 13 pix height => 243, 256
    if pages[page] == cPageIdAutopilot and #statustext < 3 then
        lcd.setColor(CUSTOM_COLOR, p.GREY)
        lcd.drawText(LCD_W/2, 256, "OlliW Telemetry Script  "..versionStr, CUSTOM_COLOR+SMLSIZE+CENTER)
    end    
    
--    if mavsdk.getBatCapacity() ~= nil then
--        lcd.setColor(CUSTOM_COLOR, p.WHITE)
--        lcd.drawNumber(LCD_W/2, 100, mavsdk.getBatCapacity(), CUSTOM_COLOR+DBLSIZE+CENTER)
--    end  
end


return { 
    name="OlliwTel", 
    options=widgetOptions, 
    create=widgetCreate, update=widgetUpdate, background=widgetBackground, refresh=widgetRefresh 
}


