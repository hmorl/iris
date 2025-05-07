package iris

// ┌─┐ ┌┬┐ ┌┐  ┬─┐ ┌─┐ ┌─┐ ┬ ┌─┐ 
// ├─┤ │││ ├┴┐ ├┬┘ │ │ └─┐ │ ├─┤ 
// ┴ ┴ ┴ ┴ └─┘ ┴└─ └─┘ └─┘ ┴ ┴ ┴ 

import "core:fmt"
import "core:math"
import "core:math/noise"
import "core:math/rand"
import "core:time"
import rl "vendor:raylib"

INK_SCALE :: 1

Scene_Ambrosia_State :: struct {
	shader:          rl.Shader,
	current_texture: rl.RenderTexture2D,
	prev_texture:    rl.RenderTexture2D,
	current_colour:  rl.Vector4,
	drop_timer:      Timer,
	col_timer:       Timer,
	angle:           f32,
	glitch_amt:      rl.Vector2,
	toggle_drop:     bool,
	lfo_start_time:  time.Time,
}

make_scene_ambrosia :: proc(params: Params) -> Scene {
	scene: Scene
	scene.name = "INK"

	state := new(Scene_Ambrosia_State)
	state.shader = iris_load_shader("../shaders/ink.frag")
	state.current_texture = rl.LoadRenderTexture(
		params.width * INK_SCALE,
		params.height * INK_SCALE,
	)
	state.prev_texture = rl.LoadRenderTexture(params.width * INK_SCALE, params.height * INK_SCALE)

	state.toggle_drop = true

	rl.SetTextureFilter(state.prev_texture.texture, rl.TextureFilter.BILINEAR)

	state.angle = math.PI / 2
	c := rand_col_f()
	state.current_colour = {c.r, c.g, c.b, 1.0}

	timer_init(&state.drop_timer, time.Millisecond * 30)
	timer_init(&state.col_timer, time.Millisecond * 694)

	scene.data = state
	scene.draw = Draw_Scene_Proc(scene_ambrosia_draw)
	scene.deinit = Deinit_Scene_Proc(scene_ambrosia_deinit)

	return scene
}

next_col :: proc(theta: f32) -> rl.Color {
	hue: f32 = math.mod(rand.float32() * 120.0 + theta * 360.0, 360.0)
	sat: f32 = 1.0
	bri: f32 = 1.0

	return rl.ColorFromHSV(hue, sat, bri)
}

scene_ambrosia_draw :: proc(
	st8: ^Scene_Ambrosia_State,
	params: Params,
	texture: rl.RenderTexture2D,
) {
	if (rl.IsWindowResized()) {
		resize_render_texture(
			&st8.current_texture,
			params.width * INK_SCALE,
			params.height * INK_SCALE,
		)
		resize_render_texture(
			&st8.prev_texture,
			params.width * INK_SCALE,
			params.height * INK_SCALE,
		)
	}

	if (!timer_running(&st8.drop_timer)) {
		timer_start(&st8.drop_timer)
	}

	set_shader_uniform(st8.shader, "u_resolution", rl.Vector2{params.width_f, params.height_f})

	if (!timer_running(&st8.col_timer)) {
		timer_start(&st8.col_timer)
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

		set_shader_uniform(st8.shader, "u_addDrop", i32(st8.toggle_drop))

		// if (st8.toggle_drop) {
		// 	st8.glitch_amt += params.mouse_delta / 1000
		// 	st8.glitch_amt = rl.Vector2Clamp(st8.glitch_amt, {-1, -1}, {1, 1})
		// }

		lfo_1 := lfo(0.28, Lfo_Shape.rand, rand_id = 123)
		lfo_2 := lfo(0.3, Lfo_Shape.rand, rand_id = 42)
		glitch_x := map_val(lfo_1, 0, 1, -0.07, 0.05)
		glitch_y := map_val(lfo_2, 0, 1, -0.07, 0.05)
		st8.glitch_amt = {f32(glitch_x), f32(glitch_y)}
		set_shader_uniform(st8.shader, "u_glitchXY", st8.glitch_amt)

		drop_size := map_val(math.pow(params.rms_smooth, 2), 0, 0.02, 0, params.width_f / 16.0)
		set_shader_uniform(st8.shader, "u_dropRadius", drop_size)

		st8.angle += params.centroid_smooth * 3 * params.dt
		pos := 300 * lissajous(st8.angle) + params.center_f
		set_shader_uniform(st8.shader, "u_dropPos", pos)

		if (timer_update(&st8.col_timer)) {
			lfo := lfo(0.03, Lfo_Shape.saw_up, 0.4, st8.lfo_start_time)
			next_col := next_col(f32(lfo))
			c := rl.ColorNormalize(next_col)
			st8.current_colour = {c.r, c.g, c.b, c.a}
			set_shader_uniform(st8.shader, "u_dropCol", st8.current_colour)
		}

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

scene_ambrosia_deinit :: proc(state: ^Scene_Ambrosia_State) {
	rl.UnloadShader(state.shader)
	rl.UnloadRenderTexture(state.current_texture)
	rl.UnloadRenderTexture(state.prev_texture)
	free(state)
}
