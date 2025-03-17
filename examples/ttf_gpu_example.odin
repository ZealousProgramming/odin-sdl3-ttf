package examples

import "core:fmt"
import "core:strings"
import "core:c"
import "core:mem"
import "core:log"
import "base:runtime"

import sdl "vendor:sdl3"
import ttf "../"
import glm "core:math/linalg/glsl"

vec2 :: [2]f32
vec3 :: [3]f32
vec4 :: [4]f32
mat4 :: glm.mat4

Shader_Kind :: enum {
	Vertex,
	Pixel,
}

Vertex :: struct {
	position: vec3,
	color: sdl.FColor,
	uv: vec2,
}

Geometry_Data :: struct {
	vertices: [MAX_VERTEX_COUNT]Vertex,
	vertex_count: c.int,
	indices: [MAX_INDEX_COUNT]u32,
	index_count: c.int,
}

Graphics_Context :: struct {
	gpu_device: ^sdl.GPUDevice,
	window: ^sdl.Window,
	pipeline: ^sdl.GPUGraphicsPipeline, // We're only supporting a single pipeline in this demo
	text_engine: ^ttf.TextEngine,
	vertex_buffer: ^sdl.GPUBuffer,
	index_buffer: ^sdl.GPUBuffer,
	transfer_buffer: ^sdl.GPUTransferBuffer,
	sampler: ^sdl.GPUSampler,
	command_buffer: ^sdl.GPUCommandBuffer,

}

Camera_Uniform_Buffer :: struct {
	projection_view: mat4,
	model:      mat4,
}

