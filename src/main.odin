package iris

//       ⌒      
//  ┬ ┬─┐ ┬ ┌─┐ 
//  │ ├┬┘ │ └─┐ 
//  ┴ ┴└─ ┴ └─┘ 

import "core:c/libc"
import "core:fmt"
import "core:log"
import "core:math"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

import rl "vendor:raylib"

PLATFORM_RASPBERRY_PI :: #config(PLATFORM_RASPBERRY_PI, false)

WINDOW_WIDTH :: 720
WINDOW_HEIGHT :: 576

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
	key_mapper.mappings[{rl.KeyboardKey.ESCAPE, {}}] = "enter_global_mode"

	key_mapper.mappings[{rl.KeyboardKey.Q, {}}] = switch_scene + "1"
	key_mapper.mappings[{rl.KeyboardKey.W, {}}] = switch_scene + "2"
	key_mapper.mappings[{rl.KeyboardKey.E, {}}] = switch_scene + "3"
	key_mapper.mappings[{rl.KeyboardKey.R, {}}] = switch_scene + "4"
	key_mapper.mappings[{rl.KeyboardKey.T, {}}] = switch_scene + "5"
	key_mapper.mappings[{rl.KeyboardKey.Y, {}}] = switch_scene + "6"

	key_mapper.mappings[{rl.KeyboardKey.ONE, {.Ctrl}}] = set_input + "0%"
	key_mapper.mappings[{rl.KeyboardKey.TWO, {.Ctrl}}] = set_input + "25%"
	key_mapper.mappings[{rl.KeyboardKey.THREE, {.Ctrl}}] = set_input + "50%"
	key_mapper.mappings[{rl.KeyboardKey.FOUR, {.Ctrl}}] = set_input + "75%"
	key_mapper.mappings[{rl.KeyboardKey.FIVE, {.Ctrl}}] = set_input + "100%"

	key_mapper.mappings[{rl.KeyboardKey.W, {.Shift}}] = "toggle_warp"
	key_mapper.mappings[{rl.KeyboardKey.P, {.Shift}}] = "toggle_pixelate"
	key_mapper.mappings[{rl.KeyboardKey.ESCAPE, {.Shift}}] = "clear_fx"

	key_mapper.mappings[{rl.KeyboardKey.SLASH, {.Shift}}] = "toggle_fps"
	key_mapper.mappings[{rl.KeyboardKey.C, {.Ctrl, .Alt, .Shift}}] = "toggle_cursor"

	key_mapper.mappings[{rl.KeyboardKey.Q, {.Ctrl, .Alt, .Shift}}] = "shut_down"
	key_mapper.mappings[{rl.KeyboardKey.P, {.Ctrl, .Alt, .Shift}}] = "reboot_composite_pal"
	key_mapper.mappings[{rl.KeyboardKey.N, {.Ctrl, .Alt, .Shift}}] = "reboot_composite_ntsc"
	key_mapper.mappings[{rl.KeyboardKey.H, {.Ctrl, .Alt, .Shift}}] = "reboot_composite_hdmi"

	key_mapper.mappings[{rl.KeyboardKey.ENTER, {}}] = "enter_scene_mode"
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

Quit_Action :: enum {
	none,
	quit,
	request_reboot_composite_pal,
	request_reboot_composite_ntsc,
	request_reboot_hdmi,
}

State :: struct {
	audio_level:     f32,
	show_fps:        bool,
	enable_warp:     bool,
	enable_pixelate: bool,
	enable_cursor:   bool,
	should_exit:     bool,
	quit_action:     Quit_Action,
	should_quit:     bool,
}

