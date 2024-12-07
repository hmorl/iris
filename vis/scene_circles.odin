package vis

import "base:runtime"
import "core:encoding/hex"
import "core:fmt"
import "core:math"
import "core:slice"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"

PALETTE :: `https://coolors.co/ff6b35-f7c59f-efefd0-004e89-1a659e`
// PALETTE :: `https://coolors.co/61a0af-96c9dc-f06c9b-f9b9b7-f5d491`
CIRCLE_RES :: 12

Circles_State :: struct {
	radius:               f32,
	offset:               rl.Vector2,
	col:                  rl.Color,
	drops:                [dynamic]Drop,
	prev_time:            f64,
	current_colour:       rl.Color,
	current_colour_count: i32,
}

circles_init :: proc(state_data: rawptr, params: Params) {
	state := cast(^Circles_State)(state_data)

	// state.radius = f32(rl.GetRandomValue(5, 20))
	state.offset = rl.Vector2{f32(rl.GetRandomValue(-50, 50)), f32(rl.GetRandomValue(-50, 50))}
	state.col = rl.Color{100, 100, u8(rl.GetRandomValue(0, 255)), 255}

	state.prev_time = rl.GetTime()
}

circles_draw :: proc(state_data: rawptr, params: Params, texture: rl.RenderTexture2D) {
	rl.BeginTextureMode(texture)
	defer rl.EndTextureMode()

	rl.ClearBackground(rl.BLANK)

	state := cast(^Circles_State)(state_data)

	// radius := 10 / params.scale
	// rl.DrawCircleV(params.mouse_pos, radius, state.col)

	if (rl.IsKeyPressed(rl.KeyboardKey.SPACE)) {
		clear(&state.drops)
	}

	now := rl.GetTime()

	if (rl.IsMouseButtonPressed(rl.MouseButton.LEFT)) {
		state.current_colour = get_coolors_colour_at_index(PALETTE, state.current_colour_count % 5)
		state.current_colour_count += 1
	}

	if (rl.IsMouseButtonDown(rl.MouseButton.LEFT) && now - state.prev_time > 0) {
		state.prev_time = rl.GetTime()

		new_drop := make_drop(params.mouse_pos, state.current_colour, 20)

		for &other, i in state.drops {
			marble_drop(&other, new_drop)

			if (other.should_delete) {
				ordered_remove(&state.drops, i)
			}
		}

		append(&state.drops, new_drop)
	}

	for d in state.drops {
		draw_drop(d)
	}
}

circles_deinit :: proc(scene_data: rawptr) {
}

Drop :: struct {
	pos:           rl.Vector2,
	r:             f32,
	vertices:      [CIRCLE_RES]rl.Vector2,
	col:           rl.Color,
	should_delete: bool,
}

get_coolors_colour_at_index :: proc(url: string, idx: i32) -> rl.Color {
	colour_url := strings.trim_prefix(url, "https://coolors.co/")
	colour_strings := strings.split_n(colour_url, "-", 5)

	r, _ := hex.decode_sequence(colour_strings[idx][0:2])
	g, _ := hex.decode_sequence(colour_strings[idx][2:4])
	b, _ := hex.decode_sequence(colour_strings[idx][4:6])

	return rl.Color{r, g, b, 255}
}

map_value :: proc(
	value: f32,
	source_min: f32,
	source_max: f32,
	target_min: f32,
	target_max: f32,
) -> f32 {
	source_range := source_max - source_min
	target_range := target_max - target_min

	return (value - source_min) / source_range * target_range + target_min
}

make_drop :: proc(pos: rl.Vector2, colour: rl.Color, radius: f32) -> Drop {
	vertices := [CIRCLE_RES]rl.Vector2{}

	for &v, idx in vertices {
		angle := map_value(f32(idx), 0, CIRCLE_RES, math.PI * 2.0, 0.0)
		v = rl.Vector2{math.cos(angle), math.sin(angle)} * radius + pos
	}

	return {pos, radius, vertices, colour, false}
}

is_off_screen :: proc(point: rl.Vector2) -> bool {
	off_screen_x := point.x < 0 || point.x > f32(rl.GetScreenWidth())
	off_screen_y := point.y < 0 || point.y > f32(rl.GetScreenHeight())

	return off_screen_x || off_screen_y
}

marble_drop :: proc(drop: ^Drop, marbling_drop: Drop) {
	marble_vertex :: proc(v: rl.Vector2, marbling_drop: Drop) -> rl.Vector2 {
		if v == marbling_drop.pos {
			return v
		}

		c := marbling_drop.pos
		r := marbling_drop.r

		p := v - c
		mag := rl.Vector2Length(p)
		root := math.sqrt(1 + (r * r) / (mag * mag))
		return (p * root) + c
	}

	for &v in drop.vertices {
		v = marble_vertex(v, marbling_drop)
	}

	drop.pos = marble_vertex(drop.pos, marbling_drop)

	if slice.all_of_proc(drop.vertices[:], is_off_screen) {
		drop.should_delete = true
	}
}

draw_drop :: proc(drop: Drop) {
	circumference_vertices := drop.vertices
	fan_vertices: [CIRCLE_RES + 2]rl.Vector2

	slice.first_ptr(fan_vertices[:])^ = drop.pos
	copy(fan_vertices[1:len(circumference_vertices) + 1], circumference_vertices[:])
	slice.last_ptr(fan_vertices[:])^ = slice.first(circumference_vertices[:])

	rl.DrawTriangleFan(slice.as_ptr(fan_vertices[:]), len(fan_vertices), drop.col)
}
