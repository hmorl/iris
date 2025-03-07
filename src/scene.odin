package iris

import "core:slice"
import "core:strings"
import rl "vendor:raylib"

Draw_Scene_Proc :: proc(state: rawptr, params: Params, texture: rl.RenderTexture2D)
Deinit_Scene_Proc :: proc(state: rawptr)

Scene :: struct {
	name:   string,
	data:   rawptr,
	draw:   Draw_Scene_Proc,
	deinit: Deinit_Scene_Proc,
}

Scene_Manager :: struct {
	active_scene: ^Scene,
	scenes:       [dynamic]Scene,
}

init_scenes :: proc(manager: ^Scene_Manager, params: Params) {
	append(&manager.scenes, make_scene_ink(params))
	append(&manager.scenes, make_scene_hello_world(params))
	append(&manager.scenes, make_scene_sketch(params))
	append(&manager.scenes, make_scene_spectrum(params))
}

deinit_scenes :: proc(manager: ^Scene_Manager) {
	for scene in manager.scenes {
		if (scene.deinit == nil) {
			assert(scene.data == nil, "No deinit proc for scene data")
		} else {
			scene.deinit(scene.data)
		}
	}
}

draw_scene :: proc(scene: ^Scene, params: Params, texture: rl.RenderTexture2D) {
	assert(scene.draw != nil)
	scene.draw(scene.data, params, texture)
}

Params :: struct {
	width, height:     i32,
	width_f, height_f: f32,
	center:            [2]i32,
	center_f:          [2]f32,
	mouse_pos:         rl.Vector2,
	mouse_pressed:     bool,
	mouse_down:        bool,
	dt:                f32,
	audio:             []f32,
	spectrum:          []f32,
	spectrum_smooth:   []f32,
	rms:               f32,
	rms_smooth:        f32,
	centroid:          f32,
	centroid_smooth:   f32,
}

@(private)
smooth :: proc(current: f32, new: f32, amount: f32) -> f32 {
	return new * amount + current * (1.0 - amount)
}

init_params :: proc(params: ^Params, initial_width, initial_height: i32, buffer_size: i32) {
	params.width, params.height = initial_width, initial_height
	params.width_f, params.height_f = f32(initial_width), f32(initial_height)
	params.audio = make([]f32, buffer_size)
	params.spectrum = make([]f32, buffer_size / 2)
	params.spectrum_smooth = make([]f32, buffer_size / 2)
}

update_params :: proc(
	params: ^Params,
	render_bounds: rl.Vector2,
	audio_buffer: []f32,
	rms: f32,
	spectrum: []f32,
	centroid: f32,
) {
	params.width, params.height = i32(render_bounds.x), i32(render_bounds.y)
	params.width_f, params.height_f = render_bounds.x, render_bounds.y
	params.center_f = {params.width_f / 2.0, params.height_f / 2.0}
	params.center = {params.width / 2, params.height / 2}

	{
		w := f32(render_bounds.x)
		h := f32(render_bounds.y)

		sw := f32(max(rl.GetScreenWidth(), 1))
		sh := f32(max(rl.GetScreenHeight(), 1))

		mouse_pos := rl.GetMousePosition()
		mouse_pos.x /= sw
		mouse_pos.y /= sh

		scale := min(sw / w, sh / h)
		mouse_pos.x *= sw / (scale * w)
		mouse_pos.y *= sh / (scale * h)
		mouse_pos.x *= w
		mouse_pos.y *= h

		params.mouse_pos = mouse_pos
	}

	params.mouse_pressed = rl.IsMouseButtonPressed(rl.MouseButton.LEFT)
	params.mouse_down = rl.IsMouseButtonDown(rl.MouseButton.LEFT)
	params.dt = rl.GetFrameTime()
	params.audio = audio_buffer

	params.rms = rms
	params.rms_smooth = smooth(params.rms_smooth, rms, 0.2)

	params.spectrum = spectrum
	for &s, idx in params.spectrum_smooth {
		s = smooth(s, spectrum[idx], 0.2)
	}

	params.centroid = centroid
	params.centroid_smooth = smooth(params.centroid_smooth, centroid, 0.2)
}
