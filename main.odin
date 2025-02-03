// ▗▖  ▗▖▗▄▄▄▖ ▗▄▄▖▗▄▄▄▖▗▄▄▄▖ ▗▄▄▖▗▖ ▗▖
// ▐▌  ▐▌  █  ▐▌     █  ▐▌   ▐▌   ▐▌ ▐▌   
// ▐▌  ▐▌  █   ▝▀▚▖  █  ▐▛▀▀▘▐▌   ▐▛▀▜▌
//  ▝▚▞▘ ▗▄█▄▖▗▄▄▞▘  █  ▐▙▄▄▖▝▚▄▄▖▐▌ ▐▌
//
// == audio visualization technique ==

package main

import "core:fmt"
import "core:math"
import "core:slice"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"

import "audio"
import "vis"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

TARGET_FPS :: 60

Modifier :: enum u8 {
	Shift,
	Ctrl,
	Alt,
	Super,
}

Modifiers :: distinct bit_set[Modifier]

Key_Combo :: struct {
	key:       rl.KeyboardKey,
	modifiers: Modifiers,
}

Key_Mapper :: struct {
	mappings: map[Key_Combo]string,
}

switch_scene :: "switch_scene_"
set_input :: "set_input_"

initialize_mappings :: proc(key_mapper: ^Key_Mapper) {
	key_mapper.mappings[{rl.KeyboardKey.Q, {}}] = switch_scene + "1"
	key_mapper.mappings[{rl.KeyboardKey.W, {}}] = switch_scene + "2"
	key_mapper.mappings[{rl.KeyboardKey.E, {}}] = switch_scene + "3"
	key_mapper.mappings[{rl.KeyboardKey.R, {}}] = "switch_scene_4"
	key_mapper.mappings[{rl.KeyboardKey.T, {}}] = "switch_scene_5"
	key_mapper.mappings[{rl.KeyboardKey.Y, {}}] = "switch_scene_6"

	key_mapper.mappings[{rl.KeyboardKey.ONE, {.Ctrl}}] = "set_input_low"
	key_mapper.mappings[{rl.KeyboardKey.TWO, {.Ctrl}}] = "set_input_mid"
	key_mapper.mappings[{rl.KeyboardKey.THREE, {.Ctrl}}] = "set_input_high"
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

get_triggered_actions :: proc(key_mapper: ^Key_Mapper) -> []string {
	if (rl.GetKeyPressed() == rl.KeyboardKey.KEY_NULL) {
		return {}
	}

	active_modifiers := get_active_modifiers()

	actions: [dynamic]string

	for key_combo, action_name in key_mapper.mappings {
		if (rl.IsKeyPressed(key_combo.key) && active_modifiers == key_combo.modifiers) {
			append(&actions, action_name)
		}
	}

	return actions[:]
}


State :: struct {
	audio_level: f32,
}

main :: proc() {
	key_mapper: Key_Mapper
	initialize_mappings(&key_mapper)

	rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT, .WINDOW_RESIZABLE, .WINDOW_HIGHDPI})

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "visualization engine")
	defer rl.CloseWindow()

	rl.SetTargetFPS(TARGET_FPS)

	audio_ctx: audio.Audio_Context
	audio.init_audio(&audio_ctx)
	defer audio.deinit_audio(&audio_ctx)

	vis_params: vis.Params
	vis.init_params(&vis_params, rl.GetScreenWidth(), rl.GetScreenHeight(), audio.BUFFER_SIZE)

	scene_manager: vis.Scene_Manager
	vis.init_scenes(&scene_manager, vis_params)
	defer vis.deinit_scenes(&scene_manager)

	scene_manager.active_scene = &scene_manager.scenes[0]

	scene_texture: rl.RenderTexture2D
	defer rl.UnloadRenderTexture(scene_texture)

	pixelate_shader := rl.LoadShader(nil, "vis/shaders/pixelate.frag")
	defer rl.UnloadShader(pixelate_shader)
	vis.set_shader_uniform(pixelate_shader, "u_amount", 2)

	first_frame := true

	state: State
	state.audio_level = 1.0

	for !rl.WindowShouldClose() {
		rl.SetWindowTitle(rl.TextFormat("VISTECH (%d fps)", rl.GetFPS()))

		if (rl.IsWindowResized() || first_frame) {
			rl.UnloadRenderTexture(scene_texture)
			scene_texture = rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())
		}

		buffer := audio_ctx.data.buffers[audio_ctx.data.read_buffer] * f32(state.audio_level)

		spectrum := audio.calc_spectrum(buffer[:], context.temp_allocator)
		spectrum_a_weighted := audio.calc_a_weighted_spectrum(spectrum, context.temp_allocator)

		vis.update_params(
			&vis_params,
			{f32(scene_texture.texture.width), f32(scene_texture.texture.height)},
			buffer[:],
			audio.calc_rms(buffer[:]),
			spectrum_a_weighted,
			audio.calc_centroid(spectrum_a_weighted),
		)

		vis.set_shader_uniform(
			pixelate_shader,
			"u_resolution",
			rl.Vector2{vis_params.width_f, vis_params.height_f},
		)

		actions := get_triggered_actions(&key_mapper)

		for a in actions {
			if (strings.has_prefix(a, set_input)) {
				switch strings.trim_prefix(a, set_input) {
				case "low":
					state.audio_level = 0.2
				case "mid":
					state.audio_level = 0.6
				case "high":
					state.audio_level = 1.0
				}
			} else if (strings.has_prefix(a, switch_scene)) {
				param := strings.trim_prefix(a, switch_scene)
				scene_num, ok := strconv.parse_int(param)
				assert(ok)

				if (scene_num <= len(scene_manager.scenes)) {
					scene_manager.active_scene = &scene_manager.scenes[scene_num - 1]
				}
			}
		}

		vis.draw_scene(scene_manager.active_scene, vis_params, scene_texture)

		{
			rl.BeginDrawing()
			defer rl.EndDrawing()

			{
				rl.BeginShaderMode(pixelate_shader)
				defer rl.EndShaderMode()

				rl.ClearBackground(rl.BLACK)

				rl.DrawTexturePro(
					texture = scene_texture.texture,
					source = {
						width = f32(scene_texture.texture.width),
						height = f32(-scene_texture.texture.height),
					},
					dest = {0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())},
					origin = {0, 0},
					rotation = 0,
					tint = rl.WHITE,
				)
			}

			first_frame = false
		}

		free_all(context.temp_allocator)
	}
}
