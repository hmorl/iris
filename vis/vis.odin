package vis

import rl "vendor:raylib"

Params :: struct {
	width, height:     i32,
	width_f, height_f: f32,
	mouse_pos:         rl.Vector2,
	mouse_pressed:     bool,
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
) {
	params.width, params.height = i32(render_bounds.x), i32(render_bounds.y)
	params.width_f, params.height_f = render_bounds.x, render_bounds.y

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
	params.dt = rl.GetFrameTime()
	params.audio = audio_buffer

	params.rms = rms
	params.rms_smooth = smooth(params.rms_smooth, rms, 0.2)

	params.spectrum = spectrum
	for &s, idx in params.spectrum_smooth {
		s = smooth(s, spectrum[idx], 0.2)
	}

}

Scene :: struct {
	draw: proc(data: rawptr, params: Params, texture: rl.RenderTexture2D),
	data: rawptr,
}

Scene_Manager :: struct {
	active_scene: ^Scene,
	scenes:       [dynamic]Scene,
}

add_scene :: proc(manager: ^Scene_Manager, scene: Scene) {
	append(&manager.scenes, scene)
}

scene_draw :: proc(scene: ^Scene, params: Params, texture: rl.RenderTexture2D) {
	scene.draw(scene.data, params, texture)
}

Shader_Uniform :: union {
	i32,
	f32,
	rl.Vector2,
	rl.Color,
	rl.Vector4,
}

set_shader_uniform :: proc(shader: rl.Shader, name: cstring, val: Shader_Uniform) {
	value := val
	data_type: rl.ShaderUniformDataType

	switch _ in val {
	case f32:
		data_type = rl.ShaderUniformDataType.FLOAT
	case rl.Vector2:
		data_type = rl.ShaderUniformDataType.VEC2
	case rl.Vector4:
		data_type = rl.ShaderUniformDataType.VEC4
	case i32:
		data_type = rl.ShaderUniformDataType.INT
	case rl.Color:
		data_type = rl.ShaderUniformDataType.IVEC4
	case:
	}

	rl.SetShaderValue(shader, rl.GetShaderLocation(shader, name), &value, data_type)
}
