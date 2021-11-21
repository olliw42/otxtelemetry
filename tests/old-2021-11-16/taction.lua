----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
----------------------------------------------------------------------
-- Page Action Draw Class
----------------------------------------------------------------------

local status_g, p, draw, play, tobject, tbutton, tbuttonlong, tmenu, apCopterFlightMode = ...


local LCD_XMID = draw.xmid


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
    rect = { x = LCD_XMID - 45, y = 175, w = 90, h = 90 },
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



----------------------------------------------------------------------
-- Interface
----------------------------------------------------------------------

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
    lcd.drawText(LCD_XMID, 20-4, "ACTIONS", CUSTOM_COLOR+DBLSIZE+CENTER)
--[[    
    if mavsdk.isReceiving() then
        local tnow = getTime()
        if tnow - tlast > 100 then 
            tlast = tnow
            mavlink.sendParamSet(0, 1)
            lcd.drawText(LCD_XMID, 20-4, "XXXXXXXXXXXXX", CUSTOM_COLOR+DBLSIZE+CENTER)
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
        lcd.drawText(LCD_XMID+60, 200, "TAKE OFF", CUSTOM_COLOR+DBLSIZE)
        if getTime() > action.display_takingoff_cntdown then action.display_takingoff_cntdown = 0 end
    elseif action_takeoff_button.armed then
        lcd.drawText(LCD_XMID+60+50, 200, "ARM", CUSTOM_COLOR+DBLSIZE)
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
          lcd.drawText(LCD_XMID, 175, "Throttle too LOW!", CUSTOM_COLOR+MIDSIZE+CENTER)
        end  
        if (thr > 75) then 
          lcd.drawText(LCD_XMID, 175, "Throttle too HIGH!", CUSTOM_COLOR+MIDSIZE+CENTER)
        end  
    elseif not isarmed then
        lcd.drawText(LCD_XMID, 175, "waiting", CUSTOM_COLOR+MIDSIZE+CENTER)
    end          
    --lcd.drawText(LCD_XMID, 175, "Throttle too LOW!", CUSTOM_COLOR+MIDSIZE+CENTER)
    
    tmenu.draw(action_follow_menu)
    
--[[    
    for i=1,#follow.param_list do
        lcd.drawNumber(10, 10+i*20, follow.param_list[i].handle, CUSTOM_COLOR)
        lcd.drawText(100, 10+i*20, follow.param_list[i].param_id, CUSTOM_COLOR)
    end    
]]
end


return 
    action,
    follow,
    actionDoAlways,
    doPageAction
