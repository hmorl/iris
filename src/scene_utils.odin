package iris

import "base:intrinsics"
import "core:math"
import "core:math/rand"
import "core:time"

import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

rand_col_f :: proc() -> [4]f32 {
	return {rand.float32(), rand.float32(), rand.float32(), rand.float32()}
}

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

iris_load_shader :: proc($filename: string) -> rl.Shader {
	SHADER :: #load(filename, cstring)
	ES_V :: "#version 300 es\n\n"
	CORE_V :: "#version 330 core\n\n"

	gl_es := rlgl.GetVersion() == .OPENGL_ES_30
	versioned_shader := gl_es ? ES_V + SHADER : CORE_V + SHADER

	return rl.LoadShaderFromMemory(nil, versioned_shader)
}
