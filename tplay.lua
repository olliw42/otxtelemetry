----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
----------------------------------------------------------------------
-- Play Functions
----------------------------------------------------------------------
local fplay, fplayForce = ...

local play = {}

function play:Intro() return end --fplay("intro") end
function play:MavTelemNotEnabled() return end --fplay("nomtel") end

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

function play:ThrottleTooLow() return end
function play:ThrottleTooHigh() return end
function play:TakeOff() fplay("takeoff") end    
function play:MagCalibrationStarted() fplay("mcalsrt") end
function play:MagCalibrationFinished() fplay("mcalend") end

return play