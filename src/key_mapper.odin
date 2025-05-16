package iris

import sml_arr "core:container/small_array"
import rl "vendor:raylib"

Modifier :: enum u8 {
	Shift,
	Ctrl,
	Alt,
	Super,
}

Modifiers :: distinct bit_set[Modifier]

Key_Map_Layer :: enum {
	App,
	Global_Fx_Mode,
	Global_Scene_Mode,
	Scene_Mode,
}

Action_Param :: struct {
	value: int,
	range: int,
}

Action_Type :: enum {
	null,
	app_toggle_fps,
	app_toggle_cursor,
	app_shut_down,
	app_reboot_composite_pal,
	app_reboot_composite_ntsc,
	app_reboot_hdmi,
	global_scene_mode_enter,
	global_scene_switch,
	global_fx_mode_enter,
	enter_scene_mode,
	audio_input_level,
	scene_set_param_1,
	scene_set_param_2,
	scene_set_param_3,
	fx_toggle_warp,
	fx_toggle_pixelate,
	fx_clear,
}

Action :: struct {
	type:  Action_Type,
	param: Maybe(Action_Param),
}

Action_Key_Map :: #sparse[rl.KeyboardKey]Action
Key_Map :: [Key_Map_Layer]Action_Key_Map
Layer_Modifiers :: [Key_Map_Layer]Modifiers

MAX_CONCURRENT_ACTIONS :: 4

Key_Mapper :: struct {
	mappings:                Key_Map,
	layer_modifiers:         Layer_Modifiers,
	currently_latched_layer: Key_Map_Layer,
	actions:                 sml_arr.Small_Array(MAX_CONCURRENT_ACTIONS, Action),
}

enumerate_key_range_mappings :: proc(
	key_map: ^Key_Map,
	layer: Key_Map_Layer,
	keys: []rl.KeyboardKey,
	action_type: Action_Type,
) {
	for k, i in keys {
		key_map[layer][k] = {action_type, Action_Param{i, len(keys)}}
	}
}

key_mapper_initialize :: proc(key_mapper: ^Key_Mapper) {
	key_mapper.layer_modifiers[.App] = {.Ctrl, .Alt}
	key_mapper.layer_modifiers[.Global_Scene_Mode] = {.Alt}
	key_mapper.layer_modifiers[.Global_Fx_Mode] = {.Shift}
	key_mapper.layer_modifiers[.Scene_Mode] = {.Ctrl}

	key_mapper.mappings[.App][.SLASH] = {.app_toggle_fps, {}}
	key_mapper.mappings[.App][.C] = {.app_toggle_cursor, {}}
	key_mapper.mappings[.App][.Q] = {.app_shut_down, {}}
	key_mapper.mappings[.App][.P] = {.app_reboot_composite_pal, {}}
	key_mapper.mappings[.App][.N] = {.app_reboot_composite_ntsc, {}}
	key_mapper.mappings[.App][.H] = {.app_reboot_hdmi, {}}

	key_mapper.mappings[.Global_Scene_Mode][.ENTER] = {.global_scene_mode_enter, {}}
	key_mapper.mappings[.Global_Scene_Mode][.TAB] = {.global_scene_mode_enter, {}}

	key_mapper.mappings[.Global_Fx_Mode][.ENTER] = {.global_fx_mode_enter, {}}
	key_mapper.mappings[.Global_Fx_Mode][.TAB] = {.global_fx_mode_enter, {}}

	key_mapper.mappings[.Scene_Mode][.ENTER] = {.enter_scene_mode, {}}
	key_mapper.mappings[.Scene_Mode][.TAB] = {.enter_scene_mode, {}}

	key_mapper.mappings[.Global_Fx_Mode][.W] = {.fx_toggle_warp, {}}
	key_mapper.mappings[.Global_Fx_Mode][.P] = {.fx_toggle_pixelate, {}}
	key_mapper.mappings[.Global_Fx_Mode][.BACKSPACE] = {.fx_clear, {}}

	enumerate_key_range_mappings(
		&key_mapper.mappings,
		.Scene_Mode,
		{.Q, .W, .E, .R, .T, .Y, .U, .I, .O, .P},
		.scene_set_param_1,
	)

	enumerate_key_range_mappings(
		&key_mapper.mappings,
		.Scene_Mode,
		{.A, .S, .D, .F, .G, .H, .J, .K, .L},
		.scene_set_param_2,
	)

	enumerate_key_range_mappings(
		&key_mapper.mappings,
		.Scene_Mode,
		{.Z, .X, .C, .V, .B, .N, .M},
		.scene_set_param_3,
	)

	enumerate_key_range_mappings(
		&key_mapper.mappings,
		.Global_Scene_Mode,
		{.ONE, .TWO, .THREE, .FOUR, .FIVE, .SIX, .SEVEN, .EIGHT, .NINE, .ZERO},
		.audio_input_level,
	)

	enumerate_key_range_mappings(
		&key_mapper.mappings,
		.Global_Scene_Mode,
		{
			.Q,
			.W,
			.E,
			.R,
			.T,
			.Y,
			.U,
			.I,
			.O,
			.P,
			.A,
			.S,
			.D,
			.F,
			.G,
			.H,
			.J,
			.K,
			.L,
			.Z,
			.X,
			.C,
			.V,
			.B,
			.N,
			.M,
		},
		.global_scene_switch,
	)
}