main :: proc() {
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)
	context.logger = log.create_console_logger(log.Level.Debug)
	g_default_context = context

	assert(init())
	assert(font_init())

	text: cstring = "SDL3_TTF GPU EXAMPLE IN ODIN!"
	message_text := ttf.CreateText(g_ctx.text_engine, g_font, text, len(text))
	if message_text == nil {
		lperr("ERROR: Failed to create text")
		return
	}
	defer ttf.DestroyText(message_text)


	quit := false
	for !quit {
		ev: sdl.Event
		for sdl.PollEvent(&ev) {
			#partial switch ev.type {
			case .QUIT: {
				quit = true
				continue
			}
			case .KEY_DOWN, .KEY_UP: {
				if ev.key.scancode == .ESCAPE {
					quit = true
					continue
				}
			}

			}
		}

		// Rendering
		// -----------
		sequence: ^ttf.GPUAtlasDrawSequence = ttf.GetGPUTextDrawData(message_text)
		if sequence == nil {
			lperr("ERROR: FAILED TO GET GPU TEXT DRAW DATA")
			continue
		}

		// move the text data into our buffers
		{
			seq := sequence
			finished := seq == nil
			for !finished {
				if seq == nil {
					finished = true
					continue
				}

				for i: i32 = 0; i < seq.num_vertices; i += 1 {
					pos_point := seq.xy[i]
					vert := Vertex{
						position = vec3{pos_point.x, pos_point.y, 0.0},
						color = sdl.FColor{1.0, 1.0, 1.0, 1.0},
						uv = cast(vec2)seq.uv[i],
					}

					g_font_data.vertices[g_font_data.vertex_count + i] = vert
				}

				mem.copy(mem.ptr_offset(&g_font_data.indices, g_font_data.index_count), seq.indices, size_of(c.int) * int(seq.num_indices))

				g_font_data.vertex_count += seq.num_vertices
				g_font_data.index_count += seq.num_indices

				seq = seq.next
			}

		}

		// copy the font geometry to transfer buffer
		vbytes: int = size_of(Vertex) * int(g_font_data.vertex_count)
		ibytes: int = size_of(c.int) * int(g_font_data.index_count)
		{
			transfer_mem := cast([^]byte)sdl.MapGPUTransferBuffer(g_ctx.gpu_device, g_ctx.transfer_buffer, false)

			mem.copy(transfer_mem, raw_data(g_font_data.vertices[:]), vbytes)
			mem.copy(transfer_mem[vbytes:], raw_data(g_font_data.indices[:]), ibytes)

			sdl.UnmapGPUTransferBuffer(g_ctx.gpu_device, g_ctx.transfer_buffer)
		}

		cmd_buffer := sdl.AcquireGPUCommandBuffer(g_ctx.gpu_device)
		if cmd_buffer == nil { 
			lperr("ERRROR: Failed to acqure GPU command buffer")
			continue 
		}
		g_ctx.command_buffer = cmd_buffer

		// upload the transfer buffer to the gpu
		{	
			// copy_command_buffer := sdl.AcquireGPUCommandBuffer(g_ctx.gpu_device)
			// copy_pass := sdl.BeginGPUCopyPass(copy_command_buffer)
			copy_pass := sdl.BeginGPUCopyPass(g_ctx.command_buffer)

			sdl.UploadToGPUBuffer(
				copy_pass,
				sdl.GPUTransferBufferLocation{
					transfer_buffer = g_ctx.transfer_buffer,
				},
				sdl.GPUBufferRegion {
					buffer = g_ctx.vertex_buffer,
					size = u32(vbytes),
				},
				false,
			)

			sdl.UploadToGPUBuffer(
				copy_pass,
				sdl.GPUTransferBufferLocation{
					transfer_buffer = g_ctx.transfer_buffer,
					offset = u32(vbytes),
				},
				sdl.GPUBufferRegion {
					buffer = g_ctx.index_buffer,
					size = u32(ibytes),
				},
				false,
			)

			sdl.EndGPUCopyPass(copy_pass)
		}

		// draw

		swapchain_texture: ^sdl.GPUTexture
		sta_ok := sdl.WaitAndAcquireGPUSwapchainTexture (
			g_ctx.command_buffer,
			g_ctx.window,
			&swapchain_texture,
			nil,
			nil,
		)
		if !sta_ok { 
			lperr("ERRROR: Failed to acqure GPU swapchain texture")
			continue 
		}

		if swapchain_texture != nil {
			color_target := sdl.GPUColorTargetInfo {
				texture     = swapchain_texture,
				load_op     = .CLEAR,
				clear_color = sdl.FColor{0.3, 0.3, 0.3, 1.0},
				store_op    = .STORE,
			}

			// begin render pass
			rp := sdl.BeginGPURenderPass(
				g_ctx.command_buffer,
				&color_target,
				1, // number of color targets
				nil, // depth_stencil target info
			)
			{
				// font rendering pipeline
				sdl.BindGPUGraphicsPipeline(rp, g_ctx.pipeline)
				sdl.BindGPUVertexBuffers(
					rp,
					0,
					&(sdl.GPUBufferBinding {
						buffer = g_ctx.vertex_buffer,
						offset = 0,
					}),
					1,
				)
				sdl.BindGPUIndexBuffer(
					rp,
					sdl.GPUBufferBinding {
						buffer = g_ctx.index_buffer,
						offset = 0,
					},
					._32BIT,
				)

				mat  := Camera_Uniform_Buffer {
					projection_view = glm.mat4Perspective(
						glm.radians_f32(90),
						f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT),
						0.1,
						1000.0,
					) * glm.mat4LookAt (
						vec3{0.0, 0.0, 0.0},
						vec3{0.0, 0.0, -1.0}, // forward
						vec3{0.0, 1.0, 0.0},
					),
					model = glm.mat4Translate(vec3{-400.0, 50.0, -500.0}),
				}

				sdl.PushGPUVertexUniformData(
					g_ctx.command_buffer, 
					0,
					&mat,
					u32(size_of(Camera_Uniform_Buffer)),
				)

				index_offset: int = 0
				vertex_offset: int = 0
				for seq := sequence; seq != nil; seq = seq.next {
					sdl.BindGPUFragmentSamplers(
						rp,
						0,
						&(sdl.GPUTextureSamplerBinding {
							texture = seq.atlas_texture,
							sampler = g_ctx.sampler,
						}),
						1,
					)

					sdl.DrawGPUIndexedPrimitives(
						rp,
						u32(seq.num_indices),
						1,
						u32(index_offset),
						i32(vertex_offset),
						0,
					)

					index_offset += int(seq.num_indices)
					vertex_offset += int(seq.num_vertices)
				}
			}
			// end render pass
			sdl.EndGPURenderPass(rp)

			submit_ok := sdl.SubmitGPUCommandBuffer(g_ctx.command_buffer)
			if !submit_ok { 
				lperr("ERRROR: Failed to submit GPU command buffer")
				continue 
			}
		}

		g_font_data.vertex_count = 0
		g_font_data.index_count = 0
	}

	shutdown()

	log.destroy_console_logger(context.logger)
	for _, leak in track.allocation_map {
		fmt.eprintf("%v leaked %v bytes\n", leak.location, leak.size)
	}

	for bad_free in track.bad_free_array {
		fmt.eprintf(
			"%p allocation %p was freed incorrectly\n",
			bad_free.location,
			bad_free.memory,
		)
	}
}

