package vis

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Timer :: struct {
	interval_ms:    f64,
	prev_tick_time: f64,
	is_running:     bool,
}

timer_init :: proc(timer: ^Timer, interval_ms: f64) {
	timer.interval_ms = interval_ms
	timer.is_running = false
}

timer_restart :: proc(timer: ^Timer) {
	timer.prev_tick_time = rl.GetTime()
	timer.is_running = true
}

timer_stop :: proc(timer: ^Timer) {
	timer.is_running = false
}

timer_running :: proc(timer: ^Timer) -> bool {
	return timer.is_running
}

timer_update :: proc(timer: ^Timer) -> bool {
	if (timer.is_running) {
		now := rl.GetTime()

		if (now - timer.prev_tick_time > timer.interval_ms / 1000) {
			timer.prev_tick_time = now
			return true
		}
	}

	return false
}

Scene_Ink_State :: struct {
	shader:          rl.Shader,
	current_texture: rl.RenderTexture2D,
	prev_texture:    rl.RenderTexture2D,
	current_colour:  rl.Vector4,
	drop_timer:      Timer,
}

scene_ink_init :: proc(state_data: rawptr, params: Params) {
	state := cast(^Scene_Ink_State)(state_data)

	state.shader = rl.LoadShader(nil, "vis/shaders/ink.frag")
	state.current_texture = rl.LoadRenderTexture(i32(params.width), i32(params.height))
	state.prev_texture = rl.LoadRenderTexture(i32(params.width), i32(params.height))

	timer_init(&state.drop_timer, 0)
}

resize_render_texture :: proc(texture: ^rl.RenderTexture2D, width: i32, height: i32) {
	temp := rl.LoadRenderTexture(width, height)

	{
		rl.BeginTextureMode(temp)
		defer rl.EndTextureMode()

		source := rl.Rectangle{0, 0, f32(texture.texture.width), f32(texture.texture.height)}
		rl.DrawTextureRec(texture.texture, source, {0, 0}, rl.WHITE)
	}

	rl.UnloadRenderTexture(texture^)
	texture^ = rl.LoadRenderTexture(width, height)

	{
		rl.BeginTextureMode(texture^)
		defer rl.EndTextureMode()

		rl.DrawTextureEx(temp.texture, {0, 0}, 0.0, 1.0, rl.WHITE)
	}
}

scene_ink_draw :: proc(state_data: rawptr, params: Params, texture: rl.RenderTexture2D) {
	st8 := cast(^Scene_Ink_State)(state_data)

	if (rl.IsWindowResized()) {
		resize_render_texture(&st8.current_texture, i32(params.width), i32(params.height))
		resize_render_texture(&st8.prev_texture, i32(params.width), i32(params.height))
	}

	if (!timer_running(&st8.drop_timer)) {
		timer_restart(&st8.drop_timer)
	}

	if (params.mouse_pressed) {
		r := f32(rl.GetRandomValue(0, 255))
		g := f32(rl.GetRandomValue(0, 255))
		b := f32(rl.GetRandomValue(0, 255))
		st8.current_colour = {(r / 255.0), g / 255.0, b / 255.0, 255}
	}

	{
		rl.BeginTextureMode(st8.current_texture)
		defer rl.EndTextureMode()

		rl.BeginShaderMode(st8.shader)
		defer rl.EndShaderMode()

		rl.SetShaderValueTexture(
			st8.shader,
			rl.GetShaderLocation(st8.shader, "u_prevTexture"),
			st8.prev_texture.texture,
		)

		v := i32(
			rl.IsMouseButtonDown(rl.MouseButton.LEFT) && timer_update(&st8.drop_timer) ? 1 : 0,
		)
		set_shader_uniform(st8.shader, "u_addDrop", v)

		set_shader_uniform(st8.shader, "u_dropPos", params.mouse_pos)

		set_shader_uniform(st8.shader, "u_dropCol", st8.current_colour)

		rl.DrawRectangle(
			0,
			0,
			i32(st8.current_texture.texture.width),
			i32(st8.current_texture.texture.height),
			rl.WHITE,
		)
	}

	{
		rl.BeginTextureMode(st8.prev_texture)
		defer rl.EndTextureMode()

		rl.ClearBackground(rl.BLACK)
		if (!rl.IsKeyPressed(rl.KeyboardKey.SPACE)) {

			rl.DrawTextureRec(
				st8.current_texture.texture,
				rl.Rectangle {
					0,
					0,
					f32(st8.current_texture.texture.width),
					-f32(st8.current_texture.texture.height),
				},
				{0, 0},
				rl.WHITE,
			)
		}
	}

	{
		rl.BeginTextureMode(texture)
		defer rl.EndTextureMode()

		rl.ClearBackground(rl.BLANK)

		rl.DrawTexturePro(
			st8.current_texture.texture,
			rl.Rectangle {
				0,
				0,
				f32(st8.current_texture.texture.width),
				f32(st8.current_texture.texture.height),
			},
			{0, 0, params.width_f, params.height_f},
			{0, 0},
			0.0,
			rl.WHITE,
		)
	}
}

scene_ink_deinit :: proc(state_data: rawptr) {
	state := cast(^Scene_Ink_State)(state_data)

	rl.UnloadShader(state.shader)
	rl.UnloadRenderTexture(state.current_texture)
	rl.UnloadRenderTexture(state.prev_texture)
}
