----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
----------------------------------------------------------------------
-- Vehicle Dependent Helpers
----------------------------------------------------------------------
local p, fplay = ...


----------------------------------------------------------------------
-- ArduPilot Flight Modes 
----------------------------------------------------------------------

local apCopterFlightMode = {
    AltHold = 2,
    Auto = 3,
    Guided = 4,
    Loiter = 5,
    Land = 9,
    PosHold = 16,
    Follow = 23,
}    


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


local function playFlightModeSound()
    local fmsound = getFlightModeSound()
    if fmsound == nil or fmsound == "" then return end
    fplay(fmsound)
end


----------------------------------------------------------------------
-- ArduPilot Pream Checks
----------------------------------------------------------------------
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
-- StatusText
----------------------------------------------------------------------
 
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


----------------------------------------------------------------------
-- classes
----------------------------------------------------------------------

local ap = {
    CopterFlightMode = apCopterFlightMode,
}



return 
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

  
  
