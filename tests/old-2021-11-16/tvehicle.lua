----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
----------------------------------------------------------------------
-- General Vehicle Dependednt Helpers
----------------------------------------------------------------------
local p = ...


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

local apCopterFlightMode = {
    AltHold = 2,
    Auto = 3,
    Guided = 4,
    Loiter = 5,
    Land = 9,
    PosHold = 16,
    Follow = 23,
}    


local function isCopter()
    return mavsdk.getVehicleClass() == mavsdk.VEHICLECLASS_COPTER
end    


local function isPlane()
    return mavsdk.getVehicleClass() == mavsdk.VEHICLECLASS_PLANE
end    


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


local function getFlightModeSound()
    local fm = mavsdk.getFlightMode();
    local vc = mavsdk.getVehicleClass();
    local fmsound = ""
    if vc == mavsdk.VEHICLECLASS_COPTER then
        fmsound = apCopterFlightModes[fm][2]
    elseif vc == mavsdk.VEHICLECLASS_PLANE then    
        fmsound = apPlaneFlightModes[fm][2]
    end
    return fmsound
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

local function getGpsFixStr(gpsId)
    if gpsId == 1 then return gpsFixes[mavsdk.getGpsFix()] end
    if gpsId == 2 then return gpsFixes[mavsdk.getGps2Fix()] end
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

local function getStatustextCount()
    return #statustext
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

 
return 
  getVehicleClassStr,
  getGimbalIdStr,
  getCameraIdStr,
  isCopter,
  isPlane,
  apCopterFlightMode,
  getFlightModeStr,
  getFlightModeSound,
  getGpsFixStr,
  clearStatustext,
  getStatustextCount,
  addStatustext,
  printStatustext,
  printStatustextLast,
  printStatustextAt

  
  
