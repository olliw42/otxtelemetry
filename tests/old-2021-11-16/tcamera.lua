----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
----------------------------------------------------------------------
-- Page Camera Draw Class
----------------------------------------------------------------------
local config_g, status_g, p, draw, play, drawWarningBox, getCameraIdStr, timeToStr, touchEventTap, tobjstate, tobject, tmenu = ...


local LCD_XMID = draw.xmid


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
    rect = { x = LCD_XMID - 60, y = 45, w = 120, h = 37 },
    min = 1, max = 2, default = 1, 
    option = { "Video", "Photo" },
    click_func = camera_menu_click;
}

local camera_button = { 
    rect = { x = LCD_XMID - 45, y = 105, w = 90, h = 90 },
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


----------------------------------------------------------------------
-- Interface
----------------------------------------------------------------------

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
        lcd.drawText(LCD_XMID, 215, timeStr, CUSTOM_COLOR+MIDSIZE+CENTER)
    elseif status.mode == mavlink.CAMERA_MODE_IMAGE then 
        local countStr = string.format("%04d", camera.photo_counter)
        lcd.drawText(LCD_XMID, 215, countStr, CUSTOM_COLOR+MIDSIZE+CENTER)
    end
    
    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    if status.video_on then
        lcd.drawText(LCD_XMID, 240, "video recording...", CUSTOM_COLOR+MIDSIZE+CENTER+BLINK)
    end
    if status.photo_on then
        lcd.drawText(LCD_XMID, 240, "photo shooting...", CUSTOM_COLOR+MIDSIZE+CENTER+BLINK)
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
        lcd.drawText(LCD_XMID, 70, "Video", CUSTOM_COLOR+DBLSIZE+CENTER)
    elseif info.has_photo then
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawText(LCD_XMID, 70, "Photo", CUSTOM_COLOR+DBLSIZE+CENTER)
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


return 
    camera,
    cameraDoAlways,
    doPageCamera