init :: proc() -> bool {
	when ODIN_DEBUG {
		sdl.SetLogPriorities(.VERBOSE)
		sdl.SetLogOutputFunction(sdl_log, nil)
	}

	if !sdl.Init({.VIDEO}) {
		lperr("ERRROR: Failed to initialize SDL")
		return false
	}

	if !ttf.Init() {
		lperr("ERRROR: Failed to initialize TTF")
		return false
	}

	window := sdl.CreateWindow("SDL3 TFF Example", 1280, 720, {.RESIZABLE, .HIGH_PIXEL_DENSITY})
	if window == nil {
		lperr("ERROR: Failed to create window")
		return false
	}

	gpu_device := sdl.CreateGPUDevice({.SPIRV, .MSL}, true, nil)
	if gpu_device == nil {
		lperr("ERRROR: Failed to GPU device")
		return false
	}

	cw_ok := sdl.ClaimWindowForGPUDevice(gpu_device, window)
	if !cw_ok {
		lperr("ERRROR: Failed to claim window for GPU device")
		return false
	}
	g_ctx.gpu_device = gpu_device
	g_ctx.window = window


	text_engine := ttf.CreateGPUTextEngine(gpu_device)
	if text_engine == nil {
		lperr("ERRROR: Failed to GPU text engine")
		return false
	}
	g_ctx.text_engine = text_engine

	base_path := string(sdl.GetBasePath())
	font_path: string = fmt.tprintf("%vInter-VariableFont.ttf", base_path)
	fmt.println("Loading Font from:", font_path)
	font := ttf.OpenFont(strings.clone_to_cstring(font_path, context.temp_allocator), 48)
	if font == nil {
		lperr("ERRROR: Failed to open font")
		return false
	}
	g_font = font

	vertex_shader := load_shader(g_ctx.gpu_device, .Vertex, 0, 1, 0, 0)
	pixel_shader := load_shader(g_ctx.gpu_device, .Pixel, 1, 0, 0, 0)

	if vertex_shader == nil || pixel_shader == nil {
		log.error("ERROR: Failed to load shaders")
		return false
	}

	target_info := sdl.GPUGraphicsPipelineTargetInfo {
		num_color_targets = 1,
		has_depth_stencil_target = false,
		depth_stencil_format = .INVALID,
		color_target_descriptions = &(sdl.GPUColorTargetDescription {
				format = sdl.GetGPUSwapchainTextureFormat(g_ctx.gpu_device, g_ctx.window),
				blend_state = sdl.GPUColorTargetBlendState{
						enable_blend = true,
	                    alpha_blend_op = .ADD,
	                    color_blend_op = .ADD,
	                    color_write_mask = {.A},
	                    src_alpha_blendfactor = .SRC_ALPHA,
	                    dst_alpha_blendfactor = .DST_ALPHA,
	                    src_color_blendfactor = .SRC_ALPHA,
	                    dst_color_blendfactor = .ONE_MINUS_SRC_ALPHA,
	            },
		}),

	}

	attributes := []sdl.GPUVertexAttribute {
		{
			buffer_slot = 0,
			format = .FLOAT3,
			location = 0,
			offset = 0,
		},
		{
			buffer_slot = 0,
			format = .FLOAT4,
			location = 1,
			offset = size_of(vec3),
		},
		{
			buffer_slot = 0,
			format = .FLOAT2,
			location = 2,
			offset = size_of(vec3) + size_of(sdl.FColor),
		},
	}

	input_state := sdl.GPUVertexInputState {
		num_vertex_buffers = 1,
		vertex_buffer_descriptions = &(sdl.GPUVertexBufferDescription{
				slot = 0,
				input_rate = .VERTEX,
				pitch = size_of(Vertex),
		}),
		num_vertex_attributes = u32(len(attributes)),
		vertex_attributes = raw_data(attributes),
	}

	pipeline_create_info := sdl.GPUGraphicsPipelineCreateInfo {
		target_info = target_info,
		vertex_shader = vertex_shader,
		fragment_shader = pixel_shader,
		primitive_type = .TRIANGLELIST,
		vertex_input_state = input_state,
	}

	g_ctx.pipeline = sdl.CreateGPUGraphicsPipeline(g_ctx.gpu_device, pipeline_create_info)
	if g_ctx.pipeline == nil {
		lperr("ERROR: Failed to create GPU pipeline")
		return false
	}

	sdl.ReleaseGPUShader(g_ctx.gpu_device, vertex_shader)
	sdl.ReleaseGPUShader(g_ctx.gpu_device, pixel_shader)

	return true
}

