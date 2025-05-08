package iris

import "base:intrinsics"
import "core:fmt"
import "core:math"
import "core:math/ease"
import "core:math/rand"
import "core:time"

import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

map_val :: proc(
	v: $T,
	in_start, in_end, out_start, out_end: T,
) -> T where intrinsics.type_is_float(T) {
	return (((out_end - out_start) * (v - in_start)) / (in_end - in_start)) + out_start
}

rand_col_f :: proc() -> [4]f32 {
	return {rand.float32(), rand.float32(), rand.float32(), rand.float32()}
}

/******************************************************************************
Movement
******************************************************************************/

polar_to_cartesian :: proc(r: $T, theta: T) -> [2]T where intrinsics.type_is_float(T) {
	return {r * math.cos(theta), r * math.sin(theta)}
}

cartesian_to_polar :: proc(coords: [2]$T) -> (r: T, theta: T) where intrinsics.type_is_float(T) {
	r = math.sqrt(math.pow(coords.x, 2) + (math.pow(coords.y, 2)))
	theta = math.atan2(coords.y, coords.x)

	return r, theta
}

lemniscate_gerono :: proc(theta: f32) -> [2]f32 {
	x := math.cos(theta)
	y := math.sin(2 * theta) / 2
	return {x, y}
}

lissajous :: proc(theta: f32) -> [2]f32 {
	a: f32 = 3.0
	b: f32 = 4.0
	r: f32 = 1.570796

	x := math.sin(a * theta + r)
	y := math.sin(b * theta)
	return {x, y}
}

interp :: proc(easing: ease.Ease, begin, end: $Value, t: $T) -> Value {
	return begin + (end - begin) * ease.ease(easing, t)
}

lerp :: proc(begin, end: $T, t: f64) -> T {
	return ease(ease.Ease.Linear, begin, end, t)
}

/******************************************************************************
Timer
******************************************************************************/

Timer :: struct {
	interval:       time.Duration,
	prev_tick_time: time.Time,
	is_running:     bool,
}

timer_init :: proc(timer: ^Timer, interval: time.Duration) {
	timer.interval = interval
}

timer_start :: proc(timer: ^Timer) {
	timer.prev_tick_time = time.now()
	timer.is_running = true
}

timer_stop :: proc(timer: ^Timer) {
	timer.is_running = false
}

timer_running :: proc(timer: ^Timer) -> bool {
	return timer.is_running
}

timer_update :: proc(timer: ^Timer) -> bool {
	if (timer.is_running) {
		now := time.now()

		if (time.diff(timer.prev_tick_time, now) > timer.interval) {
			timer.prev_tick_time = now
			return true
		}
	}

	return false
}

/******************************************************************************
LFO
******************************************************************************/

Lfo_Shape :: enum {
	sin,
	tri,
	sqr,
	saw_up,
	saw_down,
	rand,
}

splitmix_rand :: proc(input: u64) -> u64 {
	r := input + 0x9e3779b97f4a7c15
	r = (r ~ (r >> 30)) * 0xbf58476d1ce4e5b9
	r = (r ~ (r >> 27)) * 0x94d049bb133111eb
	r = r ~ (r >> 31)

	return r
}

splitmix_rand_f :: proc(input: u64) -> f64 {
	r := splitmix_rand(input)
	return f64(r >> 11) / f64(1 << 53)
}

lfo :: proc(
	freq_hz: f64,
	shape: Lfo_Shape = .sin,
	phase_offset: f64 = 0.0,
	start_time: time.Time = {},
	rand_id: u64 = 0,
	rand_smoothing: f64 = 0,
) -> f64 {
	if (freq_hz == 0.0) {
		return 0.0
	}

	elapsed_s := time.duration_seconds(time.diff(start_time, time.now()))
	period := 1.0 / freq_hz
	phase := math.mod(phase_offset + math.mod(elapsed_s, period) * freq_hz, 1.0)

	switch shape {
	case .sin:
		return 0.5 + math.sin(phase * math.PI * 2.0) * 0.5
	case .tri:
		return phase < 0.5 ? phase * 2.0 : 2 - phase * 2.0
	case .sqr:
		return phase < 0.5 ? 1 : 0
	case .saw_up:
		return phase
	case .saw_down:
		return 1 - phase
	case .rand:
		{
			count := u64(math.floor(elapsed_s / period))
			seed := splitmix_rand(rand_id)
			prev := splitmix_rand_f(seed + (count - 1))
			next := splitmix_rand_f(seed + count)

			smoothed := interp(ease.Ease.Cubic_In_Out, prev, next, phase)
			return smoothed
		}
	}

	unreachable()
}

/******************************************************************************
Shader stuff
******************************************************************************/

Shader_Uniform :: union {
	i32,
	f32,
	bool,
	rl.Vector2,
	rl.Color,
	rl.Vector4,
}

set_shader_uniform :: proc(shader: rl.Shader, name: cstring, val: Shader_Uniform) {
	value := val
	data_type: rl.ShaderUniformDataType

	switch _ in val {
	case bool:
		data_type = rl.ShaderUniformDataType.INT
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
	}

	rl.SetShaderValue(shader, rl.GetShaderLocation(shader, name), &value, data_type)
}

iris_load_shader :: proc($filename: string) -> rl.Shader {
	SHADER :: #load(filename, cstring)
	ES_V :: "#version 300 es\n\n"
	CORE_V :: "#version 330 core\n\n"

	gl_es := rlgl.GetVersion() == .OPENGL_ES_30
	versioned_shader := gl_es ? ES_V + SHADER : CORE_V + SHADER

	return rl.LoadShaderFromMemory(nil, versioned_shader)
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

	rl.SetTextureFilter(texture.texture, rl.TextureFilter.BILINEAR)

}
