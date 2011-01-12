-- {{
-- Lua Code for volumen control widget
-- Copyright (c) 2011 Christoph Seitz
-- Licensed under MIT License
-- See LICENSE for more info
-- }

local io = require("io")
local os = require("os")
volcontrol = { }
local mt_volctrl = { __index = volcontrol } 

function volcontrol.new (settings) 
	local self = { }

	if settings==nil then settings = { } end
	self.mixer = settings.mixer or 'Master'
	self.channel = settings.channel or 'Mono'
	self.updatetime = settings.updatetime or 10
	self.widget = widget({ type = "imagebox" })
	setmetatable(self,mt_volctrl)
	self:register_events()
	self:update_vol()
	return self
end

function volcontrol:register_events()
	self.widget:buttons(awful.util.table.join(
		awful.button({ }, 4, function () self:vol_up(10) end),
		awful.button({ }, 5, function () self:vol_down(10) end),
		awful.button({"Shift" }, 4, function () self:vol_up(5)end),
		awful.button({"Shift" }, 5, function () self:vol_down(5) end),
		awful.button({ }, 1, function () self:mute_toggle() end)
	))
end

function volcontrol:mute_toggle() 
	if self.mute == true then
		self.mute=false
		os.execute("amixer -q sset "..self.mixer.." ".."on")
		self:update_ui()
		return
	end
	if self.mute == false then
		self.mute=true
		os.execute("amixer -q sset "..self.mixer.." ".."off")
		self:update_ui()
		return
	end
end

function volcontrol:vol_up(x) 
	self.vol = self.vol + x
	if self.vol >100 then
		self.vol = 100
	end
	os.execute("amixer -q sset "..self.mixer.." "..tostring(self.vol).."%")
	self:update_vol()
	self:update_ui()
end	

function volcontrol:vol_down(x) 
	self.vol = self.vol - x
	if self.vol <0 then
		self.vol = 0
	end
	os.execute("amixer -q sset "..self.mixer.." "..tostring(self.vol).."%")
	self:update_vol()
	self:update_ui()
end

function volcontrol:run() 
	self.timer = timer({ timeout = self.updatetime})
	self.timer:add_signal("timeout",function () self:update_vol() end)
	self.timer:start()
end

function split(str, pat)
	local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pat
      	local last_end = 1
   	local s, e, cap = str:find(fpat, 1)
     	while s do
        	if s ~= 1 or cap ~= "" then
   	 		table.insert(t,cap)
      		end
           	last_end = e+1
          	s, e, cap = str:find(fpat, last_end)
      	end
        if last_end <= #str then
       		cap = str:sub(last_end)
           	table.insert(t, cap)
     	end
	return t
end

function volcontrol:update_vol()
	local channel = { }
	local ret = io.popen("amixer sget "..self.mixer..'| sed -rn -f '..awful.util.getdir("config")..'/lib/vol.sed' )
	for line in ret:lines() do
		channel = split(line,"=")
		if channel[1] == self.channel then
			self.vol = tonumber(channel[2])
			if channel[3] == "off" then
				self.mute = true
			else
				self.mute = false
			end
		end
	end
	io.close()
	self:update_ui()
end

function volcontrol:update_ui() 
	if self.vol <= 30 then
		self.widget.image = image(awful.util.getdir("config") .. "/lib/icons/audio-volume-low.png")
	end
	if self.vol >= 60 then
	     	self.widget.image = image(awful.util.getdir("config") .. "/lib/icons/audio-volume-high.png")
	end 
	if self.vol >30 and self.vol < 60 then
	        self.widget.image = image(awful.util.getdir("config") .. "/lib/icons/audio-volume-medium.png")
	end 
	if self.mute ==true then
		self.widget.image = image(awful.util.getdir("config") .. "/lib/icons/audio-volume-muted.png")
	end
end
