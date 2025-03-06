package sdl3

import "core:c"

when ODIN_OS == .Windows {
	@(export) foreign import lib { "SDL3_tff.lib" }
} else {
	@(export) foreign import lib { "system:SDL3_tff" }
}

// CONSTANTS
// ----------
PROP_FONT_CREATE_FILENAME_STRING            		:: "SDL_ttf.font.create.filename"
PROP_FONT_CREATE_IOSTREAM_POINTER           		:: "SDL_ttf.font.create.iostream"
PROP_FONT_CREATE_IOSTREAM_OFFSET_NUMBER     		:: "SDL_ttf.font.create.iostream.offset"
PROP_FONT_CREATE_IOSTREAM_AUTOCLOSE_BOOLEAN 		:: "SDL_ttf.font.create.iostream.autoclose"
PROP_FONT_CREATE_SIZE_FLOAT                 		:: "SDL_ttf.font.create.size"
PROP_FONT_CREATE_FACE_NUMBER                		:: "SDL_ttf.font.create.face"
PROP_FONT_CREATE_HORIZONTAL_DPI_NUMBER      		:: "SDL_ttf.font.create.hdpi"
PROP_FONT_CREATE_VERTICAL_DPI_NUMBER        		:: "SDL_ttf.font.create.vdpi"
PROP_FONT_CREATE_EXISTING_FONT              		:: "SDL_ttf.font.create.existing_font"

PROP_FONT_OUTLINE_LINE_CAP_NUMBER           		:: "SDL_ttf.font.outline.line_cap"
PROP_FONT_OUTLINE_LINE_JOIN_NUMBER          		:: "SDL_ttf.font.outline.line_join"
PROP_FONT_OUTLINE_MITER_LIMIT_NUMBER        		:: "SDL_ttf.font.outline.miter_limit"

PROP_RENDERER_TEXT_ENGINE_RENDERER                 	:: "SDL_ttf.renderer_text_engine.create.renderer"
PROP_RENDERER_TEXT_ENGINE_ATLAS_TEXTURE_SIZE       	:: "SDL_ttf.renderer_text_engine.create.atlas_texture_size"

PROP_GPU_TEXT_ENGINE_DEVICE                   		:: "SDL_ttf.gpu_text_engine.create.device"
PROP_GPU_TEXT_ENGINE_ATLAS_TEXTURE_SIZE       		:: "SDL_ttf.gpu_text_engine.create.atlas_texture_size"



// STRUCTS
// ----------
Font :: struct {} //Opaque data
TextEngine :: struct {}
TextData :: struct {}

Text :: struct {
    text: cstring,          /**< A copy of the UTF-8 string that this text object represents, useful for layout, debugging and retrieving substring text. This is updated when the text object is modified and will be freed automatically when the object is destroyed. */
	num_lines: c.int,       /**< The number of lines in the text, 0 if it's empty */

    refcount: c.int,        /**< Application reference count, used when freeing surface */

    internal: ^TextData; 	/**< Private */
}

GPUAtlasDrawSequence :: struct {
	atlas_texture: ^sdl.GPUTexture,         /**< Texture atlas that stores the glyphs */
    xy: ^sdl.FPoint,                        /**< An array of vertex positions */
    uv: ^sdl.FPoint,                        /**< An array of normalized texture coordinates for each vertex */
    num_vertices: c.int,                    /**< Number of vertices */
    indices: [^]c.int,                      /**< An array of indices into the 'vertices' arrays */
    num_indices: c.int,                     /**< Number of indices */
    image_type: ImageType,               	/**< The image type of this draw sequence */

    next: ^GPUAtlasDrawSequence,  			/**< The next sequence (will be NULL in case of the last sequence) */
}

SubString :: struct {
	flags: SubStringFlags,			/**< The flags for this substring */
    offset: c.int,                 	/**< The byte offset from the beginning of the text */
    length: c.int,                 	/**< The byte length starting at the offset */
    line_index: c.int,             	/**< The index of the line that contains this substring */
    cluster_index: c.int,          	/**< The internal cluster index, used for quickly iterating */
    rect: sdl.Rect,              	/**< The rectangle, relative to the top left of the text, containing the substring */
}

typedef struct TTF_SubString
{
    TTF_SubStringFlags flags;   /**< The flags for this substring */
    int offset;                 /**< The byte offset from the beginning of the text */
    int length;                 /**< The byte length starting at the offset */
    int line_index;             /**< The index of the line that contains this substring */
    int cluster_index;          /**< The internal cluster index, used for quickly iterating */
    SDL_Rect rect;              /**< The rectangle, relative to the top left of the text, containing the substring */
} TTF_SubString;

