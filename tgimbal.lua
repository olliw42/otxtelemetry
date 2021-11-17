----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
----------------------------------------------------------------------
-- Page Gimbal
----------------------------------------------------------------------
local config_g, status_g, p, draw, play, tmenu = ...


local LCD_XMID = draw.xmid


local function drawNoGimbal()
    if mavsdk.isReceiving() and not mavsdk.gimbalIsReceiving() then
        drawWarningBox("no gimbal")
        return true
    end
    return false
end


local function getGimbalIdStr(compid)
    if compid == mavlink.COMP_ID_GIMBAL then
        return "Gimbal1"
    elseif compid >= mavlink.COMP_ID_GIMBAL2 and compid <= mavlink.COMP_ID_GIMBAL6 then
        return "Gimbal"..tostring(compid - mavlink.COMP_ID_GIMBAL2 + 2)
    end
    return "Gimbal"
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
    rect = { x = LCD_XMID - 240/2, y = 235, w = 240, h = 34 },
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


----------------------------------------------------------------------
-- Interface
----------------------------------------------------------------------

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
        lcd.drawText(LCD_XMID, 20-4, "ARMED", CUSTOM_COLOR+DBLSIZE+CENTER)
    elseif prearm_ok then     
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        lcd.drawText(LCD_XMID, 20, "Prearm Checks Ok", CUSTOM_COLOR+MIDSIZE+CENTER)
    else  
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        lcd.drawText(LCD_XMID, 20, "Initializing", CUSTOM_COLOR+MIDSIZE+CENTER)
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


return 
    gimbalDoAlways,
    doPageGimbal

