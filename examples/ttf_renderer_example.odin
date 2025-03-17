package examples

import "core:fmt"
import "core:strings"
import "core:c"
import sdl "vendor:sdl3"
import ttf "../"

main :: proc() {
	if !sdl.Init({.VIDEO}) {
		fmt.println("ERRROR: Failed to initialize SDL")
		return
	}

	if !ttf.Init() {
		fmt.println("ERRROR: Failed to initialize TTF")
		return
	}
	defer ttf.Quit()

	window := sdl.CreateWindow("SDL3 TFF Example", 1280, 720, {.RESIZABLE, .HIGH_PIXEL_DENSITY})
	defer sdl.DestroyWindow(window)

	renderer := sdl.CreateRenderer(window, nil)
	defer sdl.DestroyRenderer(renderer)

	// C:\programming\odin\odin-sdl3-ttf\bin\Inter-VariableFont.ttf
	base_path := string(sdl.GetBasePath())
	font_path: string = fmt.tprintf("%vInter-VariableFont.ttf", base_path)
	fmt.println("Loading Font from:", font_path)
	font := ttf.OpenFont(strings.clone_to_cstring(font_path, context.temp_allocator), 100)
	if font == nil {
		fmt.println("ERRROR: Failed to open font")
		return
	}
	defer ttf.CloseFont(font)

	// if !ttf.SetFontSDF(font, true) {
	// 	fmt.println("ERROR: Failed to set SDK on font")
	// 	fmt.println(sdl.GetError())
	// }
	// fmt.println(ttf.GetFontSDF(font))

	text: cstring = "SDL3_TTF IN ODIN!"
	message_surface := ttf.RenderText_Blended(font, text, len(text), {255, 255, 255, 255})
	message_texture := sdl.CreateTextureFromSurface(renderer, message_surface)

	sdl.DestroySurface(message_surface)

	message_texture_props := sdl.GetTextureProperties(message_texture)

	text_rect := sdl.FRect{
		x = 0,
		y = 0,
		w = c.float(sdl.GetNumberProperty(message_texture_props, sdl.PROP_TEXTURE_WIDTH_NUMBER, 0)),
		h = c.float(sdl.GetNumberProperty(message_texture_props, sdl.PROP_TEXTURE_HEIGHT_NUMBER, 0)),
	}

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

		sdl.SetRenderDrawColor(renderer, 64, 64, 64, 255)
		sdl.RenderClear(renderer)
		sdl.RenderTexture(renderer, message_texture, nil, &text_rect)

		sdl.RenderPresent(renderer)
	}
}