// ENUMS
// ----------
FontStyleFlags :: distinct bit_set[FontStyleFlag; enum Uint32]
FontStyleFlag :: enum Uint32 {
	NORMAL        = 0 /**< No special style */
	BOLD          = 1 /**< Bold style */
	ITALIC        = 2 /**< Italic style */
	UNDERLINE     = 3 /**< Underlined text */
	STRIKETHROUGH = 4 /**< Strikethrough text */
}

HintingFlags :: enum c.int {
	NORMAL = 0,     /**< Normal hinting applies standard grid-fitting. */
	LIGHT,          /**< Light hinting applies subtle adjustments to improve rendering. */
	MONO,           /**< Monochrome hinting adjusts the font for better rendering at lower resolutions. */
	NONE,           /**< No hinting, the font is rendered without any grid-fitting. */
	LIGHT_SUBPIXEL  /**< Light hinting with subpixel rendering for more precise font edges. */
}

HorizontalAlignment :: enum c.int {
	INVALID = -1,
	LEFT,
	CENTER,
	RIGHT,
}

Direction :: enum c.int {
	INVALID = 0,
	LTR = 4,        /**< Left to Right */
	RTL,            /**< Right to Left */
	TTB,            /**< Top to Bottom */
	BTT             /**< Bottom to Top */
}

ImageType :: enum c.int {
	INVALID,
	ALPHA,    /**< The color channels are white */
	COLOR,    /**< The color channels have image data */
	SDF,      /**< The alpha channel has signed distance field information */
}

GPUTextEngineWinding :: enum c.int {
	INVALID = -1,
	CLOCKWISE,
	COUNTER_CLOCKWISE,
}

SubStringFlags :: distinct bit_set[SubStringsFlag; enum Uint32]
SubStringFlag :: enum Uint32 {
	DIRECTION_MASK    = 0x000000FF,  /**< The mask for the flow direction for this substring */
	TEXT_START        = 0x00000100,  /**< This substring contains the beginning of the text */
	LINE_START        = 0x00000200,  /**< This substring contains the beginning of line `line_index` */
	LINE_END          = 0x00000400,  /**< This substring contains the end of line `line_index` */
	TEXT_END          = 0x00000800,  /**< This substring contains the end of the text */
}


