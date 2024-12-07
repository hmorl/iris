package audio

import "core:fmt"
import "core:math"
import "core:math/cmplx"
import "core:slice"
import "core:strings"

import ma "vendor:miniaudio"

Audio_Context :: struct {
	ma_context: ma.context_type,
	device:     ma.device,
	data:       Audio_Data,
}

BUFFER_SIZE :: 256
SAMPLE_RATE :: 44100

Audio_Data :: struct {
	buffers:      [2][BUFFER_SIZE]f32,
	write_buffer: i32,
	read_buffer:  i32,
}

init_audio :: proc(ctx: ^Audio_Context) -> bool {
	result := ma.context_init(nil, 0, nil, &ctx.ma_context)

	if (result != ma.result.SUCCESS) {
		return false
	}

	capture_device_infos: [^]ma.device_info
	capture_device_count: u32
	ma.context_get_devices(&ctx.ma_context, nil, nil, &capture_device_infos, &capture_device_count)

	capture_devices := slice.from_ptr(capture_device_infos, int(capture_device_count))

	if (slice.is_empty(capture_devices)) {
		return false
	}

	device_name_filter := "BlackHole"

	device_id := slice.first(capture_devices).id

	for device in capture_devices {
		if device.isDefault {
			device_id = device.id
		}
	}

	if (len(device_name_filter) > 0) {
		for &device in capture_devices {
			name := strings.trim_null(strings.clone_from_bytes(device.name[:]))

			if strings.contains(strings.to_lower(name), strings.to_lower(device_name_filter)) {
				device_id = device.id
				break
			}
		}
	}

	id := strings.trim_null(strings.clone_from_bytes(device_id.coreaudio[:]))
	fmt.println("Chosen id: ", id)

	device_config := ma.device_config_init(ma.device_type.capture)
	device_config.capture.pDeviceID = &device_id
	device_config.dataCallback = audio_callback
	device_config.capture.format = ma.format.f32
	device_config.sampleRate = SAMPLE_RATE
	device_config.capture.channels = 1
	device_config.pUserData = &ctx.data
	device_config.periodSizeInFrames = BUFFER_SIZE

	if (ma.device_init(&ctx.ma_context, &device_config, &ctx.device) != ma.result.SUCCESS) {
		return false
	}

	return ma.device_start(&ctx.device) == ma.result.SUCCESS
}

deinit_audio :: proc(ctx: ^Audio_Context) {
	ma.device_uninit(&ctx.device)
	ma.context_uninit(&ctx.ma_context)
}

a_weighting :: proc(freq: f32) -> f32 {
	freq_sq := math.pow(freq, 2)

	weighting :=
		1.2588966 *
		148840000 *
		freq_sq *
		freq_sq /
		((freq_sq + 424.36) *
				math.sqrt((freq_sq + 11599.29) * (freq_sq + 544496.41)) *
				(freq_sq + 148840000))

	return weighting
}

calc_rms :: proc(buffer: []f32) -> f32 {
	sum_squares: f32 = 0.0

	for s in buffer {
		sum_squares += s * s
	}

	return math.sqrt(sum_squares / f32(len(buffer)))
}

calc_fft :: proc(input: []complex64) -> []complex64 {
	size := len(input)

	assert(math.is_power_of_two(size))

	if (size <= 1) do return input

	half_size := size / 2

	even := make([]complex64, half_size)
	odd := make([]complex64, half_size)

	for i in 0 ..< half_size {
		even[i] = input[2 * i]
		odd[i] = input[2 * i + 1]
	}

	even_fft := calc_fft(even)
	odd_fft := calc_fft(odd)

	result := make([]complex64, size)

	for k in 0 ..< half_size {
		t := odd_fft[k]
		angle := -2.0 * math.PI * f32(k) / f32(size)
		w := complex(math.cos(angle), math.sin(angle))
		twiddle := w * t
		result[k] = even_fft[k] + twiddle
		result[k + half_size] = even_fft[k] - twiddle
	}

	return result
}

hann_window_coeff :: proc(index, size: int) -> f32 {
	return 0.5 * (1.0 - math.cos(2.0 * math.PI * f32(index) / f32(size - 1)))
}

calc_spectrum :: proc(buffer: []f32) -> []f32 {
	N := len(buffer)
	assert(math.is_power_of_two(N))

	buffer_cmplx := make([]complex64, N)
	for s, idx in buffer {
		buffer_cmplx[idx] = complex(s * hann_window_coeff(idx, N), 0.0)
	}

	fft := calc_fft(buffer_cmplx)

	power_spectrum := make([]f32, len(buffer) / 2)
	for &s, idx in power_spectrum {
		freq := f32(idx) * SAMPLE_RATE / f32(len(buffer))
		s = a_weighting(freq) * cmplx.abs(fft[idx])
	}

	return power_spectrum
}

@(private)
audio_callback :: proc "c" (pDevice: ^ma.device, pOutput, pInput: rawptr, frameCount: u32) {
	// context = runtime.default_context()
	user_data := (^Audio_Data)(pDevice.pUserData)

	samples := slice.from_ptr((^f32)(pInput), (int)(frameCount))

	for i in 0 ..< frameCount {
		user_data.buffers[user_data.write_buffer][i] = samples[i]
	}

	user_data.read_buffer = user_data.write_buffer
	user_data.write_buffer = (user_data.write_buffer + 1) % 2
}
