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
import "core:time"
import rl "vendor:raylib"

WINDOW_WIDTH :: 720
WINDOW_HEIGHT :: 576

TARGET_FPS :: 60

Quit_Action :: enum {
	none,
	quit,
	request_reboot_composite_pal,
	request_reboot_composite_ntsc,
	request_reboot_hdmi,
}

Mode :: enum {
	Global_Scene,
	Global_Fx,
	Scene,
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
	is_first_frame:  bool,
}

main :: proc() {
	context.logger = log.create_console_logger(log.Level.Info, log.Options{.Level})


	rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE})
	rl.SetTargetFPS(TARGET_FPS)

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "⌒")
	defer rl.CloseWindow()

	rl.SetExitKey(rl.KeyboardKey.KEY_NULL)

	key_mapper: Key_Mapper
	key_mapper_initialize(&key_mapper)
	key_mapper_latch_layer(&key_mapper, .Global_Scene_Mode)

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

	scene_texture: rl.RenderTexture2D
	defer rl.UnloadRenderTexture(scene_texture)

	global_fx_shader := iris_load_shader("../shaders/multi_fx.frag")
	defer rl.UnloadShader(global_fx_shader)
	set_shader_uniform(global_fx_shader, "u_pixelateAmount", 8)

	state: State
	state.enable_cursor = true
	state.audio_level = 0.5
	is_first_frame := true

	for !(rl.WindowShouldClose() || state.should_exit) {
		defer state.is_first_frame = false

		if (rl.IsWindowResized() || is_first_frame) {
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

		if (state.quit_action == .none) {
			actions := key_mapper_update(&key_mapper)

			for a in actions {
				#partial switch a.type {
				case .app_shut_down:
					state.quit_action = .quit
				case .app_reboot_hdmi:
					state.quit_action = .request_reboot_hdmi
				case .app_reboot_composite_ntsc:
					state.quit_action = .request_reboot_composite_ntsc
				case .app_reboot_composite_pal:
					state.quit_action = .request_reboot_composite_pal
				case .app_toggle_fps:
					state.show_fps = !state.show_fps
				case .app_toggle_cursor:
					{
						state.enable_cursor = !state.enable_cursor
						if (state.enable_cursor) {
							rl.EnableCursor()
						} else {
							rl.DisableCursor()
						}
					}
				case .global_fx_mode_enter:
					key_mapper_latch_layer(&key_mapper, .Global_Fx_Mode)
				case .enter_scene_mode:
					key_mapper_latch_layer(&key_mapper, .Scene_Mode)
				case .global_scene_mode_enter:
					key_mapper_latch_layer(&key_mapper, .Global_Scene_Mode)
				case .fx_toggle_pixelate:
					state.enable_pixelate = !state.enable_pixelate
				case .fx_toggle_warp:
					state.enable_warp = !state.enable_warp
				case .fx_clear:
					state.enable_pixelate = false
					state.enable_warp = false
				case .audio_input_level:
					param := a.param.?
					level := map_val(f32(param.value), 0, f32(param.range - 1), 0.0, 1.0)
					state.audio_level = level
				case .global_scene_switch:
					param := a.param.?
					scene_num := param.value
					if (scene_num < len(scene_manager.scenes)) {
						scene_manager.active_scene = &scene_manager.scenes[scene_num]
					}
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