shutdown :: proc() {
	ttf.CloseFont(g_font)
	ttf.DestroyGPUTextEngine(g_ctx.text_engine)
	ttf.Quit()

	sdl.ReleaseGPUTransferBuffer(g_ctx.gpu_device, g_ctx.transfer_buffer)
	sdl.ReleaseGPUSampler(g_ctx.gpu_device, g_ctx.sampler)
	sdl.ReleaseGPUBuffer(g_ctx.gpu_device, g_ctx.vertex_buffer)
	sdl.ReleaseGPUBuffer(g_ctx.gpu_device, g_ctx.index_buffer)
	sdl.ReleaseGPUGraphicsPipeline(g_ctx.gpu_device, g_ctx.pipeline)
	sdl.ReleaseWindowFromGPUDevice(g_ctx.gpu_device, g_ctx.window)
	sdl.DestroyGPUDevice(g_ctx.gpu_device)
	sdl.DestroyWindow(g_ctx.window)
}

load_shader :: proc(
	gpu_device: ^sdl.GPUDevice,
	shader_kind: Shader_Kind,
	sampler_count: u32,
	uniform_buffer_count: u32,
	storage_buffer_count: u32,
	storage_texture_count: u32,
) -> ^sdl.GPUShader {

	shader_format := sdl.GetGPUShaderFormats(gpu_device)
	create_info := sdl.GPUShaderCreateInfo {
		num_samplers = sampler_count,
		num_storage_buffers = storage_buffer_count,
		num_storage_textures = storage_texture_count,
		num_uniform_buffers = uniform_buffer_count,
	}

	if .SPIRV in shader_format {
		create_info.format = {.SPIRV}

		switch(shader_kind) {
		case .Vertex: {
			create_info.code = raw_data(gpu_font_vert_spv)
			create_info.code_size = len(gpu_font_vert_spv)
			create_info.entrypoint = "main"
			create_info.stage = .VERTEX

		}
		case .Pixel: {
			create_info.code = raw_data(gpu_font_frag_spv)
			create_info.code_size = len(gpu_font_frag_spv)
			create_info.entrypoint = "main"
			create_info.stage = .FRAGMENT
		}
		}
	} else if .MSL in shader_format {
		log.info("Loading MSL shader..")
		create_info.format = {.MSL}

		switch(shader_kind) {
		case .Vertex: {
			create_info.code = raw_data(gpu_font_vert_msl)
			create_info.code_size = len(gpu_font_vert_msl)
			create_info.entrypoint = "main0"
			create_info.stage = .VERTEX

		}
		case .Pixel: {
			create_info.code = raw_data(gpu_font_frag_msl)
			create_info.code_size = len(gpu_font_frag_msl)
			create_info.entrypoint = "main0"
			create_info.stage = .FRAGMENT
		}
		}
	}

	shader := sdl.CreateGPUShader(gpu_device, create_info)
	if shader == nil {
		lperr("ERROR: Failed to create GPU shader")
		return nil
	}

	return shader
}

