package iris

import "core:fmt"
import "core:math"
import "core:slice"
import rl "vendor:raylib"

Sketch_State :: struct {
	radius: f32,
	colour: rl.Color,
	angle:  f32,
}

make_scene_sketch :: proc(params: Params) -> Scene {
	scene: Scene
	scene.name = "SKETCH"

	state := new(Sketch_State)
	scene.data = state

	scene.draw = Draw_Scene_Proc(sketch_draw)
	scene.deinit = Deinit_Scene_Proc(sketch_deinit)

	return scene
}

sketch_draw :: proc(state: ^Sketch_State, p: Params, texture: rl.RenderTexture2D) {
	rl.BeginTextureMode(texture)
	defer rl.EndTextureMode()

	state.angle += 2 * p.dt
	state.angle = math.mod(state.angle, math.PI * 2)

	// rl.ClearBackground(rl.BLANK)

	t := state.angle
	// x := 400 * math.cos(t) / (1 + math.sin(t) * math.sin(t))
	// y := 400 * math.sin(t) * math.cos(t) / (1 + math.sin(t) * math.sin(t))
	x := 400 * math.cos(t)
	y := 400 * (math.sin(2 * t) / 2)
	rl.DrawCircle(i32(x) + p.center.x, i32(y) + p.center.y, 1, rl.YELLOW)
}

sketch_deinit :: proc(state: ^Sketch_State) {
	free(state)
}
