package vis

import "core:fmt"
import rl "vendor:raylib"

Scene_Spectrum :: struct {}

scene_spectrum_init :: proc(state_data: rawptr, params: Params) {
}

scene_spectrum_draw :: proc(state_data: rawptr, params: Params, texture: rl.RenderTexture2D) {
	rl.BeginTextureMode(texture)
	rl.ClearBackground(rl.BLANK)
	// rl.DrawCircle(params.width / 2, params.height / 2, 30.0, rl.BLUE)
	width := rl.GetScreenWidth() / 128

	for p, idx in params.spectrum_smooth {
		p2 := i32(p * 100)
		rl.DrawRectangle(i32(idx) * i32(width), rl.GetScreenHeight() - p2, width, p2, rl.BLUE)
	}
	rl.EndTextureMode()
}

scene_spectrum_deinit :: proc(scene_data: rawptr) {

}