main :: proc() {
	context.logger = log.create_console_logger(log.Level.Info, log.Options{.Level})

	key_mapper: Key_Mapper
	initialize_mappings(&key_mapper)

	rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE})
	rl.SetTargetFPS(TARGET_FPS)

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "⌒")
	defer rl.CloseWindow()

	rl.SetExitKey(rl.KeyboardKey.KEY_NULL)

	audio_ctx: Audio_Context

	device_name_filter := ""
	if (len(os.args) > 1) {
		device_name_filter = strings.trim_prefix(os.args[1], "--device-filter=")
	}

	if (init_audio(&audio_ctx, device_name_filter) != true) {
		log.fatal("Failed to initialise audio engine")
		os.exit(1)
	}
	defer deinit_audio(&audio_ctx)

	vis_params: Params
	init_params(&vis_params, rl.GetScreenWidth(), rl.GetScreenHeight(), BUFFER_SIZE)

	scene_manager: Scene_Manager
	init_scenes(&scene_manager, vis_params)
	defer deinit_scenes(&scene_manager)

	scene_manager.active_scene = &scene_manager.scenes[0]

	scene_texture: rl.RenderTexture2D
	defer rl.UnloadRenderTexture(scene_texture)

	global_fx_shader := iris_load_shader("../shaders/multi_fx.frag")
	defer rl.UnloadShader(global_fx_shader)
	set_shader_uniform(global_fx_shader, "u_pixelateAmount", 8)

	first_frame := true

	state: State
	state.enable_cursor = true
	state.audio_level = 0.5

	for !(rl.WindowShouldClose() || state.should_exit) {
		defer first_frame = false

		if (rl.IsWindowResized() || first_frame) {
			rl.UnloadRenderTexture(scene_texture)
			scene_texture = rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())
		}

		buffer := audio_ctx.data.buffers[audio_ctx.data.read_buffer] * f32(state.audio_level)

		spectrum := calc_spectrum(buffer[:], context.temp_allocator)
		spectrum_a_weighted := calc_a_weighted_spectrum(spectrum, context.temp_allocator)

		update_params(
			&vis_params,
			{f32(scene_texture.texture.width), f32(scene_texture.texture.height)},
			buffer[:],
			calc_rms(buffer[:]),
			spectrum_a_weighted,
			calc_centroid(spectrum_a_weighted),
		)

		set_shader_uniform(
			global_fx_shader,
			"u_resolution",
			rl.Vector2{vis_params.width_f, vis_params.height_f},
		)

		if state.quit_action != .none && rl.IsKeyPressed(rl.KeyboardKey.Y) {
			state.should_exit = true
		} else if state.quit_action != .none && rl.IsKeyPressed(rl.KeyboardKey.N) ||
		   rl.IsKeyPressed(rl.KeyboardKey.ESCAPE) {
			state.quit_action = .none
		}

		if state.quit_action == .none {
			actions := get_triggered_actions(&key_mapper)

			for a in actions {
				if (strings.has_prefix(a, set_input)) {
					switch strings.trim_prefix(a, set_input) {
					case "0%":
						state.audio_level = 0
					case "25%":
						state.audio_level = 0.25
					case "50%":
						state.audio_level = 0.5
					case "75%":
						state.audio_level = 0.75
					case "100%":
						state.audio_level = 1.0
					}
				} else if (strings.has_prefix(a, switch_scene)) {
					param := strings.trim_prefix(a, switch_scene)
					scene_num, ok := strconv.parse_int(param)
					assert(ok)

					if (scene_num <= len(scene_manager.scenes)) {
						scene_manager.active_scene = &scene_manager.scenes[scene_num - 1]
					}
				} else if (a == "toggle_fps") {
					state.show_fps = !state.show_fps
				} else if (a == "toggle_warp") {
					state.enable_warp = !state.enable_warp
				} else if (a == "toggle_pixelate") {
					state.enable_pixelate = !state.enable_pixelate
				} else if (a == "clear_fx") {
					state.enable_warp = false
					state.enable_pixelate = false
				} else if (a == "toggle_cursor") {
					state.enable_cursor = !state.enable_cursor
					if (state.enable_cursor) {
						rl.EnableCursor()
					} else {
						rl.DisableCursor()
					}
				} else if a == "shut_down" {
					state.quit_action = .quit
				} else if a == "reboot_composite_pal" {
					state.quit_action = .request_reboot_composite_pal
				} else if a == "reboot_composite_ntsc" {
					state.quit_action = .request_reboot_composite_ntsc
				} else if a == "reboot_composite_hdmi" {
					state.quit_action = .request_reboot_hdmi
				}
			}
		}

		draw_scene(scene_manager.active_scene, vis_params, scene_texture)

		{
			rl.BeginDrawing()
			defer rl.EndDrawing()

			{
				set_shader_uniform(
					global_fx_shader,
					"u_enablePixelate",
					state.enable_pixelate ? 1 : 0,
				)

				set_shader_uniform(global_fx_shader, "u_enableWarp", state.enable_warp ? 1 : 0)

				warp_pos: rl.Vector2 = {
					f32(lfo(0.2, .rand, 0.0, {}, 123, 0.7)),
					f32(lfo(0.15, .rand, 0.0, {}, 97, 0.7)),
				}

				set_shader_uniform(global_fx_shader, "u_warpPos", warp_pos)

				rl.BeginShaderMode(global_fx_shader)
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

			if (state.show_fps) {
				draw_label(rl.TextFormat("%d FPS", rl.GetFPS()), {32, 32})
			}

			#partial switch state.quit_action {
			case .quit:
				draw_label("shut down IRIS? [y / n]", vis_params.center_f, .Center)
			case .request_reboot_composite_pal:
				draw_label("reboot IRIS - Composite (PAL)? [y / n]", vis_params.center_f, .Center)
			case .request_reboot_composite_ntsc:
				draw_label("reboot IRIS - Composite (NTSC)? [y / n]", vis_params.center_f, .Center)
			case .request_reboot_hdmi:
				draw_label("reboot - HDMI? [y / n]", vis_params.center_f, .Center)
			}
		}

		free_all(context.temp_allocator)
	}

	exit_code := 0

	#partial switch state.quit_action {
	case .request_reboot_composite_pal:
		exit_code = 21
	case .request_reboot_composite_ntsc:
		exit_code = 22
	case .request_reboot_hdmi:
		exit_code = 23
	}

	defer os.exit(exit_code)
}


Text_Justification :: enum {
	Left,
	Center,
}

draw_label :: proc(text: cstring, pos: rl.Vector2, justify: Text_Justification = .Left) {
	padding :: 8
	size :: 24

	w := rl.MeasureText(text, size)

	half_w: i32 = w / 2
	half_h :: size / 2

	x := i32(pos.x)
	y := i32(pos.y)

	switch justify {
	case .Left:
		rl.DrawRectangle(x - padding, y - padding, w + padding * 2, size + padding * 2, rl.BLACK)
		rl.DrawText(text, x, y, size, rl.WHITE)
	case .Center:
		rl.DrawRectangle(
			x - half_w - padding,
			y - half_h - padding,
			w + padding * 2,
			size + padding * 2,
			rl.BLACK,
		)
		rl.DrawText(text, x - half_w, y - half_h, size, rl.WHITE)
	}
}
