----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
--
-- Version: see versionStr
-- requires MAVLink-OpenTx version: v27 (@)
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
-- General
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
p.HUD_SKY = p.SKYBLUE
p.HUD_EARTH = p.OLIVEDRAB
p.BACKGROUND = p.YAAPUBLUE




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
}



local pitch = 0
local roll = 0

local function drawHud()
 
    local minY = draw.hudY
    local maxY = draw.hudY + draw.hudHeight
    local minX = 120
    local maxX = 360
    
    lcd.setColor(CUSTOM_COLOR, p.HUD_SKY)
    lcd.drawFilledRectangle(minX, minY, maxX-minX, maxY-minY, CUSTOM_COLOR+SOLID)
    
    lcd.setColor(CUSTOM_COLOR, p.HUD_EARTH)
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

----------------------------------------------------------------------
-- Widget Main entry function, create(), update(), background(), refresh()
----------------------------------------------------------------------

local widgetOptions = {
    { "Switch",       SOURCE,  0 }, --getFieldInfo("sc").id },
    { "Baudrate",     VALUE,   57600, 115200, 115200 },
}

local function widgetCreate(zone, options)
    local w = { zone = zone, options = options }
    return w
end


local function widgetUpdate(widget, options)
  widget.options = options
end


local function widgetBackground(widget)
end


local function widgetRefresh(widget)
    lcd.resetBacklightTimeout()

    local pitch_cntrl = getValue("rs")
    local roll_cntrl = getValue("ls")
    if pitch_cntrl ~= nil then 
        pitch = -(pitch_cntrl + 1008)/1008*45
        if pitch > 0 then pitch = 0 end
        if pitch < -90 then pitch = -90 end
        pitch = pitch + 15
    end
    if roll_cntrl ~= nil then 
        roll = roll_cntrl/1008*75
        if roll > 75 then roll = 75 end
        if roll < -75 then roll = -75 end
    end

    lcd.setColor(CUSTOM_COLOR, p.BACKGROUND)
    lcd.clear(CUSTOM_COLOR)

    local x = 10
    local y = 10
    local r = 80
    
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    
    lcd.drawNumber(20, 10, pitch, CUSTOM_COLOR)
    lcd.drawNumber(20, 30, roll, CUSTOM_COLOR)
    
    lcd.drawLine(50, 50, 150, 150, SOLID, CUSTOM_COLOR)

    lcd.drawRectangle(25, 100, 110, 110, CUSTOM_COLOR)  
    lcd.drawFilledRectangle(50, 50, 100, 100, CUSTOM_COLOR)  

    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    
    lcd.drawCircle(50, 50, 10, CUSTOM_COLOR)
    lcd.drawFilledCircle(100, 100, 10, CUSTOM_COLOR)
    
    lcd.drawFilledTriangle(200, 150, 250, 160, 220, 180, CUSTOM_COLOR)

    lcd.drawArc(350, 130, 50, 15, 180, CUSTOM_COLOR)
    lcd.drawArc(350, 130, 45, 45, 215, CUSTOM_COLOR)
    lcd.drawArc(350, 130, 40, 90, 270, CUSTOM_COLOR)

    lcd.drawPie(400, 80, 60, -20, 20, CUSTOM_COLOR)
    lcd.drawPie(400, 80, 40, -30, 30, CUSTOM_COLOR)

    lcd.drawAnnulus(400, 250, 30, 60, -30, 30, CUSTOM_COLOR)

    lcd.drawLine(10, 250, 400, 250, SOLID, CUSTOM_COLOR)

    x = 200
    y = 150

    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    --lcd.drawCircleQuarter(x, y, r, 4, CUSTOM_COLOR)    
    lcd.drawArc(x, y, r, 90, 180, CUSTOM_COLOR)
    
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    local cangle = pitch
    lcd.drawCircle(x + (r-10)*math.cos(math.rad(cangle)), y - (r-10)*math.sin(math.rad(cangle)), 7, CUSTOM_COLOR)

    drawHud()

end


return { 
    name="OlliwTel", 
    options=widgetOptions, 
    create=widgetCreate, update=widgetUpdate, refresh=widgetRefresh, background=widgetBackground
}


