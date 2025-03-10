package iris

import "core:fmt"
import "core:math"
import "core:math/noise"
import "core:math/rand"
import "core:time"
import rl "vendor:raylib"

INK_SCALE :: 3

Scene_Ink_State :: struct {
	shader:          rl.Shader,
	current_texture: rl.RenderTexture2D,
	prev_texture:    rl.RenderTexture2D,
	current_colour:  rl.Vector4,
	drop_timer:      Timer,
	angle:           f32,
}

make_scene_ink :: proc(params: Params) -> Scene {
	scene: Scene
	scene.name = "INK"

	state := new(Scene_Ink_State)
	state.shader = iris_load_shader("../shaders/ink.frag")
	state.current_texture = rl.LoadRenderTexture(
		params.width * INK_SCALE,
		params.height * INK_SCALE,
	)
	state.prev_texture = rl.LoadRenderTexture(params.width * INK_SCALE, params.height * INK_SCALE)

	state.angle = math.PI / 2
	c := rand_col_f()
	state.current_colour = {c.r, c.g, c.b, 1.0}

	timer_init(&state.drop_timer, time.Millisecond * 30)

	scene.data = state
	scene.draw = Draw_Scene_Proc(scene_ink_draw)
	scene.deinit = Deinit_Scene_Proc(scene_ink_deinit)

	return scene
}

scene_ink_draw :: proc(st8: ^Scene_Ink_State, params: Params, texture: rl.RenderTexture2D) {
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

	if (params.mouse_pressed) {
		c := rand_col_f()
		st8.current_colour = {c.r, c.g, c.b, 1.0}
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

		v := i32(timer_update(&st8.drop_timer) ? 1 : 0)

		set_shader_uniform(st8.shader, "u_addDrop", v)

		old_angle := st8.angle
		st8.angle += 1 * params.dt
		st8.angle = math.mod(st8.angle, math.PI * 2)

		set_shader_uniform(st8.shader, "u_dropRadius", params.centroid_smooth * 150.0 * INK_SCALE)

		if (params.mouse_down) {
			set_shader_uniform(st8.shader, "u_dropPos", params.mouse_pos * INK_SCALE)
		} else {
			pos := 400 * lemniscate_gerono(st8.angle) + params.center_f

			NOISE_Y :: 9.0
			t := rl.GetTime() * 0.5

			nois := rl.Vector2{noise.noise_2d(123, {t, NOISE_Y}), noise.noise_2d(2, {t, NOISE_Y})}
			pos = pos * INK_SCALE + (nois * 1000 * params.rms_smooth * 8)

			set_shader_uniform(st8.shader, "u_dropPos", pos)
		}


		offset: f32 = math.PI / 2
		if (st8.angle < old_angle) {
			c := rand_col_f()
			st8.current_colour = {c.r, c.g, c.b, 1.0}
		}
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

scene_ink_deinit :: proc(state: ^Scene_Ink_State) {
	rl.UnloadShader(state.shader)
	rl.UnloadRenderTexture(state.current_texture)
	rl.UnloadRenderTexture(state.prev_texture)
	free(state)
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