font_init :: proc() -> bool {
	// Create vertex buffer
	vb_info := sdl.GPUBufferCreateInfo {
		usage = {.VERTEX},
		size = u32(size_of(Vertex) * MAX_VERTEX_COUNT),
	}
	g_ctx.vertex_buffer = sdl.CreateGPUBuffer(g_ctx.gpu_device, vb_info)
	if g_ctx.vertex_buffer == nil {
		lperr("ERROR: Failedd to create GPU vertex buffer")
		return false
	}

	// Create index buffer
	ib_info := sdl.GPUBufferCreateInfo {
		usage = {.INDEX},
		size = u32(size_of(u32) * MAX_INDEX_COUNT),
	}
	g_ctx.index_buffer = sdl.CreateGPUBuffer(g_ctx.gpu_device, ib_info)
	if g_ctx.index_buffer == nil {
		lperr("ERROR: Failedd to create GPU index buffer")
		return false
	}

	// Create transfer buffer
	tb_info := sdl.GPUTransferBufferCreateInfo {
		usage = .UPLOAD,
		size = u32(size_of(Vertex) * MAX_VERTEX_COUNT) + u32(size_of(u32) * MAX_INDEX_COUNT),
	}
	g_ctx.transfer_buffer = sdl.CreateGPUTransferBuffer(g_ctx.gpu_device, tb_info)
	if g_ctx.transfer_buffer == nil {
		lperr("ERROR: Failedd to create GPU transfer buffer")
		return false
	}

	// Create Sampler
	samp_info := sdl.GPUSamplerCreateInfo {
		min_filter = .LINEAR,
		mag_filter = .LINEAR,
		mipmap_mode = .LINEAR,
		address_mode_u = .CLAMP_TO_EDGE,
		address_mode_v = .CLAMP_TO_EDGE,
		address_mode_w = .CLAMP_TO_EDGE,
	}
	g_ctx.sampler = sdl.CreateGPUSampler(g_ctx.gpu_device, samp_info)
	if g_ctx.sampler == nil {
		lperr("ERROR: Failedd to create GPU sampler")
		return false
	}

	return true
}

// Log previous SDL error
lperr :: proc(prefix: string) {
	log.errorf("%s: %v\n", prefix, sdl.GetError())
}

sdl_log :: proc "c" (
	userdata: rawptr,
	category: sdl.LogCategory,
	priority: sdl.LogPriority,
	message: cstring,
) {
	context = g_default_context

	switch priority {
	case .TRACE, .VERBOSE, .DEBUG:
		{
			log.debugf(
				"[sdl] {}  [{}]: {}",
				category,
				priority,
				message,
			)
		}
	case .INFO:
		{
			log.infof("[sdl] {}  [{}]: {}", category, priority, message)
		}
	case .WARN:
		{
			log.warnf("[sdl] {}  [{}]: {}", category, priority, message)
		}
	case .ERROR, .CRITICAL:
		{
			log.errorf(
				"[sdl] {}  [{}]: {}",
				category,
				priority,
				message,
			)
		}
	case .INVALID:
		{
			log.warnf(
				"[sdl] `.INVALID` priority given to the following message: {} - {}",
				category,
				message,
			)
		}
	}
}


// Variables
// ----------------
track: mem.Tracking_Allocator
g_default_context: runtime.Context
g_ctx: Graphics_Context
g_font: ^ttf.Font
g_font_data: Geometry_Data

gpu_font_vert_spv :: #load("../bin/shaders/gpu_font.vert.spv")
gpu_font_frag_spv :: #load("../bin/shaders/gpu_font.frag.spv")
gpu_font_vert_msl :: #load("../bin/shaders/gpu_font.vert.msl")
gpu_font_frag_msl :: #load("../bin/shaders/gpu_font.frag.msl")
 
 
MAX_VERTEX_COUNT :: u32(4000)
MAX_INDEX_COUNT :: u32(6000)

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

