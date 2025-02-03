package vis

import "core:fmt"
import rl "vendor:raylib"

Scene_Hello_World_State :: struct {}

make_scene_hello_world :: proc(params: Params) -> Scene {
	scene: Scene

	scene.name = "helloo"
	state := new(Scene_Hello_World_State)
	scene.data = state
	scene.draw = Draw_Scene_Proc(scene_hello_world_draw)
	scene.deinit = Deinit_Scene_Proc(scene_hello_world_deinit)

	return scene
}

scene_hello_world_draw :: proc(
	state_data: ^Scene_Hello_World_State,
	params: Params,
	texture: rl.RenderTexture2D,
) {
	rl.BeginTextureMode(texture)
	defer rl.EndTextureMode()

	rl.ClearBackground(rl.BLANK)

	N := len(params.audio)

	for s, idx in params.audio {
		x := f32(idx) / f32(N) * params.width_f

		rl.DrawRectangleV({x, 0}, {1, s * 300}, rl.BLUE)

		s2 := params.audio[N - 1 - idx]
		rl.DrawRectangle(i32(x), i32(params.height_f - s2 * 300), 1, i32(s2 * 300), rl.BLUE)
	}

	rl.DrawCircle(
		params.width / 2,
		params.height / 2,
		params.rms_smooth * params.rms_smooth * 2000,
		rl.GREEN,
	)

	amt := i32(rl.Clamp(params.rms * 1000, 0, 300))

	for i in 0 ..< amt {
		rl.DrawRectangle(
			rl.GetRandomValue(0, i32(params.width)),
			rl.GetRandomValue(0, i32(params.height)),
			4,
			4,
			rl.Color{255, 30, 30, 255},
		)
	}
}

scene_hello_world_deinit :: proc(scene_data: ^Scene_Hello_World_State) {

}
