----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
--
-- Version: see versionStr
-- requires MAVLink-EdgeTx version: v27 (@)
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
local versionStr = "0.27.0.rc05 2021-03-27"


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
    
    -- Set to true if camera should be included in prearm check, else set to false
    cameraPrearmCheck = false,
    
    -- Set to a source if you want control the gimbal pitch, else set to ""
    gimbalPitchSlider = "rs",
    
    -- Set to the appropriate value if you want to start teh gimbal in a given targeting mode, 
    -- else set to nil
    -- 2: MAVLink Targeting, 3: RC Targeting, 4: GPS Point Targeting, 5: SysId Targeting
    gimbalDefaultTargetingMode = 3,
    
    -- Set to true if gimbal should be included in prearm check, else set to false
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
    showDebugPage = true, --false,
}


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

local event_g = event_t16


----------------------------------------------------------------------
-- Color Table
----------------------------------------------------------------------

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

p.BACKGROUND = p.YAAPUBLUE


----------------------------------------------------------------------
-- Wrapper
----------------------------------------------------------------------

local function doAlways(bkgrd)
end


----------------------------------------------------------------------
-- Widget Main entry function, create(), update(), background(), refresh()
----------------------------------------------------------------------

local widgetOptions = {
    { "Switch",       SOURCE,  0 }, --getFieldInfo("sc").id },
    { "Baudrate",     VALUE,   57600, 115200, 115200 },
}
--widgetOptions[#widgetOptions+1] = {"menuSwitch", SOURCE, getFieldInfo("sc").id}


local function widgetCreate(zone, options)
    local w = { zone = zone, options = options }
    return w
end


local function widgetUpdate(widget, options)
    widget.options = options
end


local function widgetBackground(widget)
--    unlockKeys()
    doAlways(1)
end


local event_last = 0

local function widgetRefresh(widget)
    
    
    -- EVT_ENTER_xxx, EVT_TELEM_xx, EVT_MODEL_xxx, EVT_SYS_xxx, EVT_RTN_xxx
    -- EVT_VIRTUAL_DEC, EVT_VIRTUAL_INC
    lockKeys(KEY_ENTER + KEY_MODEL + KEY_TELEM + KEY_SYS + KEY_RTN)
    local event = getEvent()


    doAlways(0)
    
    lcd.clear(CUSTOM_COLOR)
    
  
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawNumber(LCD_W/2, 100, event, CUSTOM_COLOR+DBLSIZE+CENTER)
  
    -- do this post so that the pages can overwrite RTN & SYS use
    if event == event_g.PAGE_NEXT then
      
    elseif event == event_g.PAGE_PREVIOUS then
    end
   
    
  lcd.setColor(CUSTOM_COLOR, p.GREY)
  lcd.drawText(LCD_W/2, 256, "OlliW Telemetry Script  "..versionStr, CUSTOM_COLOR+SMLSIZE+CENTER)
    
end


return { 
    name = "OlliwTel", 
    options = widgetOptions, 
    create = widgetCreate, update = widgetUpdate, refresh = widgetRefresh, background = widgetBackground 
}


