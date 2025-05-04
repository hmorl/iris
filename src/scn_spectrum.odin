package iris

import "core:fmt"
import rl "vendor:raylib"

make_scene_spectrum :: proc(params: Params) -> Scene {
	scene: Scene
	scene.name = "SPECTRUM"
	scene.draw = Draw_Scene_Proc(spectrum_draw)

	return scene
}

spectrum_draw :: proc(data: rawptr, params: Params, texture: rl.RenderTexture2D) {
	rl.BeginTextureMode(texture)
	rl.ClearBackground(rl.BLANK)
	// rl.DrawCircle(params.width / 2, params.height / 2, 30.0, rl.BLUE)
	width := params.width / 128

	for p, idx in params.spectrum_smooth {
		p2 := i32(p * 100)
		rl.DrawRectangle(i32(idx) * i32(width), rl.GetScreenHeight() - p2, width, p2, rl.BLUE)
	}
	rl.EndTextureMode()
}
