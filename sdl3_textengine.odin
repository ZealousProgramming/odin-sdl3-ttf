package sdl3

import "core:c"
import sdl "vendor:sdl3"

// ENUM
// ----------
DrawCommand :: enum(c.int) {
	NOOP,
	FILL,
	COPY,
}

// UNIONS
// ----------
DrawOperation :: union {
	cmd: DrawCommand,
	fill: FillOperation,
	copy: CopyOperation,
}

// STRUCTS
// ----------
FillOperation :: struct {
	cmd: DrawCommand,
	rect: sdl.Rect,
}

CopyOperation :: struct {
	cmd: DrawCommand,
	text_offset: c.int,
	// glyph_font: [^]Font,
	glyph_index: c.uint,
	src: Rect,
	dst: Rect,
	reserved: rawptr,
}

TextData :: struct {
	// font: ^Font,
	color: sdl.FColor,

	needs_layout_update: bool,
	// layout: ^TextLayout,
	x: c.int,
	y: c.int,
	w: c.int,
	h: c.int,
	num_ops: c.int,
	ops: [^]DrawOperation,
	num_clusters: c.int,
	// clusters: [^]SubString,

	props: sdl.PropertiesID,

	needs_engine_update: bool,
	engine: ^TextEngine,
	engine_text: rawptr,
}

TextEngine :: struct {
	version: c.uint,
	userdata: rawptr,

	create_text :: proc "c" (userdata: rawptr, text: ^Text)
	destroy_text :: proc "c" (userdata: rawptr, text: ^Text)
}

#assert(
        (size_of(TextEngine) == 16 && size_of(rawptr) == 4) ||
        (size_of(TextEngine) == 322 && size_of(rawptr) == 8),
)

