package iris

// ┌┐┌ ┌─┐ ┌─┐ ┬┌─ ┬   ┌─┐ ┌─┐ ┌─┐   ┌─┐ ┌─┐   ┬ ┬ ┌─┐ ┬─┐ ┌┬┐ ┌─┐ ┌┐┌ ┬ ┌─┐
// │││ ├┤  │   ├┴┐ │   ├─┤ │   ├┤    │ │ ├┤    ├─┤ ├─┤ ├┬┘ │││ │ │ │││ │ ├─┤
// ┘└┘ └─┘ └─┘ ┴ ┴ ┴─┘ ┴ ┴ └─┘ └─┘   └─┘ └     ┴ ┴ ┴ ┴ ┴└─ ┴ ┴ └─┘ ┘└┘ ┴ ┴ ┴

import "core:fmt"
import "core:time"
import rl "vendor:raylib"

Scene_Harmonia_State :: struct {
}

make_scene_harmonia :: proc(params: Params) -> Scene {
	scene: Scene

	scene.name = "helloo"
	state := new(Scene_Harmonia_State)
	scene.data = state
	scene.draw = Draw_Scene_Proc(scene_harmonia_draw)
	scene.deinit = Deinit_Scene_Proc(scene_harmonia_deinit)

	return scene
}

scene_harmonia_draw :: proc(
	state_data: ^Scene_Harmonia_State,
	params: Params,
	texture: rl.RenderTexture2D,
) {
	lfo1 := lfo(0.16, .sin, 0.0)
	lfo2 := lfo(0.1, .tri, 0.5, params.mouse_down ? time.now() : {})

	rl.BeginTextureMode(texture)
	defer rl.EndTextureMode()

	rl.ClearBackground({58, 0, 5, u8(lfo2 * 200.0)})
	N := len(params.audio)

	for s, idx in params.audio {
		x := f32(idx) / f32(N) * params.width_f

		rl.DrawRectangleV({x, 0}, {1, s * 300}, rl.BLUE)

		s2 := params.audio[N - 1 - idx]
		rl.DrawRectangle(i32(x), i32(params.height_f - s2 * 300), 1, i32(s2 * 300), rl.BLUE)
	}

	sides := 2 + i32(params.rms_smooth * 15)

	for i in 0 ..< 5 {
		rl.DrawPolyLines(
			{params.width_f / 2, params.height_f / 2},
			sides,
			params.rms_smooth * params.width_f * f32(i) * 0.8,
			params.centroid * 360 + f32(i) * 10,
			rl.GREEN,
		)
	}

	amt := i32(rl.Clamp(params.centroid * 1000, 0, 200))

	for i in 0 ..< amt {
		rl.DrawRectangle(
			rl.GetRandomValue(0, i32(params.width)),
			rl.GetRandomValue(0, i32(params.height)),
			7,
			2,
			rl.Color{255, 30, 30, u8(lfo1 * 255.0)},
		)
	}
}

scene_harmonia_deinit :: proc(scene_data: ^Scene_Harmonia_State) {

}
