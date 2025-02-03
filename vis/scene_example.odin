package vis

import "core:fmt"
import "core:math/rand"
import "core:slice"
import rl "vendor:raylib"

Example_State :: struct {
	radius: f32,
	colour: rl.Color,
}

make_scene_example :: proc(params: Params) -> Scene {
	scene: Scene
	scene.name = "Example"

	state := new(Example_State)
	state.colour = rand.choice([]rl.Color{rl.DARKBLUE, rl.YELLOW, rl.GREEN})
	state.radius = 64.0
	scene.data = state

	scene.draw = Draw_Scene_Proc(example_draw)
	scene.deinit = Deinit_Scene_Proc(example_deinit)

	return scene
}

example_draw :: proc(state: ^Example_State, params: Params, texture: rl.RenderTexture2D) {
	rl.BeginTextureMode(texture)
	defer rl.EndTextureMode()

	rl.ClearBackground(rl.BLANK)
	rl.DrawCircle(
		i32(params.centroid_smooth * params.width_f),
		params.height / 2,
		state.radius,
		state.colour,
	)
}

example_deinit :: proc(state: ^Example_State) {
	free(state)
}
