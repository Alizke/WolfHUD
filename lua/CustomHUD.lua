if WolfHUD and not WolfHUD.settings.use_customhud then return end
if string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then


	HUDManager.CUSTOM_TEAMMATE_PANEL = true	--External flag
	HUDManager._USE_BURST_MODE = HUDManager._USE_BURST_MODE or false	--Updated on burst fire plugin load
	HUDManager._USE_KILL_COUNTER = HUDManager._USE_KILL_COUNTER or false	--Updated on kill counter plugin load

	local update_original = HUDManager.update
	local set_stamina_value_original = HUDManager.set_stamina_value
	local set_max_stamina_original = HUDManager.set_max_stamina
	local add_weapon_original = HUDManager.add_weapon
	local setup_endscreen_hud_original = HUDManager.setup_endscreen_hud

	function HUDManager:update(t, dt, ...)
		self._next_latency_update = self._next_latency_update or 0

				
		for i, panel in ipairs(self._teammate_panels) do
			panel:update_downs()
		end
		
		local session = managers.network:session()
		if session and self._next_latency_update <= t then
			self._next_latency_update = t + 1
			local latencies = {}
			for _, peer in pairs(session:peers()) do
				if peer:id() ~= session:local_peer():id() then
					latencies[peer:id()] = Network:qos(peer:rpc()).ping
				end
			end
			
			for i, panel in ipairs(self._teammate_panels) do
				local latency = latencies[panel:peer_id()]
				if latency then
					self:update_teammate_latency(i, latency)
				end
			end
		end
		
		--[[
		for i = 1, #self._teammate_panels do
			self._teammate_panels[i]:update(t, dt)
		end
		]]
		
		return update_original(self, t, dt, ...)
	end

	function HUDManager:set_stamina_value(value, ...)
		self._teammate_panels[HUDManager.PLAYER_PANEL]:set_current_stamina(value)
		
		return set_stamina_value_original(self, value, ...)
	end

	function HUDManager:set_max_stamina(value, ...)
		self._teammate_panels[HUDManager.PLAYER_PANEL]:set_max_stamina(value)
		
		return set_max_stamina_original(self, value, ...)
	end

	function HUDManager:add_weapon(data, ...)
		local selection_index = data.inventory_index
		local weapon_id = data.unit:base().name_id
		local silencer = data.unit:base():got_silencer()
		self:set_teammate_weapon_id(HUDManager.PLAYER_PANEL, selection_index, weapon_id, silencer)

		return add_weapon_original(self, data, ...)
	end
	
	function HUDManager:setup_endscreen_hud(...)
		self._hud_chat_ingame:disconnect_mouse()
		return setup_endscreen_hud_original(self, ...)
	end
	
	function HUDManager:_create_teammates_panel(hud)
		local hud = hud or managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		self._hud.teammate_panels_data = self._hud.teammate_panels_data or {}
		self._teammate_panels = {}
		
		if hud.panel:child("teammates_panel") then	
			hud.panel:remove(hud.panel:child("teammates_panel"))
		end
		
		local teammates_panel = hud.panel:panel({ 
			name = "teammates_panel", 
			h = hud.panel:h(), 
			w = hud.panel:w(),
		})

		local num_panels = CriminalsManager and CriminalsManager.MAX_NR_CRIMINALS or 4
		for i = 1, math.max(num_panels, HUDManager.PLAYER_PANEL) do
			local is_player = i == HUDManager.PLAYER_PANEL
			self._hud.teammate_panels_data[i] = {
				taken = false,--is_player,--false and is_player, 	--TODO: The fuck is up with this value?
				special_equipments = {},
			}
			local teammate = HUDTeammate:new(i, teammates_panel, is_player)
			table.insert(self._teammate_panels, teammate)
			
			if is_player then
				teammate:add_panel()
			end
		end
	end

	function HUDManager:set_teammate_carry_info(i, carry_id, value, override_main)
		if i ~= HUDManager.PLAYER_PANEL or override_main then
			self._teammate_panels[i]:set_carry_info(carry_id, value)
		end
	end

	function HUDManager:remove_teammate_carry_info(i)
		self._teammate_panels[i]:remove_carry_info()
	end

	function HUDManager:set_teammate_weapon_id(i, slot, id, silencer)
		self._teammate_panels[i]:set_weapon_id(slot, id, silencer)
	end

	function HUDManager:update_teammate_latency(i, value)
		self._teammate_panels[i]:update_latency(value)
	end

	function HUDManager:set_mugshot_voice(id, active)
		local panel_id
		for _, data in pairs(managers.criminals:characters()) do
			if data.data.mugshot_id == id then
				panel_id = data.data.panel_id
				break
			end
		end

		if panel_id and panel_id ~= HUDManager.PLAYER_PANEL then
			self._teammate_panels[panel_id]:set_voice_com(active)
		end
	end

	function HUDManager:get_teammate_carry_panel_info(i)
		return self._teammate_panels[i]:get_carry_panel_info()
	end
	
	function HUDManager:_set_custom_hud_chat_offset(offset)
		self._hud_chat_ingame:set_offset(offset)
	end
	
	function HUDManager:hide_player_gear(panel_id)
		if self._teammate_panels[panel_id] then
			self._teammate_panels[panel_id]:set_gear_visible(false)
		end
	end
	
	function HUDManager:show_player_gear(panel_id)
		if self._teammate_panels[panel_id] then
			self._teammate_panels[panel_id]:set_gear_visible(true)
		end
	end
	--[[
	function HUDManager:set_stored_health(stored_health_ratio) 
		--self._teammate_panels[HUDManager.PLAYER_PANEL]:set_stored_health(stored_health_ratio) 		-- _teammate_panels seems to not exist, when it's called...
	end 
	function HUDManager:set_stored_health_max(stored_health_ratio) 
		--self._teammate_panels[HUDManager.PLAYER_PANEL]:set_stored_health_max(stored_health_ratio) 	-- _teammate_panels seems to not exist, when it's called...
	end 
	]]
	
elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammate" then


	HUDTeammate._PLAYER_PANEL_SCALE = WolfHUD.settings.PLAYER_PANEL_SCALE or 0.85
	HUDTeammate._TEAMMATE_PANEL_SCALE = WolfHUD.settings.TEAMMATE_PANEL_SCALE or 0.75
	HUDTeammate._NAME_ANIMATE_SPEED = 90

	HUDTeammate._INTERACTION_TEXTS = {
		big_computer_server = "USING COMPUTER",
	--[[
		ammo_bag = "Using ammo bag",
		c4_bag = "Taking C4",
		c4_mission_door = "Planting C4 (equipment)",
		c4_x1_bag = "Taking C4",
		connect_hose = "Connecting hose",
		crate_loot = "Opening crate",
		crate_loot_close = "Closing crate",
		crate_loot_crowbar = "Opening crate",
		cut_fence = "Cutting fence",
		doctor_bag = "Using doctor bag",
		drill = "Placing drill",
		drill_jammed = "Repairing drill",
		drill_upgrade = "Upgrading drill",
		ecm_jammer = "Placing ECM jammer",
		first_aid_kit = "Using first aid kit",
		free = "Uncuffing",
		grenade_briefcase = "Taking grenade",
		grenade_crate = "Opening grenade case",
		hack_suburbia_jammed = "Resuming hack",
		hold_approve_req = "Approving request",
		hold_close = "Closing door",
		hold_close_keycard = "Closing door (keycard)",
		hold_download_keys = "Starting hack",
		hold_hack_comp = "Starting hack",
		hold_open = "Opening door",
		hold_open_bomb_case = "Opening bomb case",
		hold_pku_disassemble_cro_loot = "Disassembling bomb",
		hold_remove_armor_plating = "Removing plating",
		hold_remove_ladder = "Taking ladder",
		hold_take_server_axis = "Taking server",
		hostage_convert = "Converting enemy",
		hostage_move = "Moving hostage",
		hostage_stay = "Moving hostage",
		hostage_trade = "Trading hostage",
		intimidate = "Cable tying civilian",
		open_train_cargo_door = "Opening door",
		pick_lock_easy_no_skill = "Picking lock",
		requires_cable_ties = "Cable tying civilian",
		revive = "Reviving",
		sentry_gun_refill = "Refilling sentry gun",
		shaped_charge_single = "Planting C4 (deployable)",
		shaped_sharge = "Planting C4 (deployable)",
		shape_charge_plantable = "Planting C4 (equipment)",
		shape_charge_plantable_c4_1 = "Planting C4 (equipment)",
		shape_charge_plantable_c4_x1 = "Planting C4 (equipment)",
		trip_mine = "Placing trip mine",
		uload_database_jammed = "Resuming hack",
		use_ticket = "Using ticket",
		votingmachine2 = "Starting hack",
		votingmachine2_jammed = "Resuming hack",
		methlab_caustic_cooler = "Cooking meth (caustic soda)",
		methlab_gas_to_salt = "Cooking meth (hydrogen chloride)",
		methlab_bubbling = "Cooking meth (muriatic acid)",
		money_briefcase = "Opening briefcase",
		pku_barcode_downtown = "Taking barcode (downtown)",
		pku_barcode_edgewater = "Taking barcode (?)",	--TODO: Location
		gage_assignment = "Taking courier package",
		stash_planks = "Boarding window",
		stash_planks_pickup = "Taking planks",
		taking_meth = "Bagging loot",
		hlm_connect_equip = "Connecting cable",
	]]
	}

	local function debug_check_tweak_data(tweak_data_id)
		if (rawget(_G, "DEBUG_MODE") ~= nil) and tweak_data_id and tweak_data.interaction[tweak_data_id] and tweak_data.interaction[tweak_data_id].timer and tweak_data.interaction[tweak_data_id].timer > 1 then
			if not (tweak_data.interaction[tweak_data_id].action_text_id or HUDTeammate._INTERACTION_TEXTS[tweak_data_id]) then
				debug_log("interactions.log", "%s - %s - %s\n", tweak_data_id, managers.job:current_level_id(), tweak_data.interaction[tweak_data_id].timer)
			end
		end
	end

	function HUDTeammate:init(i, parent, is_player)
		HUDTeammate._TEAMMATEPANELS = HUDTeammate._TEAMMATEPANELS or 0
		self._parent = parent
		self._id = i
		self._main_player = is_player and true or false
		self._timer = 0
		self._special_equipment = {}
		self._deployable_amount = 0
		self._cable_ties_amount = 0
		self._grenades_amount = 0
		self._downs = 0
		
		if self._main_player then
			self:_create_player_panel()
		else
			self:_create_teammate_panel()
			HUDTeammate._TEAMMATEPANELS = HUDTeammate._TEAMMATEPANELS + 1
		end
		
		self:reset_kill_count()
	end

	function HUDTeammate:_create_player_panel()
		local scale = HUDTeammate._PLAYER_PANEL_SCALE
		self:_create_main_panel(575 + 4 * 5 * scale, 80, scale)
		self:_create_health_panel(60, 60, scale)
		self:_create_rip_panel(60, 60, scale)
		self:_create_stamina_panel(15, 60, scale)
		self:_create_weapons_panel(360, 60, scale)
		self:_create_equipment_panel(60, 80, scale)
		self:_create_special_equipment_panel(80, 80, scale)
		self:_create_carry_panel(330, 20, scale)
		self:_create_kills_panel(105, 20, scale)
		self:_create_interact_panel_new()	--Overlays weapon panel
		
		self._health_panel:set_left(0)
		self._health_panel:set_bottom(self._panel:h())
		self._stamina_panel:set_left(self._health_panel:right() + 5 * scale)
		self._stamina_panel:set_bottom(self._panel:h())
		self._weapons_panel:set_left(self._stamina_panel:right() + 5 * scale)
		self._weapons_panel:set_bottom(self._panel:h())
		self._equipment_panel:set_left(self._weapons_panel:right() + 5 * scale)
		self._equipment_panel:set_bottom(self._panel:h())
		self._special_equipment_panel:set_left(self._equipment_panel:right() + 5 * scale)
		self._special_equipment_panel:set_bottom(self._panel:h())
		self._kills_panel:set_right(self._weapons_panel:right())
		self._kills_panel:set_bottom(self._weapons_panel:top())
		self._carry_panel:set_left(0)
		self._carry_panel:set_bottom(self._weapons_panel:top())
		self._interact_panel:set_left(self._weapons_panel:left())
		self._interact_panel:set_top(self._weapons_panel:top())

		
		self._panel:set_center(self._parent:w() / 2, 0)
		self._panel:set_bottom(self._parent:h())
	end

	function HUDTeammate:_create_teammate_panel()
		local scale = HUDTeammate._TEAMMATE_PANEL_SCALE
		local label_height = 20 * scale
		
		self:_create_main_panel(388 + 2 * 5 * scale, 85, scale)
		self:_create_health_panel(45, 45, scale)
		self:_create_weapons_panel(243, 45, scale)
		self:_create_special_equipment_panel(100, 85, scale)
		
		local w_h_width = self._health_panel:w() + self._weapons_panel:w()
		self:_create_equipment_panel(w_h_width * 0.375, label_height, 1)
		self:_create_carry_panel(w_h_width * 0.45, label_height, 1)
		self:_create_kills_panel(w_h_width * 0.3, label_height, 1)
		
		self:_create_name_panel(w_h_width * 0.625, label_height, 1)
		self:_create_latency_panel(w_h_width * 0.25, label_height, 1)
		--self:_create_interact_panel()
		self:_create_interact_panel_new()	--Overlays weapon panel
		
		self._kills_panel:set_left(0)
		self._kills_panel:set_bottom(self._panel:h())
		self._latency_panel:set_left(self._kills_panel:right())
		self._latency_panel:set_bottom(self._panel:h())
		self._carry_panel:set_left(self._latency_panel:right())
		self._carry_panel:set_bottom(self._panel:h())
		self._health_panel:set_left(0)
		self._health_panel:set_bottom(self._kills_panel:top())
		self._weapons_panel:set_left(self._health_panel:right() + 5 * scale)
		self._weapons_panel:set_bottom(self._kills_panel:top())
		self._equipment_panel:set_left(self._health_panel:w() + self._weapons_panel:w() - self._equipment_panel:w())
		self._equipment_panel:set_bottom(self._weapons_panel:top())
		self._special_equipment_panel:set_left(self._weapons_panel:right() + 5 * scale)
		self._special_equipment_panel:set_bottom(self._panel:h())
		self._name_panel:set_left(0)
		self._name_panel:set_bottom(self._weapons_panel:top())
		--self._interact_panel:set_left(self._health_panel:left())
		--self._interact_panel:set_top(self._health_panel:top())
		self._interact_panel:set_left(self._weapons_panel:left())
		self._interact_panel:set_top(self._weapons_panel:top())

		
		local total_height = self._name_panel:h() + self._health_panel:h() + self._kills_panel:h() + 10
		self._panel:set_left(0)
		self._panel:set_bottom(self._parent:h() - HUDTeammate._TEAMMATEPANELS * total_height)
	end

	function HUDTeammate:_create_main_panel(width, height, scale)
		scale = scale or 1
		width = width * scale
		height = height * scale

		self._panel = self._parent:panel({
			name = "teammate_panel_" .. self._id,
			visible = false,
			w = width,
			h = height,
		})
		--[[
		self._panel:rect({	--TEMPORARY
			blend_mode = "normal",
			color = tweak_data.chat_colors[self._id] or Color.white,
			alpha = 0.10,
			h = self._panel:h(),
			w = self._panel:w(),
			layer = -10,
		})]]
	end

	function HUDTeammate:_create_health_panel(width, height, scale)
		scale = scale or 1
		width = width * scale
		height = height * scale

		self._health_panel = self._panel:panel({
			name = "radial_health_panel",
			h = height,
			w = width,
		})

		local health_panel_bg = self._health_panel:bitmap({
			name = "radial_bg",
			texture = "guis/textures/pd2/hud_radialbg",
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 0,
		})
		
		local radial_health = self._health_panel:bitmap({
			name = "radial_health",
			texture = "guis/textures/pd2/hud_health",
			texture_rect = { 64, 0, -64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(1, 1, 0, 0),
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 2,
		})
		
		local radial_shield = self._health_panel:bitmap({
			name = "radial_shield",
			texture = "guis/textures/pd2/hud_shield",
			texture_rect = { 64, 0, -64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(1, 1, 0, 0),
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 1
		})

		
		local risk_indicator = self._health_panel:text({
			name = "risk_indicator",
			text = "?",
			color = Color(1, 1, 0, 0),
			blend_mode = "normal",
			layer = 1,
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			vertical = "center",
			align = "center",
			font_size = 15,
			font = tweak_data.menu.pd2_medium_font
		})

				
		local damage_indicator = self._health_panel:bitmap({
			name = "damage_indicator",
			texture = "guis/textures/pd2/hud_radial_rim",
			blend_mode = "add",
			color = Color(1, 1, 1, 1),
			alpha = 0,
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 1
		})
		
		local radial_custom = self._health_panel:bitmap({
			name = "radial_custom",
			texture = "guis/textures/pd2/hud_swansong",
			texture_rect = { 0, 0, 64, 64 },
			render_template = "VertexColorTexturedRadial",
			blend_mode = "add",
			color = Color(1, 0, 0, 0),
			visible = false,
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			layer = 2
		})
		
		self._condition_icon = self._health_panel:bitmap({
			name = "condition_icon",
			layer = 4,
			visible = false,
			color = Color.white,
			w = self._health_panel:w(),
			h = self._health_panel:h(),
		})
		self._condition_timer = self._health_panel:text({
			name = "condition_timer",
			visible = false,
			layer = 5,
			color = Color.white,
			w = self._health_panel:w(),
			h = self._health_panel:h(),
			align = "center",
			vertical = "center",
			font_size = self._health_panel:h() * 0.5,
			font = tweak_data.hud_players.timer_font
		})
		--[[
		if self._main_player then
			self._stamina_bar = self._health_panel:bitmap({
				name = "radial_stamina",
				texture = "guis/textures/pd2/hud_shield",
				texture_rect = { 64, 0, -64, 64 },
				render_template = "VertexColorTexturedRadial",
				blend_mode = "add",
				color = Color(1, 1, 0, 0),
				w = self._health_panel:w() * 0.5,
				h = self._health_panel:h() * 0.5,
				layer = 5
			})
			self._stamina_bar:set_center(self._health_panel:w() / 2, self._health_panel:h() / 2)
			
			self._stamina_line = self._health_panel:rect({
				color = Color.red,
				w = self._health_panel:w() * 0.10,
				h = 1,
				layer = 10,
			})
			self._stamina_line:set_center(self._health_panel:w() / 2, self._health_panel:h() / 2)
		end
		]]
	end
	function HUDTeammate:_create_rip_panel(width, height, scale) 
		local radial_rip = self._health_panel:bitmap({  
			name = "radial_rip",  
			texture = "guis/textures/pd2/hud_rip",  
			texture_rect = { 64, 0, -64, 64 },  
			render_template = "VertexColorTexturedRadial",  
			color = Color(1, 0, 0, 0),  
			w = self._health_panel:w(),  
			h = self._health_panel:h(),  
			layer = 3  
		})  
		radial_rip:hide()  
		
		local radial_rip_bg = self._health_panel:bitmap({  
			name = "radial_rip_bg",  
			texture = "guis/textures/pd2/hud_rip_bg",  
			texture_rect = { 64, 0, -64, 64 },  
			render_template = "VertexColorTexturedRadial",  
			blend_mode = "add",  
			color = Color(1, 0, 0, 0),  
			w = self._health_panel:w(),  
			h = self._health_panel:h(),  
			layer = 1  
		})  
		radial_rip_bg:set_visible(managers.player:has_category_upgrade("player", "armor_health_store_amount"))  
	end  


	function HUDTeammate:set_health(data)
		local radial_health = self._health_panel:child("radial_health")
		local red = data.current / data.total
		if red < radial_health:color().red then
			self:_damage_taken()
		end
		radial_health:set_color(Color(1, red, 1, 1))
	end

	function HUDTeammate:set_armor(data)
		local radial_shield = self._health_panel:child("radial_shield")
		local red = data.current / data.total
		if red < radial_shield:color().red then
			self:_damage_taken()
		end
		radial_shield:set_color(Color(1, red, 1, 1))
	end

	function HUDTeammate:_damage_taken()
		local damage_indicator = self._health_panel:child("damage_indicator")
		damage_indicator:stop()
		damage_indicator:animate(callback(self, self, "_animate_damage_taken"))
	end

	function HUDTeammate:set_condition(icon_data, text)
		if icon_data == "mugshot_normal" then
			self._condition_icon:set_visible(false)
		else
			self._condition_icon:set_visible(true)
			local icon, texture_rect = tweak_data.hud_icons:get_icon_data(icon_data)
			self._condition_icon:set_image(icon, texture_rect[1], texture_rect[2], texture_rect[3], texture_rect[4])
		end
	end

	function HUDTeammate:set_custom_radial(data)
		local radial_custom = self._health_panel:child("radial_custom")
		local red = data.current / data.total
		radial_custom:set_color(Color(1, red, 1, 1))
		radial_custom:set_visible(red > 0)
	end

	function HUDTeammate:start_timer(time)
		self._timer_paused = 0
		self._timer = time
		self._condition_timer:set_font_size(self._health_panel:h() * 0.5)
		self._condition_timer:set_color(Color.white)
		self._condition_timer:stop()
		self._condition_timer:set_visible(true)
		self._condition_timer:animate(callback(self, self, "_animate_timer"))
	end

	function HUDTeammate:stop_timer()
		if alive(self._panel) then
			self._condition_timer:set_visible(false)
			self._condition_timer:stop()
		end
	end

	function HUDTeammate:set_pause_timer(pause)
		if not alive(self._panel) then
			return
		end
		--self._condition_timer:set_visible(false)
		self._condition_timer:stop()
	end

	function HUDTeammate:is_timer_running()
		return self._condition_timer:visible()
	end
	
	function HUDTeammate:update_downs( i )
		local color = Color(1, 0, 0.8, 1)
		if not self._downs then self._downs = 0 end
		if managers.groupai:state():whisper_mode() then	
			local risk = 99
			if self._id == HUDManager.PLAYER_PANEL then
				self._health_panel:child("risk_indicator"):set_font_size(15 * HUDTeammate._PLAYER_PANEL_SCALE)
				risk = tonumber(string.format("%.0f", managers.blackmarket:get_suspicion_offset_of_local(75)))
			elseif self:peer_id() ~= nil then
				self._health_panel:child("risk_indicator"):set_font_size(15 * HUDTeammate._TEAMMATE_PANEL_SCALE)
				risk = tonumber(string.format("%.0f", managers.blackmarket:get_suspicion_offset_of_peer(managers.network:session():peer(self:peer_id()), 75)))
			end
			self._health_panel:child("risk_indicator"):set_text("")
			if risk < 99 then
				local r = (risk-3)/72
				local g = 0.8-0.6*((risk-3)/72)
				local b = 1-(risk-3)/72
				color = Color(1, r, g, b)
				self._health_panel:child("risk_indicator"):set_text("" .. tostring(risk))
			end
		else
			if self._id == HUDManager.PLAYER_PANEL then
				self._health_panel:child("risk_indicator"):set_font_size(19 * HUDTeammate._PLAYER_PANEL_SCALE)
			elseif self:peer_id() ~= nil then
				self._health_panel:child("risk_indicator"):set_font_size(15 * HUDTeammate._TEAMMATE_PANEL_SCALE)
				--if PocoHud3 ~= nil then
				--	self._downs = i or self._downs
				--end
			end
			local alpha = ((self:peer_id() ~= nil or self._id == HUDManager.PLAYER_PANEL) and 1 or 0)
			color = self._downs > 2 and Color.red:with_alpha(alpha) or self._downs == 2 and Color.yellow:with_alpha(alpha) or Color.green:with_alpha(alpha)
			self._health_panel:child("risk_indicator"):set_text(self._downs)
		end
		self._health_panel:child("risk_indicator"):set_color(color)
	end
	
	function HUDTeammate:downed()
		self._downs = self._downs + 1
		self:update_downs()
	end
	
	function HUDTeammate:reset_downs()
		self._downs = 0
		self:update_downs()
	end

	function HUDTeammate:_create_stamina_panel(width, height, scale)
		scale = scale or 1
		width = width * scale
		height = height * scale

		self._stamina_panel = self._panel:panel({
			name = "stamina_panel",
			h = height,
			w = width,
		})
		
		local stamina_bar_outline = self._stamina_panel:bitmap({
			name = "stamina_bar_outline",
			texture = "guis/textures/hud_icons",
			texture_rect = { 252, 240, 12, 48 },
			color = Color.white,
			w = width,
			h = height,
			layer = 10,
		})
		self._stamina_bar_max_h = stamina_bar_outline:h() * 0.96
		self._default_stamina_color = Color(0.7, 0.8, 1.0)
		
		local stamina_bar = self._stamina_panel:rect({
			name = "stamina_bar",
			blend_mode = "normal",
			color = self._default_stamina_color,
			alpha = 0.75,
			h = self._stamina_bar_max_h,
			w = stamina_bar_outline:w() * 0.9,
			layer = 5,
		})
		stamina_bar:set_center(stamina_bar_outline:center())
		
		local bar_bg = self._stamina_panel:gradient({
			layer = 1,
			gradient_points = { 0, Color.white:with_alpha(0.10), 1, Color.white:with_alpha(0.40) },
			h = stamina_bar:h(),
			w = stamina_bar:w(),
			blend_mode = "sub",
			orientation = "vertical",
			layer = 10,
		})
		bar_bg:set_center(stamina_bar:center())
		
		local stamina_threshold = self._stamina_panel:rect({
			name = "stamina_threshold",
			color = Color.red,
			w = stamina_bar:w(),
			h = 2,
			layer = 8,
		})
		stamina_threshold:set_center(stamina_bar:center())
	end

	function HUDTeammate:set_max_stamina(value)
		if value ~= self._max_stamina then
			self._max_stamina = value
			local stamina_bar = self._stamina_panel:child("stamina_bar")
			
			local offset = stamina_bar:h() * (tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD / self._max_stamina)
			self._stamina_panel:child("stamina_threshold"):set_bottom(stamina_bar:bottom() - offset + 1)
		end
	end

	function HUDTeammate:set_current_stamina(value)
		local stamina_bar = self._stamina_panel:child("stamina_bar")
		local stamina_bar_outline = self._stamina_panel:child("stamina_bar_outline")
		
		stamina_bar:set_h(self._stamina_bar_max_h * (value / self._max_stamina))
		stamina_bar:set_bottom(0.5 * (stamina_bar_outline:h() + self._stamina_bar_max_h))
		if value <= tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD and not self._animating_low_stamina then
			self._animating_low_stamina = true
			stamina_bar:animate(callback(self, self, "_animate_low_stamina"), stamina_bar_outline)
		elseif value > tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD and self._animating_low_stamina then
			self._animating_low_stamina = nil
		end
	end
	
	function HUDTeammate:set_stored_health(stored_health_ratio)  
		local rip = self._health_panel:child("radial_rip")
		local rip_bg = self._health_panel:child("radial_rip_bg")
		local radial_health = self._health_panel:child("radial_health")		
		if alive(rip) then  
			do			  
				local red = math.min(stored_health_ratio, 1)  
				rip:set_visible(red > 0)  
				rip:stop()
				rip:set_rotation((1 - radial_health:color().r) * 360)
				rip_bg:set_rotation((1 - radial_health:color().r) * 360)
				if red < rip:color().red then  
					rip:set_color(Color(1, red, 1, 1))  
				else  
					rip:animate(function(o)  
						local s = rip:color().r  
						local e = red  
						over(0.2, function(p)  
							rip:set_color(Color(1, math.lerp(s, e, p), 1, 1))  
							end  
						)  
						end  
					)  
				end  
			end  
		end  
	end
	
	function HUDTeammate:set_stored_health_max(stored_health_ratio)  
		local rip_bg = self._health_panel:child("radial_rip_bg")  
		if alive(rip_bg) then  
			rip_bg:set_color(Color(1,math.min(stored_health_ratio,1),1,1))  
		end
	end  
	
	
	function HUDTeammate:_create_weapons_panel(width, height, scale)
		local function populate_weapon_panel(panel)
			if self._main_player then
				local bg_box = HUDBGBox_create(panel, {
						w = panel:w(),
						h = panel:h(),
					}, {})
			end
			
			local icon = panel:bitmap({
				name = "icon",
				blend_mode = "normal",
				visible = false,
				w = panel:h() * 2,
				h = panel:h(),
				layer = 10,
			})
			
			local size = panel:h() * 0.25
			local silencer_icon = panel:bitmap({
				name = "silencer_icon",
				texture = "guis/textures/pd2/blackmarket/inv_mod_silencer",
				blend_mode = "normal",
				visible = false,
				w = size,
				h = size,
				layer = 11,
			})
			silencer_icon:set_bottom(icon:bottom())
			silencer_icon:set_right(icon:right())
			
			local ammo_text_width = (panel:w() - icon:w()) * (self._main_player and 0.65 or 1)
			
			local ammo_clip = panel:text({
				name = "ammo_clip",
				text = "000",
				color = Color.white,
				blend_mode = "normal",
				layer = 1,
				w = ammo_text_width,
				h = height * 0.55,
				vertical = "center",
				align = "right",
				font_size = height * 0.55,
				font = tweak_data.hud_players.ammo_font
			})
			ammo_clip:set_top(icon:top())
			ammo_clip:set_left(icon:right())
			
			local ammo_total = panel:text({
				name = "ammo_total",
				text = "000",
				color = Color.white,
				blend_mode = "normal",
				layer = 1,
				w = ammo_text_width,
				h = height * 0.45,
				vertical = "center",
				align = "right",
				font_size = height * 0.45,
				font = tweak_data.hud_players.ammo_font
			})
			ammo_total:set_bottom(icon:bottom())
			ammo_total:set_left(icon:right())
			
			if self._main_player then
				local weapon_selection_panel = panel:panel({
					name = "weapon_selection",
					layer = 1,
					w = panel:w() - ammo_clip:w() - icon:w(),
					h = height,
				})
				weapon_selection_panel:set_bottom(panel:h())
				weapon_selection_panel:set_left(ammo_total:right())
				
				local fire_modes = {
					{ name = "auto_fire", abbrev = "A" },
					{ name = "single_fire", abbrev = "S" },
				}
				if HUDManager._USE_BURST_MODE then
					table.insert(fire_modes, 2, { name = "burst_fire", abbrev = "B" })
				end
				
				local weapon_selection_bg = weapon_selection_panel:rect({
					blend_mode = "normal",
					color = Color.white,
					h = weapon_selection_panel:h() * math.clamp(#fire_modes * 0.25, 0.25, 1),
					w = weapon_selection_panel:w() * 0.65,
					layer = 1,
				})
				weapon_selection_bg:set_center(weapon_selection_panel:w() / 2, weapon_selection_panel:h() / 2)

				for i, data in ipairs(fire_modes) do
					local text = weapon_selection_panel:text({
						name = data.name,
						text = data.abbrev,
						color = Color.black,
						blend_mode = "normal",
						layer = 10,
						alpha = 0.75,
						w = weapon_selection_bg:w(),
						h = weapon_selection_bg:h() / #fire_modes,
						vertical = "center",
						align = "center",
						font_size = weapon_selection_bg:h() / #fire_modes,
						font = tweak_data.hud_players.ammo_font
					})
					text:set_center(weapon_selection_bg:center())
					text:set_bottom(weapon_selection_bg:bottom() - text:h() * (i-1))
				end
			end
		end
		

		scale = scale or 1
		width = width * scale
		height = height * scale
		
		self._weapons_panel = self._panel:panel({
			name = "weapons_panel",
			h = height,
			w = width,
		})
		
		self._weapons_panel:rect({
			name = "bg",
			blend_mode = "normal",
			color = Color.black,
			alpha = 0.25,
			h = self._weapons_panel:h(),
			w = self._weapons_panel:w(),
			layer = -1,
		})
		
		local primary_weapon_panel = self._weapons_panel:panel({
			name = "primary_weapon_panel",
			h = self._weapons_panel:h(),
			w = self._weapons_panel:w() * 0.5,
			alpha = 0.25,
		})
		
		local secondary_weapon_panel = self._weapons_panel:panel({
			name = "secondary_weapon_panel",
			h = self._weapons_panel:h(),
			w = self._weapons_panel:w() * 0.5,
			alpha = 0.25,
		})
		
		populate_weapon_panel(primary_weapon_panel)
		populate_weapon_panel(secondary_weapon_panel)
		secondary_weapon_panel:set_right(self._weapons_panel:w())
		self:recreate_weapon_firemode()
	end

	function HUDTeammate:recreate_weapon_firemode()
		if self._main_player then
			local weapon = managers.blackmarket:equipped_primary()
			local panel = self._weapons_panel:child("primary_weapon_panel")
			self:_create_weapon_firemode(weapon, panel, 2)
			
			weapon = managers.blackmarket:equipped_secondary()
			panel = self._weapons_panel:child("secondary_weapon_panel")
			self:_create_weapon_firemode(weapon, panel, 1)
		end
	end

	function HUDTeammate:_create_weapon_firemode(weapon, panel, id)		
		local weapon_tweak_data = tweak_data.weapon[weapon.weapon_id]
		local fire_mode = weapon_tweak_data.FIRE_MODE
		local can_toggle_firemode = weapon_tweak_data.CAN_TOGGLE_FIREMODE
		local locked_to_auto = managers.weapon_factory:has_perk("fire_mode_auto", weapon.factory_id, weapon.blueprint)
		local locked_to_single = managers.weapon_factory:has_perk("fire_mode_single", weapon.factory_id, weapon.blueprint)

		local has_single = (fire_mode == "single" or can_toggle_firemode) and not locked_to_auto and true or false
		local has_auto = (fire_mode == "auto" or can_toggle_firemode) and not locked_to_single and true or false
		local has_burst = (weapon_tweak_data.HAS_BURST_FIRE or can_toggle_firemode) and not (locked_to_single or locked_to_auto) and not weapon_tweak_data.FORBIDS_BURST_MODE

		local selection_panel = panel:child("weapon_selection")
		local single_fire = selection_panel:child("single_fire")
		local auto_fire = selection_panel:child("auto_fire")
		local burst_fire = selection_panel:child("burst_fire")
		
		single_fire:set_color(has_single and Color.black or Color(0.6, 0.1, 0.1))
		auto_fire:set_color(has_auto and Color.black or Color(0.6, 0.1, 0.1))
		if burst_fire then
			burst_fire:set_color(has_burst and Color.black or Color(0.6, 0.1, 0.1))
		end
		
		local default = locked_to_auto and "auto" or locked_to_single and "single" or fire_mode
		self:set_weapon_firemode(id, default)
	end

	function HUDTeammate:set_weapon_selected(id, hud_icon)
		self._weapons_panel:child("primary_weapon_panel"):set_alpha(id == 1 and 0.5 or 1)
		self._weapons_panel:child("secondary_weapon_panel"):set_alpha(id == 1 and 1 or 0.5)
	end

	function HUDTeammate:set_weapon_firemode(id, firemode)
		local panel = self._weapons_panel:child(id == 1 and "secondary_weapon_panel" or "primary_weapon_panel")
		local selection_panel = panel:child("weapon_selection")
		local single_fire = selection_panel:child("single_fire")
		local auto_fire = selection_panel:child("auto_fire")
		local burst_fire = selection_panel:child("burst_fire")
		
		local active_alpha = 1
		local inactive_alpha = 0.65
		
		if firemode == "single" then
			single_fire:set_alpha(active_alpha)
			single_fire:set_text("[S]")
			auto_fire:set_alpha(inactive_alpha)
			auto_fire:set_text("A")
			if burst_fire then
				burst_fire:set_text("B")
				burst_fire:set_alpha(inactive_alpha)
			end
		elseif firemode == "auto" then
			auto_fire:set_alpha(active_alpha)
			auto_fire:set_text("[A]")
			single_fire:set_alpha(inactive_alpha)
			single_fire:set_text("S")
			if burst_fire then
				burst_fire:set_text("B")
				burst_fire:set_alpha(inactive_alpha)
			end
		elseif firemode == "burst" then
			burst_fire:set_alpha(active_alpha)
			burst_fire:set_text("[B]")
			auto_fire:set_alpha(inactive_alpha)
			auto_fire:set_text("A")
			single_fire:set_alpha(inactive_alpha)
			single_fire:set_text("S")
		end
	end

	function HUDTeammate:set_weapon_firemode_burst(id)
		self:set_weapon_firemode(id, "burst")
	end

	function HUDTeammate:set_weapon_id(slot, id, silencer)
		local bundle_folder = tweak_data.weapon[id] and tweak_data.weapon[id].texture_bundle_folder
		local guis_catalog = "guis/"
		if bundle_folder then
			guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
		end
		local texture_name = tweak_data.weapon[id] and tweak_data.weapon[id].texture_name or tostring(id)
		local bitmap_texture = guis_catalog .. "textures/pd2/blackmarket/icons/weapons/" .. texture_name

		local panel = self._weapons_panel:child(slot == 1 and "secondary_weapon_panel" or "primary_weapon_panel")
		local icon = panel:child("icon")
		local silencer_icon = panel:child("silencer_icon")
		icon:set_visible(true)
		icon:set_image(bitmap_texture)
		silencer_icon:set_visible(silencer)
		
		if self._main_player and HUDManager._USE_BURST_MODE and alive(managers.player:player_unit()) then
			local unit = managers.player:player_unit():inventory():unit_by_selection(slot)
			if alive(unit) then
				local has_burst = unit:base().can_use_burst_burst and unit:base():can_use_burst_burst() or false
				panel:child("weapon_selection"):child("burst_fire"):set_color(has_burst and Color.black or Color(0.6, 0.1, 0.1))
			end
		end
	end

	function HUDTeammate:set_ammo_amount_by_type(type, max_clip, current_clip, current_left, max)
		local panel = self._weapons_panel:child(type .. "_weapon_panel")
		local low_ammo = current_left <= math.round(max_clip / 2)
		local low_ammo_clip = current_clip <= math.round(max_clip / 4)
		local out_of_ammo_clip = current_clip <= 0
		local out_of_ammo = current_left <= 0
		local color_total = out_of_ammo and Color(1, 0.9, 0.3, 0.3)
		color_total = color_total or low_ammo and Color(1, 0.9, 0.9, 0.3)
		color_total = color_total or Color.white
		local color_clip = out_of_ammo_clip and Color(1, 0.9, 0.3, 0.3)
		color_clip = color_clip or low_ammo_clip and Color(1, 0.9, 0.9, 0.3)
		color_clip = color_clip or Color.white
		
		local ammo_clip = panel:child("ammo_clip")
		local zero = current_clip < 10 and "00" or current_clip < 100 and "0" or ""
		ammo_clip:set_text(zero .. tostring(current_clip))
		ammo_clip:set_color(color_clip)
		ammo_clip:set_range_color(0, string.len(zero), color_clip:with_alpha(0.5))
		
		local ammo_total = panel:child("ammo_total")
		local zero = current_left < 10 and "00" or current_left < 100 and "0" or ""
		ammo_total:set_text(zero .. tostring(current_left))
		ammo_total:set_color(color_total)
		ammo_total:set_range_color(0, string.len(zero), color_total:with_alpha(0.5))
	end

	function HUDTeammate:_create_equipment_panel(width, height, scale)
		scale = scale or 1
		width = width * scale
		height = height * scale
		
		self._equipment_panel = self._panel:panel({
			name = "equipment_panel",
			h = height,
			w = width,
		})
		
		local item_panel_height = self._main_player and (height / 3) or height
		local item_panel_width = self._main_player and width or (width / 3)
		
		for i, name in ipairs({ "deployable_equipment_panel", "cable_ties_panel", "grenades_panel" }) do
			local panel = self._equipment_panel:panel({
				name = name,
				h = item_panel_height,
				w = item_panel_width,
				visible = false,
			})
			
			local icon = panel:bitmap({
				name = "icon",
				layer = 1,
				color = Color.white,
				w = panel:h(),
				h = panel:h(),
				layer = 2,
			})
			
			local amount = panel:text({
				name = "amount",
				text = "00",
				font = "fonts/font_medium_mf",
				font_size = panel:h(),
				color = Color.white,
				align = "right",
				vertical = "center",
				layer = 2,
				w = panel:w(),
				h = panel:h()
			})
			
			local bg = panel:rect({
				name = "bg",
				blend_mode = "normal",
				color = Color.black,
				alpha = 0.5,
				h = panel:h(),
				w = panel:w(),
				layer = -1,
			})
			
			if self._main_player then
				panel:set_top((i-1) * panel:h())
			else
				panel:set_left((i-1) * panel:w())
			end
		end
	end

	function HUDTeammate:_set_amount_string(text, amount)
		local zero = self._main_player and amount < 10 and "0" or ""
		text:set_text(zero .. amount)
		text:set_range_color(0, string.len(zero), Color.white:with_alpha(0.5))
	end

	function HUDTeammate:set_deployable_equipment(data)
		local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
		local deployable_equipment_panel = self._equipment_panel:child("deployable_equipment_panel")
		local deployable_icon = deployable_equipment_panel:child("icon")
		deployable_icon:set_image(icon, unpack(texture_rect))
		self:set_deployable_equipment_amount(1, data)
	end

	function HUDTeammate:set_deployable_equipment_amount(index, data)
		local deployable_equipment_panel = self._equipment_panel:child("deployable_equipment_panel")
		local deployable_amount = deployable_equipment_panel:child("amount")
		self:_set_amount_string(deployable_amount, data.amount)	
		deployable_equipment_panel:set_visible(data.amount ~= 0)
		self._deployable_amount = data.amount
	end

	function HUDTeammate:set_cable_tie(data)
		local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
		local cable_ties_panel = self._equipment_panel:child("cable_ties_panel")
		local tie_icon = cable_ties_panel:child("icon")
		tie_icon:set_image(icon, unpack(texture_rect))
		self:set_cable_ties_amount(data.amount)
	end

	function HUDTeammate:set_cable_ties_amount(amount)
		local cable_ties_panel = self._equipment_panel:child("cable_ties_panel")
		self:_set_amount_string(cable_ties_panel:child("amount"), amount)
		cable_ties_panel:set_visible(amount ~= 0)
		self._cable_ties_amount = amount
	end

	function HUDTeammate:set_grenades(data)
		local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
		local grenades_panel = self._equipment_panel:child("grenades_panel")
		local grenade_icon = grenades_panel:child("icon")
		grenade_icon:set_image(icon, unpack(texture_rect))
		self:set_grenades_amount(data)
	end

	function HUDTeammate:set_grenades_amount(data)
		local grenades_panel = self._equipment_panel:child("grenades_panel")
		local amount = grenades_panel:child("amount")
		self:_set_amount_string(amount, data.amount)
		grenades_panel:set_visible(data.amount ~= 0)
		self._grenades_amount = data.amount
	end

	function HUDTeammate:_create_special_equipment_panel(width, height, scale)
		scale = scale or 1
		width = width * scale
		height = height * scale

		self._special_equipment_panel = self._panel:panel({
			name = "special_equipment_panel",
			h = height,
			w = width,
		})
	end

	function HUDTeammate:add_special_equipment(data)
		local size = self._special_equipment_panel:h() / 3--(self._main_player and 3 or 4)
		
		local equipment_panel = self._special_equipment_panel:panel({
			name = data.id,
			h = size,
			w = size,
		})
		table.insert(self._special_equipment, equipment_panel)
		
		local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
		local bitmap = equipment_panel:bitmap({
			name = "bitmap",
			texture = icon,
			color = Color.white,
			layer = 1,
			texture_rect = texture_rect,
			w = equipment_panel:w(),
			h = equipment_panel:h()
		})
		
		local amount, amount_bg
		if data.amount then
			amount = equipment_panel:child("amount") or equipment_panel:text({
				name = "amount",
				text = tostring(data.amount),
				font = "fonts/font_small_noshadow_mf",
				font_size = 12 * equipment_panel:h() / 32,
				color = Color.black,
				align = "center",
				vertical = "center",
				layer = 4,
				w = equipment_panel:w(),
				h = equipment_panel:h()
			})
			amount:set_visible(1 < data.amount)
			amount_bg = equipment_panel:child("amount_bg") or equipment_panel:bitmap({
				name = "amount_bg",
				texture = "guis/textures/pd2/equip_count",
				color = Color.white,
				layer = 3,
			})
			amount_bg:set_size(amount_bg:w() * equipment_panel:w() / 32, amount_bg:h() * equipment_panel:h() / 32)
			amount_bg:set_center(bitmap:center())
			amount_bg:move(amount:w() * 0.2, amount:h() * 0.2)
			amount_bg:set_visible(1 < data.amount)
			amount:set_center(amount_bg:center())
		end
		
		local flash_icon = equipment_panel:bitmap({
			name = "bitmap",
			texture = icon,
			color = tweak_data.hud.prime_color,
			layer = 2,
			texture_rect = texture_rect,
			w = equipment_panel:w() + 2,
			h = equipment_panel:w() + 2
		})
		
		local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		flash_icon:set_center(bitmap:center())
		flash_icon:animate(hud.flash_icon, nil, equipment_panel)
		self:layout_special_equipments()
	end

	function HUDTeammate:remove_special_equipment(equipment)
		for i, panel in ipairs(self._special_equipment) do
			if panel:name() == equipment then
				local data = table.remove(self._special_equipment, i)
				self._special_equipment_panel:remove(panel)
				self:layout_special_equipments()
				return
			end
		end
	end

	function HUDTeammate:set_special_equipment_amount(equipment_id, amount)
		for i, panel in ipairs(self._special_equipment) do
			if panel:name() == equipment_id then
				panel:child("amount"):set_text(tostring(amount))
				panel:child("amount"):set_visible(amount > 1)
				panel:child("amount_bg"):set_visible(amount > 1)
				return
			end
		end
	end

	function HUDTeammate:clear_special_equipment()
		self:remove_panel()
		self:add_panel()
	end

	function HUDTeammate:layout_special_equipments()
		if #self._special_equipment > 0 then
			local h = self._special_equipment[1]:h()
			local w = self._special_equipment[1]:w()
			local items_per_column = math.floor(self._special_equipment_panel:h() / h)
			
			for i, panel in ipairs(self._special_equipment) do
				local column = math.floor((i-1) / items_per_column)
				panel:set_left(0 + column * w)
				panel:set_top(0 + (i - 1 - column * items_per_column) * h)
			end
		end
	end

	function HUDTeammate:set_gear_visible(visible)
		self._weapons_panel:set_visible(visible)
		self._equipment_panel:child("deployable_equipment_panel"):set_visible(visible and self._deployable_amount > 0)
		self._equipment_panel:child("cable_ties_panel"):set_visible(visible and self._cable_ties_amount > 0)
		self._equipment_panel:child("grenades_panel"):set_visible(visible and self._grenades_amount > 0)
	end
	
	function HUDTeammate:_create_carry_panel(width, height, scale)
		scale = scale or 1
		width = width * scale
		height = height * scale
		
		self._carry_panel = self._panel:panel({
			name = "carry_panel",
			visible = false,
			h = height,
			w = width,
		})
		
		local text = self._carry_panel:text({
			name = "text",
			layer = 1,
			color = Color.white,
			w = self._carry_panel:w(),
			h = self._carry_panel:h(),
			vertical = "center",
			align = "center",
			font_size = self._carry_panel:h(),
			font = tweak_data.hud.medium_font_noshadow,
		})
		
		local icon = self._carry_panel:bitmap({
			name = "icon",
			visible = false,	--Shows otherwise for some reason...
			texture = "guis/textures/pd2/hud_tabs",
			texture_rect = { 32, 33, 32, 31 },
			w = self._carry_panel:h(),
			h = self._carry_panel:h(),
			layer = 1,
			color = Color.white,
		})
		
		self:remove_carry_info()
	end

	function HUDTeammate:set_carry_info(carry_id, value)
		local name_id = carry_id and tweak_data.carry[carry_id] and tweak_data.carry[carry_id].name_id
		local carry_text = utf8.to_upper(name_id and managers.localization:text(name_id) or "UNKNOWN")
		local text = self._carry_panel:child("text")
		local icon = self._carry_panel:child("icon")
		
		text:set_text(carry_text)
		local _, _, w, _ = text:text_rect()
		text:set_w(w)
		text:set_right(self._carry_panel:w() / 2 + text:w() / 2 + icon:h() / 4)
		icon:set_right(text:left() - icon:h() / 4)
		icon:set_visible(true)
		
		self._carry_panel:set_visible(true)
		self._carry_panel:animate(callback(self, self, "_animate_carry_pickup"))
	end

	function HUDTeammate:remove_carry_info()
		self._carry_panel:stop()
		self._carry_panel:set_visible(false)
		self._carry_panel:child("icon"):set_visible(false)
		self._carry_panel:child("text"):set_text("")
	end

	function HUDTeammate:get_carry_panel_info()
		return self._carry_panel:w(), self._carry_panel:h(), self._panel:x() + self._carry_panel:x(), self._panel:y() + self._carry_panel:y()
	end

	function HUDTeammate:_create_kills_panel(width, height, scale)
		scale = scale or 1
		width = width * scale
		height = height * scale
		
		self._kills_panel = self._panel:panel({
			name = "kills_panel",
			visible = HUDManager._USE_KILL_COUNTER,
			h = height,
			w = width,
		})
		
		local icon = self._kills_panel:bitmap({
			name = "icon",
			texture = "guis/textures/pd2/cn_miniskull",
			w = self._kills_panel:h() * 0.75,
			h = self._kills_panel:h(),
			texture_rect = { 0, 0, 12, 16 },
			alpha = 1,
			visible = HUDManager._USE_KILL_COUNTER,
			blend_mode = "add",
			color = Color.yellow
		})
		
		local text = self._kills_panel:text({
			name = "text",
			text = "0 / 0",
			layer = 1,
			visible = HUDManager._USE_KILL_COUNTER,
			color = Color.yellow,
			w = self._kills_panel:w() - icon:w() - 1,
			h = self._kills_panel:h(),
			vertical = "center",
			align = "left",
			font_size = self._kills_panel:h(),
			font = tweak_data.hud_players.name_font
		})
		text:set_right(self._kills_panel:w())
	end

	function HUDTeammate:increment_kill_count(is_special, headshot)
		self._kill_count = self._kill_count + 1
		self._kill_count_special = self._kill_count_special + (is_special and 1 or 0)
		self._headshot_kills = self._headshot_kills + (headshot and 1 or 0)
		self:_update_kill_count_text()
	end

	function HUDTeammate:_update_kill_count_text()
		local text = tostring(self._kill_count)
		if HUDTeammate.SHOW_SPECIAL_KILLS then
			text = text .. "/" .. tostring(self._kill_count_special)
		end
		if HUDTeammate.SHOW_HEADSHOT_KILLS then
			text = text .. " (" .. tostring(self._headshot_kills) .. ")"
		end
		
		local field = self._kills_panel:child("text")
		field:set_text(text)
	end

	function HUDTeammate:reset_kill_count()
		self._kill_count = 0
		self._kill_count_special = 0
		self._headshot_kills = 0
		self:_update_kill_count_text()
	end

	function HUDTeammate:_create_name_panel(width, height, scale)
		scale = scale or 1
		width = width * scale
		height = height * scale
		
		self._name_panel = self._panel:panel({
			name = "name_panel",
			h = height,
			w = width,
		})
		
		local callsign = self._name_panel:bitmap({
			name = "callsign",
			texture = "guis/textures/pd2/hud_tabs",
			texture_rect = { 84, 34, 19, 19 },
			layer = 1,
			color = Color.white,
			blend_mode = "normal",
			w = self._name_panel:h(),
			h = self._name_panel:h()
		})
		
		local name_sub_panel = self._name_panel:panel({
			name = "name_sub_panel",
			h = self._name_panel:h(),
			w = self._name_panel:w() - callsign:w(),
		})
		name_sub_panel:set_right(self._name_panel:w())
		
		local text = name_sub_panel:text({
			name = "name",
			text = tostring(self._id),
			layer = 1,
			color = Color.white,
			--align = "left",
			align = "center",
			vertical = "center",
			w = name_sub_panel:w(),
			h = name_sub_panel:h(),
			font_size = name_sub_panel:h(),
			font = tweak_data.hud_players.name_font
		})
		--text:set_left(callsign:right())
	end

	function HUDTeammate:set_cheater(state)
		if not self._main_player then
			self._name_panel:child("name_sub_panel"):child("name"):set_color(state and tweak_data.screen_colors.pro_color or Color.white)
		end
	end

	function HUDTeammate:set_name(teammate_name)
		if not self._main_player and self._name ~= teammate_name then
			self._name = teammate_name
			self:reset_kill_count()
			self._name_panel:stop()
			
			local sub_panel = self._name_panel:child("name_sub_panel")
			local text = sub_panel:child("name")
			text:set_left(0)


			local experience = ""
			if self:peer_id() then
				local peer = managers.network:session():peer(self:peer_id())
				experience = " (" .. (peer:rank() > 0 and managers.experience:rank_string(peer:rank()) .. "-" or "") .. peer:level() .. ")"
			end
			
			text:set_text(teammate_name .. experience)
			local _, _, w, _ = text:text_rect()
			w = w + 5
			text:set_w(w)
			if w > sub_panel:w() then
				self._name_panel:animate(callback(self, self, "_animate_name_label"), w - sub_panel:w())
			end
		end
	end

	function HUDTeammate:set_callsign(id)
		if not self._main_player then
			self._name_panel:child("name_sub_panel"):child("name"):set_color((tweak_data.chat_colors[id] or Color.white):with_alpha(1))
			self._name_panel:child("callsign"):set_color((tweak_data.chat_colors[id] or Color.white):with_alpha(1))
			self:set_voice_com(false)
		end
	end

	function HUDTeammate:set_voice_com(status)
		local texture = status and "guis/textures/pd2/jukebox_playing" or "guis/textures/pd2/hud_tabs"
		local texture_rect = status and { 0, 0, 16, 16 } or { 84, 34, 19, 19 }
		local callsign = self._name_panel:child("callsign")
		
		callsign:set_image(texture, unpack(texture_rect))
		if status then
			callsign:animate(callback(self, self, "_animate_voice_com"), self._name_panel:h(), callsign:center())
		else
			callsign:stop()
			callsign:set_size(self._name_panel:h(), self._name_panel:h())
			callsign:set_position(0, 0)
		end
	end

	function HUDTeammate:_create_latency_panel(width, height, scale)
		scale = scale or 1
		width = width * scale
		height = height * scale
		
		self._latency_panel = self._panel:panel({
			name = "latency_panel",
			h = height,
			w = width,
		})
		
		local text = self._latency_panel:text({
			name = "text",
			text = "0 ms",
			layer = 1,
			color = Color.yellow,
			w = self._latency_panel:w(),
			h = self._latency_panel:h(),
			vertical = "center",
			align = "center",
			font_size = self._latency_panel:h(),
			font = tweak_data.hud_players.name_font
		})
	end

	function HUDTeammate:update_latency(value)
		if not (self._ai or self._main_player) then
			local text = self._latency_panel:child("text")
			text:set_text(string.format("%d ms", value))
			text:set_color(value < 75 and Color.green or value < 150 and Color.yellow or Color.red)
		end
	end

	function HUDTeammate:_create_interact_panel_new()
		self._interact_panel = self._panel:panel({
			name = "interact_panel",
			layer = 0,
			visible = false,
			alpha = 0,
			w = self._weapons_panel:w(),
			h = self._weapons_panel:h(),
		})
		
		self._interact_panel:rect({
			name = "bg",
			blend_mode = "normal",
			color = Color.black,
			alpha = 0.25,
			h = self._interact_panel:h(),
			w = self._interact_panel:w(),
			layer = -1,
		})

		local interact_text = self._interact_panel:text({
			name = "interact_text",
			layer = 10,
			color = Color.white,
			w = self._interact_panel:w(),
			h = self._interact_panel:h() * 0.5,
			vertical = "center",
			align = "center",
			blend_mode = "normal",
			font_size = self._interact_panel:h() * 0.4,
			font = tweak_data.hud_players.name_font
		})
		interact_text:set_top(0)
		
		local interact_bar_outline = self._interact_panel:bitmap({
			name = "outline",
			texture = "guis/textures/hud_icons",
			texture_rect = { 252, 240, 12, 48 },
			w = self._interact_panel:h() * 0.5,
			h = self._interact_panel:w() * 0.75,
			layer = 10,
			rotation = 90
		})
		interact_bar_outline:set_center(self._interact_panel:w() / 2, 0)
		interact_bar_outline:set_bottom(self._interact_panel:h() + interact_bar_outline:h() / 2 - interact_bar_outline:w() / 2)
		
		self._interact_bar_max_width = interact_bar_outline:h() * 0.97

		local interact_bar = self._interact_panel:gradient({
			name = "interact_bar",
			blend_mode = "normal",
			alpha = 0.75,
			layer = 5,
			h = interact_bar_outline:w() * 0.8,
			w = self._interact_bar_max_width,
		})
		interact_bar:set_center(interact_bar_outline:center())
		
		local interact_bar_bg = self._interact_panel:rect({
			name = "interact_bar_bg",
			blend_mode = "normal",
			color = Color.black,
			alpha = 1.0,
			h = interact_bar_outline:w(),
			w = interact_bar_outline:h(),
			layer = 0,
		})
		interact_bar_bg:set_center(interact_bar:center())
		
		local interact_timer = self._interact_panel:text({
			name = "interact_timer",
			layer = 10,
			color = Color.white,
			w = interact_bar:w(),
			h = interact_bar:h(),
			vertical = "center",
			align = "center",
			blend_mode = "normal",
			font_size = interact_bar:h(),
			font = tweak_data.hud_players.name_font
		})
		interact_timer:set_center(interact_bar:center())
	end

	function HUDTeammate:teammate_progress(enabled, tweak_data_id, timer, success)
		debug_check_tweak_data(tweak_data_id)
		
		--if not self._main_player then
			self._interact_panel:stop()
			
			if not enabled and self._interact_panel:visible() then
				self._interact_panel:animate(callback(self, self, "_animate_interact_timer_complete"), success)
				--self._interact_panel:set_visible(false)
				--self._weapons_panel:set_visible(true)
			end
			
			if enabled and timer > 1 then
				local text = ""
				if tweak_data_id then
					local action_text_id = tweak_data.interaction[tweak_data_id] and tweak_data.interaction[tweak_data_id].action_text_id or "hud_action_generic"
					text = HUDTeammate._INTERACTION_TEXTS[tweak_data_id] or action_text_id and managers.localization:text(action_text_id)
				end
				
				self._interact_panel:child("interact_text"):set_text(string.format("%s (%.1fs)", utf8.to_upper(text), timer))
				self._interact_panel:animate(callback(self, self, "_animate_interact_timer_new"), timer)
			end
		--end
	end

	function HUDTeammate:panel()
		return self._panel
	end

	function HUDTeammate:peer_id()
		return self._peer_id
	end

	function HUDTeammate:add_panel()
		self._panel:set_visible(true)
	end

	function HUDTeammate:remove_panel()
		while self._special_equipment[1] do
			self._special_equipment_panel:remove(table.remove(self._special_equipment, 1))
		end
		
		--self._weapons_panel:child("secondary_weapon_panel"):child("icon"):set_visible(false)
		--self._weapons_panel:child("primary_weapon_panel"):child("icon"):set_visible(false)
		self._panel:set_visible(false)
		self:set_condition("mugshot_normal")
		self:set_cheater(false)
		self:stop_timer()
		self:set_peer_id(nil)
		self:set_ai(nil)
		self:teammate_progress(false)
		self:remove_carry_info()
		if self._main_player then
			self._stamina_panel:child("stamina_bar"):stop()
		end
	end

	function HUDTeammate:set_peer_id(peer_id)
		self._peer_id = peer_id

		local peer = peer_id and managers.network:session():peer(peer_id)
		if peer then
			local outfit = peer:blackmarket_outfit()
			
			for selection, data in ipairs({ outfit.secondary, outfit.primary }) do
				local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(data.factory_id)
				local silencer = managers.weapon_factory:has_perk("silencer", data.factory_id, data.blueprint)
				self:set_weapon_id(selection, weapon_id, silencer)
			end
		end
	end

	function HUDTeammate:set_ai(ai)
		self._ai = ai
		self._downs = 0;
		
		self._weapons_panel:set_visible(not ai and true or false)
		self._equipment_panel:set_visible(not ai and true or false)
		self._special_equipment_panel:set_visible(not ai and true or false)
		self._equipment_panel:set_visible(not ai and true or false)
		--self._carry_panel:set_visible(not ai and true or false)
		if not HUDTeammate.SHOW_AI_KILLS then
			self._kills_panel:set_visible(not ai and true or false)
		end
		
		if not self._main_player then
			self._latency_panel:set_visible(not ai and true or false)
			if ai then
				self._interact_panel:set_visible(false)
			end
			self._name_panel:child("name_sub_panel"):child("name"):set_color((not ai and tweak_data.chat_colors[self._id] or Color.white):with_alpha(1))
		end
	end

	function HUDTeammate:set_state(state)
		--log_print("out.log", string.format("HUDTeammate:set_state(%s)\n", tostring(state)))
	end

	function HUDTeammate:_animate_damage_taken(damage_indicator)
		damage_indicator:set_alpha(1)
		local st = 3
		local t = st
		local st_red_t = 0.5
		local red_t = st_red_t
		while t > 0 do
			local dt = coroutine.yield()
			t = t - dt
			red_t = math.clamp(red_t - dt, 0, 1)
			damage_indicator:set_color(Color(1, red_t / st_red_t, red_t / st_red_t))
			damage_indicator:set_alpha(t / st)
		end
		damage_indicator:set_alpha(0)
	end

	function HUDTeammate:_animate_timer()
		local rounded_timer = math.round(self._timer)
		while self._timer >= 0 do
			local dt = coroutine.yield()
			if self._timer_paused == 0 then
				self._timer = self._timer - dt
				local text = self._timer < 0 and "00" or (math.round(self._timer) < 10 and "0" or "") .. math.round(self._timer)
				self._condition_timer:set_text(text)
				if rounded_timer > math.round(self._timer) then
					rounded_timer = math.round(self._timer)
					if rounded_timer < 11 then
						self._condition_timer:animate(callback(self, self, "_animate_timer_flash"))
					end
				end
			end
		end
	end

	function HUDTeammate:_animate_timer_flash()
		local t = 0
		while t < 0.5 do
			t = t + coroutine.yield()
			local n = 1 - math.sin(t * 180)
			local r = math.lerp(1 or self._point_of_no_return_color.r, 1, n)
			local g = math.lerp(0 or self._point_of_no_return_color.g, 0.8, n)
			local b = math.lerp(0 or self._point_of_no_return_color.b, 0.2, n)
			self._condition_timer:set_color(Color(r, g, b))
			self._condition_timer:set_font_size(math.lerp(self._health_panel:h() * 0.5, self._health_panel:h() * 0.8, n))
		end
		self._condition_timer:set_font_size(self._health_panel:h() * 0.5)
	end

	function HUDTeammate:_animate_voice_com(callsign, original_size, cx, cy)
		local t = 0
		
		while true do
			local dt = coroutine.yield()
			t = t + dt
			
			local size = (math.sin(t * 360) * 0.15 + 1) * original_size
			callsign:set_size(size, size)
			callsign:set_center(cx, cy)
		end
	end

	function HUDTeammate:_animate_carry_pickup(carry_panel)
		local DURATION = 2
		local text = self._carry_panel:child("text")
		local icon = self._carry_panel:child("icon")
		
		local t = DURATION
		while t > 0 do
			local dt = coroutine.yield()
			t = math.max(t-dt, 0)
			
			local r = math.sin(720 * t) * 0.5 + 0.5
			text:set_color(Color(1, 1, 1, r))
			icon:set_color(Color(1, 1, 1, r))
		end
		
		text:set_color(Color(1, 1, 1, 1))
		icon:set_color(Color(1, 1, 1, 1))
	end

	function HUDTeammate:_animate_interact_timer_new(panel, timer)
		local bar = panel:child("interact_bar")
		local text = panel:child("interact_timer")
		local outline = panel:child("outline")
		text:set_size(self._interact_bar_max_width, bar:h())
		text:set_font_size(text:h())
		text:set_color(Color.white)
		text:set_alpha(1)
		text:set_center(outline:center())
		
		self._interact_panel:set_visible(true)
		self._weapons_panel:set_visible(true)
		self._interact_panel:set_alpha(0)
		self._weapons_panel:set_alpha(1)

		local b = 0
		local g_max = 0.9
		local g_min = 0.1
		local r_max = 0.9
		local r_min = 0.1		
		
		local T = 0.5
		local t = 0
		while timer > t do
			if t < T then
				self._weapons_panel:set_alpha(1-t/T)
				self._interact_panel:set_alpha(t/T)
			end
		
			local time_left = timer - t
			local r = t / timer
			bar:set_w(self._interact_bar_max_width * r)
			if r < 0.5 then
				local green = math.clamp(r * 2, 0, 1) * (g_max - g_min) + g_min
				bar:set_gradient_points({ 0, Color(r_max, g_min, b), 1, Color(r_max, green, b) })
			else
				local red = math.clamp(1 - (r - 0.5) * 2, 0, 1) * (r_max - r_min) + r_min
				bar:set_gradient_points({ 0, Color(r_max, g_min, b), 0.5/r, Color(r_max, g_max, b), 1, Color(red, g_max, b) })
			end
			--bar:set_gradient_points({0, Color(0.9, 0.1, 0.1), 1, Color((1-r) * 0.8 + 0.1, r * 0.8 + 0.1, 0.1)})
			text:set_text(string.format("%.1fs", time_left))
			t = t + coroutine.yield()
		end
		
		self._weapons_panel:set_visible(false)
		bar:set_w(self._interact_bar_max_width)
		bar:set_gradient_points({ 0, Color(r_max, g_min, b), 0.5, Color(r_max, g_max, b), 1, Color(r_min, g_max, b) })
		--bar:set_gradient_points({ 0, Color(0.9, 0.1, 0.1), 1, Color(0.1, 0.9, 0.1) })
	end
	
	function HUDTeammate:_animate_interact_timer_complete(panel, success)
		local text = panel:child("interact_timer")
		local h = text:h()
		local w = text:w()
		local x = text:center_x()
		local y = text:center_y()
		text:set_color(success and Color.green or Color.red)
		self._weapons_panel:set_visible(true)
		self._weapons_panel:set_alpha(0)
		self._interact_panel:set_alpha(1)
		if success then 
			text:set_text("DONE") 
		end
		
		local T = 1
		local t = 0
		while t < T do
			local r = math.sin(t/T*90)
			text:set_size(w * (1 + r * 2), h * (1 + r * 2))
			text:set_font_size(text:h())
			text:set_center(x, y)
			self._weapons_panel:set_alpha(t/T)
			self._interact_panel:set_alpha(1-t/T)
			t = t + coroutine.yield()
		end
		
		self._interact_panel:set_visible(false)
		coroutine.yield()	--Prevents text flashing
		text:set_text("")
		text:set_color(Color.white)
		text:set_size(self._interact_bar_max_width, h)
		text:set_font_size(text:h())
		text:set_center(x, y)
	end

	function HUDTeammate:_animate_low_stamina(stamina_bar, stamina_bar_outline)
		local target = Color(1.0, 0.1, 0.1)
		local bar = self._default_stamina_color
		local border = Color.white
	
		while self._animating_low_stamina do
			local t = 0
			while t <= 0.5 do
				t = t + coroutine.yield()
				local ratio = 0.5 + 0.5 * math.sin(t * 720)
				stamina_bar:set_color(Color(
					bar.r + (target.r - bar.r) * ratio, 
					bar.g + (target.g - bar.g) * ratio, 
					bar.b + (target.b - bar.b) * ratio))
				stamina_bar_outline:set_color(Color(
					border.r + (target.r - border.r) * ratio, 
					border.g + (target.g - border.g) * ratio, 
					border.b + (target.b - border.b) * ratio))
			end
		end
		
		stamina_bar:set_color(bar)
		stamina_bar_outline:set_color(border)
	end
	
	function HUDTeammate:_animate_name_label(panel, width)
		local t = 0
		local text = self._name_panel:child("name_sub_panel"):child("name")
		
		while true do
			t = t + coroutine.yield()
			text:set_left(width * (math.sin(90 + t * HUDTeammate._NAME_ANIMATE_SPEED) * 0.5 - 0.5))
		end
	end
	
elseif string.lower(RequiredScript) == "lib/managers/hud/hudtemp" then


	HUDTemp._MARGIN = 8

	function HUDTemp:init(hud)
		self._hud_panel = hud.panel
		if self._hud_panel:child("bag_panel") then
			self._hud_panel:remove(self._hud_panel:child("bag_panel"))
		end
		
		self._destination_size_ratio = 0.5
		
		self._panel = self._hud_panel:panel({
			visible = false,
			name = "bag_panel",
		})
		
		self._bg_box = HUDBGBox_create(self._panel, { }, {})
		
		self._bag_icon = self._panel:bitmap({
			name = "bag_icon",
			texture = "guis/textures/pd2/hud_tabs",
			texture_rect = { 32, 33, 32, 31 },
			visible = true,
			layer = 0,
			color = Color.white,
		})
		
		self._carry_text = self._panel:text({
			name = "carry_text",
			visible = true,
			layer = 2,
			color = Color.white,
			font = tweak_data.hud.medium_font_noshadow,
			align = "left",
			vertical = "center",
		})
	end

	function HUDTemp:show_carry_bag(carry_id, value)
		self._carry_id = carry_id
		self._value = value
		local carry_data = tweak_data.carry[carry_id]
		local type_text = carry_data.name_id and managers.localization:text(carry_data.name_id)
		
		self._carry_text:set_text(utf8.to_upper(type_text))
		local width = self:_get_text_width(self._carry_text) + HUDTemp._MARGIN * 2 + self._bag_icon:w()
		self._bg_box:set_w(width)
		self._bag_icon:set_left(self._bg_box:left() + HUDTemp._MARGIN)
		self._carry_text:set_left(self._bag_icon:right())
		
		self._panel:stop()
		local w, h, x, y = managers.hud:get_teammate_carry_panel_info(HUDManager.PLAYER_PANEL)
		self._panel:animate(callback(self, self, "_animate_pickup"), w, h, x, y, h)
	end

	function HUDTemp:hide_carry_bag()
		self._carry_id = nil
		self._value = nil
		self._panel:stop()
		self._panel:animate(callback(self, self, "_animate_drop"))
	end

	function HUDTemp:_get_text_width(obj)
		local _, _, w, _ = obj:text_rect()
		return w
	end

	function HUDTemp:_animate_pickup(o, ew, eh, ex, ey)
		local function update_size(w, h)
			self._panel:set_size(w * 1.1, h * 2)
			self._carry_text:set_font_size(h)
			local text_w = self:_get_text_width(self._carry_text)
			self._bag_icon:set_size(h, h)
			self._carry_text:set_size(text_w, h)
			
			self._bg_box:set_size(1.3 * (self._carry_text:w() + self._bag_icon:w() * 1.3), h * 1.75)
			self._bg_box:set_center(self._panel:w() / 2 - self._bg_box:w() * 0.05, self._panel:h() / 2)
			self._carry_text:set_center(0, self._panel:h() / 2)
			self._carry_text:set_right(self._panel:w() / 2 + self._carry_text:w() / 2 + self._bag_icon:w() / 4)
			self._bag_icon:set_center(0, self._panel:h() / 2)
			self._bag_icon:set_right(self._carry_text:left() - self._bag_icon:w() / 4)
		end
		
		local FLASH_T = 1
		local MOVE_T = 0.2
		
		self._panel:set_visible(true)
		local sw = ew / self._destination_size_ratio
		local sh = eh / self._destination_size_ratio
		update_size(sw, sh)
		self._panel:set_center(self._hud_panel:center())
		self._panel:set_y(self._hud_panel:h() * 0.6)
		local sx = self._panel:x()
		local sy = self._panel:y()
		
		local t = FLASH_T
		while t > 0 do
			local dt = coroutine.yield()
			t = math.max(t - dt, 0)
			local val = math.sin(4 * 360 * t^2)
			self._panel:set_visible(val > 0)
		end
		self._panel:set_visible(true)
		
		t = MOVE_T
		while t > 0 do
			local dt = coroutine.yield()
			t = math.max(t - dt, 0)
			local ratio = (MOVE_T-t)/MOVE_T
			local x = math.lerp(sx, ex, ratio)
			local y = math.lerp(sy, ey, ratio)
			self._panel:set_position(x, y)
			
			local w = math.lerp(sw, ew, ratio)
			local h = math.lerp(sh, eh, ratio)
			update_size(w, h)
		end
		
		self._panel:set_visible(false)
		managers.hud:set_teammate_carry_info(HUDManager.PLAYER_PANEL, self._carry_id, self._value, true)
	end

	function HUDTemp:_animate_drop(object)
		object:set_visible(false)
	end

	function HUDTemp:set_throw_bag_text() end
	function HUDTemp:set_stamina_value(value) end
	function HUDTemp:set_max_stamina(value) end
	

elseif string.lower(RequiredScript) == "lib/managers/hud/hudassaultcorner" then
	
	
        local init_original = HUDAssaultCorner.init
 
        function HUDAssaultCorner:init(...)
                init_original(self, ...)
               
                local assault_panel = self._hud_panel:child("assault_panel")
                assault_panel:set_right(self._hud_panel:w() / 2 + 133)
                local buffs_panel = self._hud_panel:child("buffs_panel")
                buffs_panel:set_x(assault_panel:left() + self._bg_box:left() - 3 - 200)
               
                local point_of_no_return_panel = self._hud_panel:child("point_of_no_return_panel")
                point_of_no_return_panel:set_right(self._hud_panel:w() / 2 + 133)
               
                local casing_panel = self._hud_panel:child("casing_panel")
                casing_panel:set_right(self._hud_panel:w() / 2 + 133)
               
                local hostages_panel = self._hud_panel:child("hostages_panel")
                hostages_panel:set_alpha(0)
        end

	function HUDAssaultCorner:sync_start_assault(data)
		if self._point_of_no_return then
			return
		end

		if managers.job:current_difficulty_stars() > 0 then
			local ids_risk = Idstring("risk")
			self:_start_assault({
				"hud_assault_assault",
				"hud_assault_end_line",
				ids_risk,
				"hud_assault_end_line",
				"hud_assault_assault",
				"hud_assault_end_line",
				ids_risk,
				"hud_assault_end_line"
			})
		else
			self:_start_assault({
				"hud_assault_assault",
				"hud_assault_end_line",
				"hud_assault_assault",
				"hud_assault_end_line",
				"hud_assault_assault",
				"hud_assault_end_line"
			})
		end
	end

	function HUDAssaultCorner:show_point_of_no_return_timer()
		local delay_time = self._assault and 1.2 or 0
		self:_end_assault()
		local point_of_no_return_panel = self._hud_panel:child("point_of_no_return_panel")
		point_of_no_return_panel:stop()
		point_of_no_return_panel:animate(callback(self, self, "_animate_show_noreturn"), delay_time)
		self._point_of_no_return = true
	end

	function HUDAssaultCorner:hide_point_of_no_return_timer()
		self._noreturn_bg_box:stop()
		self._hud_panel:child("point_of_no_return_panel"):set_visible(false)
		self._point_of_no_return = false
	end

	function HUDAssaultCorner:set_control_info(...) end
	function HUDAssaultCorner:show_casing(...) end
	function HUDAssaultCorner:hide_casing(...) end
	
	
elseif string.lower(RequiredScript) == "lib/managers/hud/hudobjectives" then
	
	
	HUDObjectives._TEXT_MARGIN = 8

	function HUDObjectives:init(hud)
		if hud.panel:child("objectives_panel") then
			hud.panel:remove(self._panel:child("objectives_panel"))
		end

		self._panel = hud.panel:panel({
			visible = false,
			name = "objectives_panel",
			h = 100,
			w = 500,
			x = 60,
			valign = "top"
		})
			
		self._bg_box = HUDBGBox_create(self._panel, {
			w = 500,
			h = 38,
		})
		
		self._objective_text = self._bg_box:text({
			name = "objective_text",
			visible = false,
			layer = 2,
			color = Color.white,
			text = "",
			font_size = tweak_data.hud.active_objective_title_font_size,
			font = tweak_data.hud.medium_font_noshadow,
			align = "left",
			vertical = "center",
			w = self._bg_box:w(),
			x = HUDObjectives._TEXT_MARGIN
		})
		
		self._amount_text = self._bg_box:text({
			name = "amount_text",
			visible = false,
			layer = 2,
			color = Color.white,
			text = "",
			font_size = tweak_data.hud.active_objective_title_font_size,
			font = tweak_data.hud.medium_font_noshadow,
			align = "left",
			vertical = "center",
			w = self._bg_box:w(),
			x = HUDObjectives._TEXT_MARGIN
		})
	end

	function HUDObjectives:activate_objective(data)
		self._active_objective_id = data.id
		
		self._panel:set_visible(true)
		self._objective_text:set_text(utf8.to_upper(data.text))
		self._objective_text:set_visible(true)
		self._amount_text:set_visible(false)
		
		local width = self:_get_text_width(self._objective_text)
		
		if data.amount then
			self:update_amount_objective(data)
			self._amount_text:set_left(width + HUDObjectives._TEXT_MARGIN)
			width = width + self:_get_text_width(self._amount_text)
		else
			self._amount_text:set_text("")
		end

		self._bg_box:set_w(HUDObjectives._TEXT_MARGIN * 2 + width)
		self._bg_box:stop()
		--self._amount_text:animate(callback(self, self, "_animate_new_objective"))
		--self._objective_text:animate(callback(self, self, "_animate_new_objective"))
		self._bg_box:animate(callback(self, self, "_animate_update_objective"))
	end

	function HUDObjectives:update_amount_objective(data)
		if data.id ~= self._active_objective_id then
			return
		end

		self._amount_text:set_visible(true)
		self._amount_text:set_text(": " .. (data.current_amount or 0) .. "/" .. data.amount)
		self._amount_text:set_x(self:_get_text_width(self._objective_text) + HUDObjectives._TEXT_MARGIN)
		self._bg_box:set_w(HUDObjectives._TEXT_MARGIN * 2 + self:_get_text_width(self._objective_text) + self:_get_text_width(self._amount_text))
		self._bg_box:stop()
		self._bg_box:animate(callback(self, self, "_animate_update_objective"))
	end

	function HUDObjectives:remind_objective(id)
		if id ~= self._active_objective_id then
			return
		end
		
		self._bg_box:stop()
		self._bg_box:animate(callback(self, self, "_animate_update_objective"))
	end

	function HUDObjectives:complete_objective(data)
		if data.id ~= self._active_objective_id then
			return
		end

		self._amount_text:set_visible(false)
		self._objective_text:set_visible(false)
		self._panel:set_visible(false)
		self._bg_box:set_w(0)
	end

	function HUDObjectives:_animate_new_objective(object)
		local TOTAL_T = 2
		local t = TOTAL_T
		object:set_color(Color(1, 1, 1, 1))
		while t > 0 do
			local dt = coroutine.yield()
			t = t - dt
			object:set_color(Color(1, 1 - (0.5 * math.sin(t * 360) + 0.5), 1, 1 - (0.5 * math.sin(t * 360) + 0.5)))
		end
		object:set_color(Color(1, 1, 1, 1))
	end

	function HUDObjectives:_animate_update_objective(object)
		local TOTAL_T = 2
		local t = TOTAL_T
		object:set_y(0)
		while t > 0 do
			local dt = coroutine.yield()
			t = t - dt
			object:set_y(math.round((1 + math.sin((TOTAL_T - t) * 450 * 2)) * (12 * (t / TOTAL_T))))
		end
		object:set_y(0)
	end

	function HUDObjectives:_get_text_width(obj)
		local _, _, w, _ = obj:text_rect()
		return w
	end	
	
	
elseif string.lower(RequiredScript) == "lib/managers/hud/hudheisttimer" then
	
	
	function HUDHeistTimer:init(hud)
		self._hud_panel = hud.panel
		if self._hud_panel:child("heist_timer_panel") then
			self._hud_panel:remove(self._hud_panel:child("heist_timer_panel"))
		end
		
		self._heist_timer_panel = self._hud_panel:panel({
			visible = true,
			name = "heist_timer_panel",
			h = 40,
			w = 50,
			valign = "top",
			layer = 0
		})
		self._timer_text = self._heist_timer_panel:text({
			name = "timer_text",
			text = "00:00",
			font_size = 28,
			font = tweak_data.hud.medium_font_noshadow,
			color = Color.white,
			align = "center",
			vertical = "center",
			layer = 1,
			wrap = false,
			word_wrap = false
		})
		self._last_time = 0
	end
	
	
elseif string.lower(RequiredScript) == "lib/managers/hud/hudchat" then
	

	HUDChat.LINE_HEIGHT = WolfHUD.settings.LINE_HEIGHT or 15
	HUDChat.WIDTH = 375
	HUDChat.MAX_OUTPUT_LINES = WolfHUD.settings.MAX_OUTPUT_LINES or 8
	HUDChat.MAX_INPUT_LINES = 5
	
	local enter_key_callback_original = HUDChat.enter_key_callback
	local esc_key_callback_original = HUDChat.esc_key_callback
	local _on_focus_original = HUDChat._on_focus
	local _loose_focus_original = HUDChat._loose_focus
	
	function HUDChat:init(ws, hud)
		local fullscreen = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
		
		self._x_offset = (fullscreen.panel:w() - hud.panel:w()) / 2
		self._y_offset = (fullscreen.panel:h() - hud.panel:h()) / 2
		self._esc_callback = callback(self, self, "esc_key_callback")
		self._enter_callback = callback(self, self, "enter_key_callback")
		self._typing_callback = 0
		self._skip_first = false
		self._messages = {}
		self._current_line_offset = 0
		self._total_message_lines = 0
		self._current_input_lines = 1
		self._ws = ws
		self._parent = hud.panel
		self:set_channel_id(ChatManager.GAME)
		
		self._panel = self._parent:panel({
			name = "chat_panel",
			h = HUDChat.LINE_HEIGHT * (HUDChat.MAX_OUTPUT_LINES + 1),
			w = HUDChat.WIDTH,
		})
		
		--Default chat box position
		--self._panel:set_left(0)
		--self._panel:set_bottom(self._parent:h() - 112)
		--Custom chat box position
		self._panel:set_right(self._parent:w())
		self._panel:set_bottom(self._parent:h())
		
		self:_create_output_panel()
		self:_create_input_panel()
		self:_layout_output_panel()
	end

	function HUDChat:_create_input_panel()
		self._input_panel = self._panel:panel({
			name = "input_panel",
			alpha = 0,
			h = HUDChat.LINE_HEIGHT,
			w = self._panel:w(),
			layer = 1,
		})
		local focus_indicator = self._input_panel:rect({
			name = "focus_indicator",
			visible = false,
			color = Color.white:with_alpha(0.2),
			layer = 0
		})	
		local gradient = self._input_panel:gradient({	--TODO: Why won't this POS behave?
			name = "input_bg",
			visible = false,	--TODO: Remove
			alpha = 0,	--TODO: Remove
			gradient_points = { 0, Color.white:with_alpha(0), 0.2, Color.white:with_alpha(0.25), 1, Color.white:with_alpha(0) },
			layer = -1,
			valign = "grow",
			blend_mode = "sub",
		})
		local bg_simple = self._input_panel:rect({
			name = "input_bg_simple",
			alpha = 0.5,
			color = Color.black,
			layer = -1,
			h = HUDChat.MAX_INPUT_LINES * HUDChat.LINE_HEIGHT,--self._input_panel:h(),
			w = self._input_panel:w(),
		})
		
		local input_prompt = self._input_panel:text({
			name = "input_prompt",
			text = utf8.to_upper(managers.localization:text("debug_chat_say")),
			font = tweak_data.menu.pd2_small_font,
			font_size = HUDChat.LINE_HEIGHT * 0.95,
			h = HUDChat.LINE_HEIGHT,
			align = "left",
			halign = "left",
			vertical = "center",
			hvertical = "center",
			blend_mode = "normal",
			color = Color.white,
			layer = 1
		})
		local _, _, w, h = input_prompt:text_rect()
		input_prompt:set_w(w)
		input_prompt:set_left(0)
		
		local input_text = self._input_panel:text({
			name = "input_text",
			text = "",
			font = tweak_data.menu.pd2_small_font,
			font_size = HUDChat.LINE_HEIGHT * 0.95,
			h = HUDChat.LINE_HEIGHT,
			w = self._input_panel:w() - input_prompt:w() - 4,
			align = "left",
			halign = "left",
			vertical = "center",
			hvertical = "center",
			blend_mode = "normal",
			color = Color.white,
			layer = 1,
			wrap = true,
			word_wrap = false
		})
		input_text:set_right(self._input_panel:w())
		
		local caret = self._input_panel:rect({
			name = "caret",
			layer = 2,
			color = Color(0.05, 1, 1, 1)
		})
		
		focus_indicator:set_shape(input_text:shape())
		self._input_panel:set_bottom(self._panel:h())
	end

	function HUDChat:_create_output_panel()
		local output_panel = self._panel:panel({
			name = "output_panel",
			h = 0,
			w = self._panel:w(),
			layer = 1,
		})
		local scroll_bar_bg = output_panel:rect({
			name = "scroll_bar_bg",
			color = Color.black,
			layer = -1,
			alpha = 0.35,
			visible = false,
			blend_mode = "normal",
			w = 8,
			h = HUDChat.LINE_HEIGHT * HUDChat.MAX_OUTPUT_LINES,
		})
		scroll_bar_bg:set_right(output_panel:w())
		
		local scroll_bar_up = output_panel:bitmap({
			name = "scroll_bar_up",
			texture = "guis/textures/pd2/scrollbar_arrows",
			texture_rect = { 1, 1, 9, 10 },
			w = scroll_bar_bg:w(),
			h = scroll_bar_bg:w(),
			visible = false,
			blend_mode = "add",
			color = Color.white,
		})
		scroll_bar_up:set_right(output_panel:w())
		
		local scroll_bar_down = output_panel:bitmap({
			name = "scroll_bar_down",
			texture = "guis/textures/pd2/scrollbar_arrows",
			texture_rect = { 1, 1, 9, 10 },
			w = scroll_bar_bg:w(),
			h = scroll_bar_bg:w(),
			visible = false,
			blend_mode = "add",
			color = Color.white,
			rotation = 180,
		})
		scroll_bar_down:set_right(output_panel:w())
		scroll_bar_down:set_bottom(output_panel:h())
		
		local scroll_bar_position = output_panel:rect({
			name = "scroll_bar_position",
			color = Color.white,
			alpha = 0.8,
			visible = false,
			blend_mode = "normal",
			w = scroll_bar_bg:w() * 0.6,
			h = 3,
		})
		scroll_bar_position:set_center_x(scroll_bar_bg:center_x())
		
		output_panel:gradient({
			name = "output_bg",
			--gradient_points = { 0, Color.white:with_alpha(0), 0.2, Color.white:with_alpha(0.25), 1, Color.white:with_alpha(0) },
			--gradient_points = { 0, Color.white:with_alpha(0.4), 0.2, Color.white:with_alpha(0.3), 1, Color.white:with_alpha(0.2) },
			gradient_points = { 0, Color.white:with_alpha(0.3), 0.3, Color.white:with_alpha(0.1), 0.5, Color.white:with_alpha(0.2) , 0.7, Color.white:with_alpha(0.1), 1, Color.white:with_alpha(0.3) },
			layer = -1,
			valign = "grow",
			blend_mode = "sub",
			w = output_panel:w() - scroll_bar_bg:w() ,
		})
		
		output_panel:set_bottom(self._panel:h())
	end

	function HUDChat:_layout_output_panel()
		local output_panel = self._panel:child("output_panel")
		
		output_panel:set_h(HUDChat.LINE_HEIGHT * math.min(HUDChat.MAX_OUTPUT_LINES, self._total_message_lines))
		if self._total_message_lines > HUDChat.MAX_OUTPUT_LINES then
			local scroll_bar_bg = output_panel:child("scroll_bar_bg")
			local scroll_bar_up = output_panel:child("scroll_bar_up")
			local scroll_bar_down = output_panel:child("scroll_bar_down")
			local scroll_bar_position = output_panel:child("scroll_bar_position")
			
			scroll_bar_bg:show()
			scroll_bar_up:show()
			scroll_bar_down:show()
			scroll_bar_position:show()
			scroll_bar_down:set_bottom(output_panel:h())
			
			local positon_height_area = scroll_bar_bg:h() - scroll_bar_up:h() - scroll_bar_down:h() - 4
			scroll_bar_position:set_h(math.max((HUDChat.MAX_OUTPUT_LINES / self._total_message_lines) * positon_height_area, 3))
			scroll_bar_position:set_center_y((1 - self._current_line_offset / self._total_message_lines) * positon_height_area + scroll_bar_up:h() + 2 - scroll_bar_position:h() / 2)
		end
		output_panel:set_bottom(self._input_panel:top())

		local y = -self._current_line_offset * HUDChat.LINE_HEIGHT
		for i = #self._messages, 1, -1 do
			local msg = self._messages[i]
			msg.panel:set_bottom(output_panel:h() - y)
			y = y + msg.panel:h()
		end
	end
	
	function HUDChat:receive_message(name, message, color, icon)
		local output_panel = self._panel:child("output_panel")
		local scroll_bar_bg = output_panel:child("scroll_bar_bg")
		local x_offset = 0
		
		local msg_panel = output_panel:panel({
			name = "msg_" .. tostring(#self._messages),
			w = output_panel:w() - scroll_bar_bg:w(),
		})
		local msg_panel_bg = msg_panel:rect({
			name = "bg",
			alpha = 0.25,
			color = color,
			w = msg_panel:w(),
		})
		
		if icon then
			local icon_texture, icon_texture_rect = tweak_data.hud_icons:get_icon_data(icon)
			local icon_bitmap = msg_panel:bitmap({
				name = "icon",
				texture = icon_texture,
				texture_rect = icon_texture_rect,
				color = color,
				h = HUDChat.LINE_HEIGHT * 0.85,
				w = HUDChat.LINE_HEIGHT * 0.85,
				layer = 1,
			})
			icon_bitmap:set_center_y(HUDChat.LINE_HEIGHT / 2)
			x_offset = icon_bitmap:w() + 1
		end

		local text = msg_panel:text({
			name = "msg",
			text = name .. ": " .. message,
			font = tweak_data.menu.pd2_small_font,
			font_size = HUDChat.LINE_HEIGHT * 0.95,
			w = msg_panel:w() - x_offset,
			x = x_offset,
			align = "left",
			halign = "left",
			vertical = "top",
			hvertical = "top",
			blend_mode = "normal",
			wrap = true,
			word_wrap = true,
			color = Color.white,
			layer = 1
		})
		local no_lines = text:number_of_lines()
		text:set_range_color(0, utf8.len(name) + 1, color)
		text:set_h(HUDChat.LINE_HEIGHT * no_lines)
		text:set_kern(text:kern())
		msg_panel:set_h(HUDChat.LINE_HEIGHT * no_lines)
		msg_panel_bg:set_h(HUDChat.LINE_HEIGHT * no_lines)
		
		self._total_message_lines = self._total_message_lines + no_lines
		table.insert(self._messages, { panel = msg_panel, name = name, lines = no_lines })
		
		self:_layout_output_panel()
		if not self._focus then
			local output_panel = self._panel:child("output_panel")
			output_panel:stop()
			output_panel:animate(callback(self, self, "_animate_show_component"), output_panel:alpha())
			output_panel:animate(callback(self, self, "_animate_fade_output"))
		end
	end

	function HUDChat:enter_text(o, s)
		if managers.hud and managers.hud:showing_stats_screen() then
			return
		end
		if self._skip_first then
			self._skip_first = false
			return
		end
		local text = self._input_panel:child("input_text")
		if type(self._typing_callback) ~= "number" then
			self._typing_callback()
		end
		text:replace_text(s)
		
		local lbs = text:line_breaks()
		if #lbs <= HUDChat.MAX_INPUT_LINES then
			self:_set_input_lines(#lbs)
		else
			local s = lbs[HUDChat.MAX_INPUT_LINES + 1]
			local e = utf8.len(text:text())
			text:set_selection(s, e)
			text:replace_text("")
		end
		self:update_caret()
	end

	function HUDChat:enter_key_callback(...)
		enter_key_callback_original(self, ...)
		self:_set_input_lines(1)
		self:_set_line_offset(0)
	end

	function HUDChat:esc_key_callback(...)
		esc_key_callback_original(self, ...)
		self:_set_input_lines(1)
		self:_set_line_offset(0)
	end

	function HUDChat:_set_input_lines(no_lines)
		if no_lines ~= self._current_input_lines then
			no_lines = math.max(no_lines, 1)
			self._current_input_lines = no_lines
			self._input_panel:set_h(no_lines * HUDChat.LINE_HEIGHT)
			self._input_panel:child("input_text"):set_h(no_lines * HUDChat.LINE_HEIGHT)
			self._input_panel:set_bottom(self._panel:h())
			self._panel:child("output_panel"):set_bottom(self._input_panel:top())
		end
	end
	
	function HUDChat:set_offset(offset)
		self._panel:set_bottom(self._parent:h() - offset)
	end
	
	function HUDChat:update_key_down(o, k)
		wait(0.6)
		local text = self._input_panel:child("input_text")
		while self._key_pressed == k do
			local s, e = text:selection()
			local n = utf8.len(text:text())
			local d = math.abs(e - s)
			if self._key_pressed == Idstring("backspace") then
				if s == e and s > 0 then
					text:set_selection(s - 1, e)
				end
				text:replace_text("")
				self:_set_input_lines(#(text:line_breaks()))
				if not (utf8.len(text:text()) < 1) or type(self._esc_callback) ~= "number" then
				end
			elseif self._key_pressed == Idstring("delete") then
				if s == e and s < n then
					text:set_selection(s, e + 1)
				end
				text:replace_text("")
				self:_set_input_lines(#(text:line_breaks()))
				if not (utf8.len(text:text()) < 1) or type(self._esc_callback) ~= "number" then
				end
			elseif self._key_pressed == Idstring("left") then
				if s < e then
					text:set_selection(s, s)
				elseif s > 0 then
					text:set_selection(s - 1, s - 1)
				end
			elseif self._key_pressed == Idstring("right") then
				if s < e then
					text:set_selection(e, e)
				elseif s < n then
					text:set_selection(s + 1, s + 1)
				end
			elseif self._key_pressed == Idstring("up") then
				self:_change_line_offset(1)
			elseif self._key_pressed == Idstring("down") then
				self:_change_line_offset(-1)
			elseif self._key_pressed == Idstring("page up") then
				self:_change_line_offset(HUDChat.MAX_OUTPUT_LINES - self._current_input_lines)
			elseif self._key_pressed == Idstring("page down") then
				self:_change_line_offset(-(HUDChat.MAX_OUTPUT_LINES - self._current_input_lines))
			else
				self._key_pressed = false
			end
			self:update_caret()
			wait(0.03)
		end
	end

	function HUDChat:key_press(o, k)
		if self._skip_first then
			self._skip_first = false
			return
		end
		if not self._enter_text_set then
			self._input_panel:enter_text(callback(self, self, "enter_text"))
			self._enter_text_set = true
		end
		local text = self._input_panel:child("input_text")
		local s, e = text:selection()
		local n = utf8.len(text:text())
		local d = math.abs(e - s)
		self._key_pressed = k
		text:stop()
		text:animate(callback(self, self, "update_key_down"), k)
		if k == Idstring("backspace") then
			if s == e and s > 0 then
				text:set_selection(s - 1, e)
			end
			text:replace_text("")
			if not (utf8.len(text:text()) < 1) or type(self._esc_callback) ~= "number" then
			end
			self:_set_input_lines(#(text:line_breaks()))
		elseif k == Idstring("delete") then
			if s == e and s < n then
				text:set_selection(s, e + 1)
			end
			text:replace_text("")
			if not (utf8.len(text:text()) < 1) or type(self._esc_callback) ~= "number" then
			end
			self:_set_input_lines(#(text:line_breaks()))
		elseif k == Idstring("left") then
			if s < e then
				text:set_selection(s, s)
			elseif s > 0 then
				text:set_selection(s - 1, s - 1)
			end
		elseif k == Idstring("right") then
			if s < e then
				text:set_selection(e, e)
			elseif s < n then
				text:set_selection(s + 1, s + 1)
			end
		elseif self._key_pressed == Idstring("up") then
			self:_change_line_offset(1)
		elseif self._key_pressed == Idstring("down") then
			self:_change_line_offset(-1)
		elseif self._key_pressed == Idstring("page up") then
			self:_change_line_offset(HUDChat.MAX_OUTPUT_LINES - self._current_input_lines)
		elseif self._key_pressed == Idstring("page down") then
			self:_change_line_offset(-(HUDChat.MAX_OUTPUT_LINES - self._current_input_lines))
		elseif self._key_pressed == Idstring("end") then
			text:set_selection(n, n)
		elseif self._key_pressed == Idstring("home") then
			text:set_selection(0, 0)
		elseif k == Idstring("enter") then
			if type(self._enter_callback) ~= "number" then
				self._enter_callback()
			end
		elseif k == Idstring("esc") and type(self._esc_callback) ~= "number" then
			text:set_text("")
			text:set_selection(0, 0)
			self._esc_callback()
		end
		self:update_caret()
	end

	function HUDChat:_change_line_offset(diff)
		if diff ~= 0 then
			self:_set_line_offset(math.clamp(self._current_line_offset + diff, 0, math.max(self._total_message_lines - HUDChat.MAX_OUTPUT_LINES + self._current_input_lines - 1, 0)))
		end
	end
	
	function HUDChat:_set_line_offset(offset)
		if self._current_line_offset ~= offset then
			self._current_line_offset = offset
			self:_layout_output_panel()
		end
	end

	function HUDChat:_on_focus(...)
		if not self._focus then
			managers.mouse_pointer:use_mouse({
				mouse_move = callback(self, self, "_mouse_move"),
				mouse_press = callback(self, self, "_mouse_press"),
				mouse_release = callback(self, self, "_mouse_release"),
				mouse_click = callback(self, self, "_mouse_click"),
				id = "ingame_chat_mouse",
			})
			return _on_focus_original(self, ...)
		end
	end
	
	function HUDChat:_loose_focus(...)
		self:disconnect_mouse()
		return _loose_focus_original(self, ...)
	end
	
	function HUDChat:disconnect_mouse()
		if self._focus then
			managers.mouse_pointer:remove_mouse("ingame_chat_mouse")
		end
	end
	
	function HUDChat:_mouse_move(o, x, y)
		if self._mouse_state then
			x = x - self._x_offset
			y = y - self._y_offset
		
			--TODO: Move relative to initial click position, change y based on y move difference instead (or fuck it and leave it as it is, it works)
			local output_panel = self._panel:child("output_panel")
			self:_move_scroll_bar_position_center(y - self._panel:y() - output_panel:y())
			self._mouse_state = y
		end
	end
	
	function HUDChat:_mouse_press(o, button, x, y)
		x = x - self._x_offset
		y = y - self._y_offset
		
		if button == Idstring("mouse wheel up") then
			self:_change_line_offset(1)
		elseif button == Idstring("mouse wheel down") then
			self:_change_line_offset(-1)
		elseif button == Idstring("0") then
			local scroll_bar_position = self._panel:child("output_panel"):child("scroll_bar_position")
			if scroll_bar_position:inside(x, y) then
				self._mouse_state = y
			end
		end
	end
	
	function HUDChat:_mouse_release(o, button, x, y)
		x = x - self._x_offset
		y = y - self._y_offset
		
		if button == Idstring("0") then
			self._mouse_state = nil
		end
	end
	
	function HUDChat:_mouse_click(o, button, x, y)
		x = x - self._x_offset
		y = y - self._y_offset
		
		local output_panel = self._panel:child("output_panel")
		local scroll_bar_bg = output_panel:child("scroll_bar_bg")
		local scroll_bar_up = output_panel:child("scroll_bar_up")
		local scroll_bar_down = output_panel:child("scroll_bar_down")
		local scroll_bar_position = output_panel:child("scroll_bar_position")
		
		if scroll_bar_up:inside(x, y) then
			self:_change_line_offset(1)
		elseif scroll_bar_down:inside(x, y) then
			self:_change_line_offset(-1)
		elseif scroll_bar_position:inside(x, y) then

		elseif scroll_bar_bg:inside(x, y) then
			self:_move_scroll_bar_position_center(y - self._panel:y() - output_panel:y())
		end
	end
	
	function HUDChat:_move_scroll_bar_position_center(y)
		local output_panel = self._panel:child("output_panel")
		local scroll_bar_bg = output_panel:child("scroll_bar_bg")
		local scroll_bar_up = output_panel:child("scroll_bar_up")
		local scroll_bar_down = output_panel:child("scroll_bar_down")
		local scroll_bar_position = output_panel:child("scroll_bar_position")
		
		y = y + scroll_bar_position:h() / 2
		local positon_height_area = scroll_bar_bg:h() - scroll_bar_up:h() - scroll_bar_down:h() - 4
		local new_line_offset = math.round((1 - ((y - scroll_bar_up:h() - 2) / positon_height_area)) * self._total_message_lines)
		self:_change_line_offset(new_line_offset - self._current_line_offset)
	end

elseif string.lower(RequiredScript) == "lib/units/beings/player/states/playerbleedout" then
	local player_bleed_out_original = PlayerBleedOut._enter
	function PlayerBleedOut:_enter(enter_data)
		player_bleed_out_original(self, enter_data)
		managers.hud._teammate_panels[HUDManager.PLAYER_PANEL]:downed()
	end
elseif string.lower(RequiredScript) == "lib/units/beings/player/huskplayermovement" then
	local HuskPlayerMovement_start_bleedout = HuskPlayerMovement._start_bleedout
	function HuskPlayerMovement:_start_bleedout(event_desc)
		local char_data = managers.criminals:character_data_by_unit(self._unit)
		managers.hud._teammate_panels[char_data.panel_id or HUDManager.PLAYER_PANEL]:downed()
		return HuskPlayerMovement_start_bleedout(self, event_desc)
	end
elseif string.lower(RequiredScript) == "lib/units/equipment/doctor_bag/doctorbagbase" then
	local doctor_bag_take_original = DoctorBagBase.take
	function DoctorBagBase:take(unit)
		managers.hud._teammate_panels[HUDManager.PLAYER_PANEL]:reset_downs()
		doctor_bag_take_original(self, unit)
	end
elseif string.lower(RequiredScript) == "lib/network/handlers/unitnetworkhandler" then
	local UnitNetworkHandler_sync_doctor_bag_taken = UnitNetworkHandler.sync_doctor_bag_taken
	function UnitNetworkHandler:sync_doctor_bag_taken(unit, amount, sender)
		UnitNetworkHandler_sync_doctor_bag_taken(self, unit, amount, sender)
		local peer = self._verify_sender(sender)
		local char_data = managers.criminals:character_data_by_peer_id(peer:id())
		managers.hud._teammate_panels[char_data.panel_id or HUDManager.PLAYER_PANEL]:reset_downs()
	end
elseif string.lower(RequiredScript) == "lib/managers/trademanager" then
	local announce_spawn_orig = TradeManager._announce_spawn
	function TradeManager:_announce_spawn(criminal_name)
		announce_spawn_orig(self, criminal_name)
		local char_data = managers.criminals:character_data_by_name(criminal_name)
		managers.hud._teammate_panels[char_data.panel_id or HUDManager.PLAYER_PANEL]:reset_downs()
	end
end