key_mapper_update :: proc(key_mapper: ^Key_Mapper) -> []Action {
	active_primary_keys: sml_arr.Small_Array(MAX_CONCURRENT_ACTIONS, rl.KeyboardKey)
	active_modifier_keys := get_active_modifiers()

	k := rl.GetKeyPressed()

	for k != rl.KeyboardKey.KEY_NULL {
		if (k < rl.KeyboardKey.LEFT_SHIFT) {
			if sml_arr.len(active_primary_keys) + 1 > sml_arr.cap(active_primary_keys) {
				sml_arr.pop_front(&active_primary_keys)
			}

			sml_arr.push_back(&active_primary_keys, k)
		}
		k = rl.GetKeyPressed()
	}

	layer := get_current_layer(key_mapper^, active_modifier_keys)

	sml_arr.clear(&key_mapper.actions)

	for primary_key in sml_arr.slice(&active_primary_keys) {
		action := key_mapper.mappings[layer][primary_key]

		if (action.type != .null) {
			sml_arr.append(&key_mapper.actions, action)
		}
	}

	return sml_arr.slice(&key_mapper.actions)
}

key_mapper_latch_layer :: proc(key_mapper: ^Key_Mapper, layer: Key_Map_Layer) {
	key_mapper.currently_latched_layer = layer
}

get_active_modifiers :: proc() -> Modifiers {
	active_modifiers: Modifiers

	if (rl.IsKeyDown(rl.KeyboardKey.LEFT_SHIFT) || rl.IsKeyDown(rl.KeyboardKey.RIGHT_SHIFT)) {
		active_modifiers += {.Shift}
	}

	if (rl.IsKeyDown(rl.KeyboardKey.LEFT_CONTROL) || rl.IsKeyDown(rl.KeyboardKey.RIGHT_CONTROL)) {
		active_modifiers += {.Ctrl}
	}

	if (rl.IsKeyDown(rl.KeyboardKey.LEFT_ALT) || rl.IsKeyDown(rl.KeyboardKey.RIGHT_ALT)) {
		active_modifiers += {.Alt}
	}

	if (rl.IsKeyDown(rl.KeyboardKey.LEFT_SUPER) || rl.IsKeyDown(rl.KeyboardKey.RIGHT_SUPER)) {
		active_modifiers += {.Super}
	}

	return active_modifiers
}

get_current_layer :: proc(key_mapper: Key_Mapper, active_modifiers: Modifiers) -> Key_Map_Layer {
	layer := key_mapper.currently_latched_layer

	for layer_mods, modifier_layer in key_mapper.layer_modifiers {
		if active_modifiers == layer_mods {
			layer = modifier_layer
		}
	}

	return layer
}