// PROCEDURES
// ----------
@(default_calling_convention="c", link_prefix="TTF_")
foreign lib {
	Version :: proc() -> c.int ---
	GetFreeTypeVersion :: proc(major: ^c.int, minor: ^c.int, patch: ^c.int) ---
	GetHarfBuzzVersion :: proc(major: ^c.int, minor: ^c.int, patch: ^c.int) --- 

	Init :: proc() -> bool --- 
	OpenFont :: proc(file: cstring, ptsize: c.float) -> ^Font ---
	OpenFontIO :: proc(src: ^sdl.IOStream, closeio: bool, ptsize: c.float) -> ^Font ---
	OpenFontWithProperties :: proc(props: sdl.PropertiesID) -> ^Font ---

	CopyFont :: proc(existing_font: ^Font) -> ^Font ---
	GetFontProperties :: proc(font: ^Font) -> sdl.PropertiesID ---

	GetFontGeneration :: proc(font: ^Font) -> c.uint ---
	AddFallbackFont :: proc(font: ^Font, fallback: ^Font) -> bool ---
	RemoveFallbackFont :: proc(font: ^Font, fallback: ^Font) ---
	ClearFallbackFonts :: proc(font: ^Font) ---
	SetFontSize :: proc(font: ^Font, ptsize: c.float) -> bool ---
	SetFontSizeDPI :: proc(font: ^Font, ptsize: c.float, hdpi: c.int, vdpi: c.int) -> bool ---
	GetFontSize :: proc(font: ^Font) -> c.float ---
	GetFontDPI :: proc(font: ^Font, hdpi: ^c.int, vdpi: ^c.int) bool ---

	SetFontStyle :: proc(font: ^Font, style: FontStyleFlags) ---
	GetFontStyle :: proc(font: ^Font) -> FontStyleFlags ---
	SetFontOutline :: proc(font: ^Font, outline: c.int) -> bool ---
	GetFontOutline :: proc(font: ^Font) -> c.int ---

	SetFontHinting :: proc(font: ^Font, hinting: HintingFlags) ---
	GetNumFontFaces :: proc(font: ^Font) -> c.int ---
	GetFontHinting :: proc(font: ^Font) -> HintingFlags ---
	SetFontSDF :: proc(font: ^Font, enabled: bool) -> bool ---
	GetFontSDF :: proc(font: ^Font) -> bool ---

	SetFontWrapAlignment :: proc(font: ^Font, align: HorizontalAlignment) ---
	GetFontWrapAlignment :: proc(font: ^Font) -> HorizontalAlignment ---
	GetFontHeight :: proc(font: ^Font) -> c.int ---
	GetFontAscent :: proc(font: ^Font) -> c.int ---
	GetFontDescent :: proc(font: ^Font) -> c.int ---
	SetFontLineSkip :: proc(font: ^Font, lineskip: c.int) ---
	GetFontLineSkip :: proc(font: ^Font) -> c.int ---
	SetFontKerning :: proc(font: ^Font, enabled: bool) ---
	GetFontKerning :: proc(font: ^Font) -> bool ---
	IsFixedWidth :: proc(font: ^Font) -> bool ---
	IsScalable :: proc(font: ^Font) -> bool ---
	GetFontFamilyName :: proc(font: ^Font) -> cstring ---
	GetFontStyleName :: proc(font: ^Font) -> cstring ---

	SetFontDirection :: proc(font: ^Font, direction: Direction) -> bool ---
	GetFontDirection :: proc(font: ^Font) -> Direction ---
	StringToTag :: proc(str: cstring) -> c.uint ---
	TagToString :: proc(tag: c.uint, str: cstring, size: c.size_t) ---
	SetFontScript :: proc(font: ^Font, script: c.uint) -> bool ---
	GetFontScript :: proc(font: ^Font) -> c.uint ---
	GetGlyphScript :: proc(ch: c.uint) -> c.uint ---
	SetFontLanguage :: proc(font: ^Font, language_bcp47: cstring) -> bool ---
	HasGlyph :: proc(font: ^Font, ch: c.uint) -> bool ---
	GetGlyphImage :: proc(font: ^Font, ch: c.uint, image_type: ^ImageType) -> ^sdl.Surface ---
	GetGlyphImageForIndex :: proc(font: ^Font, glyph_index: c.uint, image_type: ^ImageType) -> ^sdl.Surface ---
	GetGlyphMetrics :: proc(font: ^Font, ch: c.uint, minx: ^c.int, maxx: ^c.int, miny: ^c.int, maxy: ^c.int, advance: ^c.int) -> bool ---
	GetGlyphKerning :: proc(font: ^Font, previous_ch: c.int, ch: c.int, kerning: ^c.int) -> bool ---
	GetStringSize :: proc(font: ^Font, text: cstring, length: c.size_t, w: ^c.int, h: ^x.int) -> bool ---
	GetStringSizeWrapped :: proc(font: ^Font, text: cstring, length: c.size_t, wrap_width: c.int, w: ^c.int, h: ^c.int) -> bool ---
	MeasureString :: proc(font: ^Font, text: cstring, length: c.size_t, max_width: c.int, measured_width: ^c.int, measured_length: ^c.size_t) -> bool ---
	RenderText_Solid :: proc(font: ^Font, text: cstring, length: c.size_t, fg: sdl.FColor) -> ^sdl.Surface ---
	RenderText_Solid_Wrapped :: proc(font: ^Font, text: cstring, length: c.size_t, fg: sdl.FColor, wrap_length: c.int) -> ^sdl.Surface ---
	RenderGlyph_Solid :: proc(font: ^Font, ch: c.uint, fg: sdl.FColor) -> ^sdl.Surface ---
	RenderText_Shaded :: proc(font: ^Font, text: cstring, length: c.size_t, fg: sdl.FColor, bg: sdl.FColor) -> ^sdl.Surface ---
	RenderText_Shaded_Wrapped :: proc(font: ^Font, text: cstring, length: c.size_t, fg: sdl.FColor, bg: sdl.FColor, wrap_width: c.int) -> ^sdl.Surface ---
	RenderGlyph_Shaded :: proc(font: ^Font, ch: c.uint, fg: sdl.FColor, bg: sdl.FColor) -> ^sdl.Surface ---
	RenderText_Blended :: proc(font: ^Font, text: cstring, length: c.size_t, fg: sdl.FColor) -> ^sdl.Surface ---
	RenderText_Blended_Wrapped :: proc(font: ^Font, text: cstring, length: c.size_t, fg: sdl.FColor, wrap_width: c.int) -> ^sdl.Surface ---
	RenderGlyph_Blended :: proc(font: ^Font, ch: c.uint, fg: sdl.FColor) -> ^sdl.Surface ---
	RenderText_LCD :: proc(font: ^Font, text: cstring, length: c.size_t, fg: sdl.FColor, bg: sdl.FColor) -> ^sdl.Surface ---
	RenderText_LCD_Wrapped :: proc(font: ^Font, text: cstring, length: c.size_t, fg: sdl.FColor, bg: sdl.FColor, wrap_width: c.int) -> ^sdl.Surface ---
	RenderGlyph_LCD :: proc(font: ^Font, ch: c.uint, fg: sdl.FColor, bg: sdl.FColor) -> ^sdl.Surface ---

	CreateSurfaceTextEngine :: proc() -> ^TextEngine ---
	DrawSurfaceText :: proc(text: ^Text, x: c.int, y: c.int, surface: ^sdl.Surface) -> bool ---
	DestroySurfaceTextEngine :: proc(engine: ^TextEngine) ---

	CreateRendererTextEngine :: proc(renderer: ^sdl.Renderer) -> ^TextEngine ---
	CreateRendererTextEngineWithProperties :: proc(props: sdl.PropertiesID) -> ^TextEngine ---
	DrawRendererText :: proc(text: ^Text, x: c.float, y: c.float) -> bool ---
	DestroyRendererTextEngine :: proc(engine: ^TextEngine) ---

	CreateGPUTextEngine :: proc(device: ^sdl.GPUDevice) -> ^TextEngine ---
	CreateGPUTextEngineWithProperties :: proc(props: sdl.PropertiesID) -> ^TextEngine ---
	GetGPUTextDrawData :: proc(text: ^Text) -> ^GPUAtlasDrawSequence ---
	DestroyGPUTextEngine :: proc(engine: ^TextEngine) ---
	SetGPUTextEngineWinding :: proc(engine: ^TextEngine, winding: GPUTextEngineWinding) ---
	GetGPUTextEngineWinding :: proc(engine: ^TextEngine) -> GPUTextEngineWinding ---

	CreateText :: proc(engine: TextEngine, font: ^Font, text: cstring, length: c.size_t) -> ^Text ---
	GetTextProperties :: proc(text: ^Text) -> sdl.PropertiesID ---
	SetTextEngine :: proc(text: ^Text, engine: ^TextEngine) -> bool ---
	GetTextEngine :: proc(text: ^Text) -> ^TextEngine ---
	SetTextFont :: proc(text: ^Text, font: ^Font) -> bool ---
	GetTextFont :: proc(text: ^Text) -> ^Font ---
	SetTextDirection :: proc(text: ^Text, direction: Direction) -> bool ---
	GetTextDirection :: proc(textu: ^Text) -> Direction ---
	SetTextScript :: proc(text: ^Text, script: c.uint) -> bool ---
	GetTextScript :: proc(text: ^Text) -> c.uint ---
	SetTextColor :: proc(text: ^Text, r: c.Uint8, g: c.Uint8, b: c.Uint8, a: c.Uint8) -> bool ---
	SetTextColorFloat :: proc(text: ^Text, r: c.float, g: c.float, b: c.float, a: c.float) -> bool ---
	GetTextColor :: proc(text: ^Text, r: ^c.Uint8, ^g: c.Uint8, ^b: c.Uint8, ^a: c.Uint8) -> bool ---
	GetTextColorFloat :: proc(text: ^Text, r: ^c.float, ^g: c.float, b: ^c.float, a: ^c.float) -> bool ---
	SetTextPosition :: proc(text: ^Text, x: c.int, y: c.int) -> bool ---
	GetTextPosition :: proc(text: ^Text, x: ^c.int, y: ^c.int) -> bool ---
	SetTextWrapWidth :: proc(text: ^Text, wrap_width: c.int) -> bool ---
	GetTextWrapWidth :: proc(text: ^Text, wrap_width: ^c.int) -> bool ---
	SetTextWrapWhitespaceVisible :: proc(text: ^Text, visible: bool) -> bool ---
	TextWrapWhitespaceVisible :: proc(text: ^Text) -> bool ---
	SetTextString :: proc(text: ^Text, str: cstring, length: c.size_t) -> bool ---
	InsertTextString :: proc(text: ^Text, offset: c.int, str: cstring, length: c.size_t) -> bool ---
	AppendTextString :: proc(text: ^Text,  str: cstring, length: c.size_t) -> bool ---
	DeleteTextString :: proc(text: ^Text, offset: c.int, length: c.int) -> bool ---
	GetTextSize :: proc(text: ^Text, w: ^c.int, h: ^c.int) -> bool ---
	GetTextSubString :: proc(text: ^Text, offset: c.int, substring: ^SubString) -> bool ---
	GetTextSubStringForLine :: proc(text: ^Text, line: c.int, substring: ^SubString) -> bool ---
	GetTextSubStringsForRange :: proc(text: ^Text, offset: c.int, length: c.int, count: ^c.int) -> [^]^SubString ---
	GetTextSubStringForPoint :: proc(text: ^Text, x: c.int, y: c.int, substring: ^SubString) -> bool ---
	GetPreviousTextSubString :: proc(text: ^Text, substring: ^SubString, prvious: ^SubString) -> bool ---
	GetNextTextSubString :: proc(text: ^Text, substring: ^SubString, next: ^SubString) -> bool ---
	UpdateText :: proc(text: ^Text) -> bool ---
	DestroyText :: proc(text: ^Text) ---

	CloseFont :: proc(font: ^Font) ---
	Quit :: proc() ---
	WasInit :: proc() -> c.int ---

}
