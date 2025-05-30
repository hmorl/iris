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

Scene_Ambrosia_State :: struct {
	shader:         rl.Shader,
	prev_texture:   rl.RenderTexture2D,
	current_colour: rl.Vector4,
	col_timer:      Timer,
	angle:          f32,
	glitch_amt:     rl.Vector2,
	pos:            rl.Vector2,
	lfo_start_time: time.Time,
	drop_size:      f32,
}

make_scene_ambrosia :: proc(params: Params) -> Scene {
	scene: Scene
	scene.name = "INK"

	state := new(Scene_Ambrosia_State)
	state.shader = iris_load_shader("../shaders/ink.frag")
	state.prev_texture = rl.LoadRenderTexture(params.width, params.height)

	rl.SetTextureFilter(state.prev_texture.texture, rl.TextureFilter.BILINEAR)

	state.angle = math.PI / 2
	c := rand_col_f()
	state.current_colour = {c.r, c.g, c.b, 1.0}

	timer_init(&state.col_timer, time.Millisecond * 694)
	timer_start(&state.col_timer)

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
		resize_render_texture(&st8.prev_texture, params.width, params.height)
	}

	set_shader_uniform(st8.shader, "u_resolution", rl.Vector2{params.width_f, params.height_f})
	set_shader_uniform(st8.shader, "u_addDrop", true)

	if (params.mouse_down) {
		st8.glitch_amt += params.mouse_delta / 1000
		st8.glitch_amt = rl.Vector2Clamp(st8.glitch_amt, {-1, -1}, {1, 1})

		st8.pos = params.mouse_pos
	} else {
		lfo_1 := lfo(0.28, Lfo_Shape.rand, rand_id = 123)
		lfo_2 := lfo(0.3, Lfo_Shape.rand, rand_id = 42)
		glitch_x := map_val(lfo_1, 0, 1, -0.07, 0.05)
		glitch_y := map_val(lfo_2, 0, 1, -0.07, 0.05)
		st8.glitch_amt = {f32(glitch_x), f32(glitch_y)}

		st8.angle += params.centroid_smooth * 3 * params.dt
		st8.pos = 300 * lissajous(st8.angle) + params.center_f
	}

	set_shader_uniform(st8.shader, "u_glitchXY", st8.glitch_amt)
	set_shader_uniform(st8.shader, "u_dropPos", st8.pos)

	if lfo(0.03, Lfo_Shape.saw_up) > 0.95 {
		set_shader_uniform(st8.shader, "u_sharpen", 0.7)
	} else {
		set_shader_uniform(st8.shader, "u_sharpen", 0.0)
	}

	drop_size := smooth_val(
		st8.drop_size,
		map_val(math.pow(params.rms_smooth, 1.2), 0, 0.1, 5, params.width_f / 16.0),
		0,
	)
	set_shader_uniform(st8.shader, "u_dropRadius", drop_size)

	if (timer_update(&st8.col_timer)) {
		lfo := lfo(0.03, Lfo_Shape.saw_up, 0.4, st8.lfo_start_time)
		next_col := next_col(f32(lfo))
		c := rl.ColorNormalize(next_col)
		st8.current_colour = {c.r, c.g, c.b, c.a}
		set_shader_uniform(st8.shader, "u_dropCol", st8.current_colour)
	}

	{
		rl.BeginTextureMode(texture)
		defer rl.EndTextureMode()

		rl.BeginShaderMode(st8.shader)
		defer rl.EndShaderMode()

		rl.SetShaderValueTexture(
			st8.shader,
			rl.GetShaderLocation(st8.shader, "u_prevTexture"),
			st8.prev_texture.texture,
		)

		rl.DrawRectangle(0, 0, texture.texture.width, texture.texture.height, rl.WHITE)
	}

	{
		rl.BeginTextureMode(st8.prev_texture)
		defer rl.EndTextureMode()

		rl.ClearBackground(rl.BLACK)
		if (!rl.IsKeyPressed(rl.KeyboardKey.SPACE)) {
			rl.DrawTextureRec(
				texture.texture,
				rl.Rectangle{0, 0, f32(texture.texture.width), f32(texture.texture.height)},
				{0, 0},
				rl.WHITE,
			)
		}
	}
}

scene_ambrosia_deinit :: proc(state: ^Scene_Ambrosia_State) {
	rl.UnloadShader(state.shader)
	rl.UnloadRenderTexture(state.prev_texture)
	free(state)
}
