# Usage:
# make build-odin                  // build odin compiler (odin executable in vendor/odin)
# make | make release | make debug // build iris and libs
# make clean                       // removes iris and lib artifacts

NAME := iris
ODIN := ./vendor/odin/odin

UNAME_OS := $(shell uname)
UNAME_ARCH := $(shell uname -m)

MINIAUDIO_LIB := ./vendor/odin/vendor/miniaudio/lib/miniaudio.a
RAYLIB_LIB := ./vendor/raylib/src/libraylib.a

ifeq ($(UNAME_OS),Linux)
	OS := linux

	ifeq ($(UNAME_ARCH),aarch64) # assuming raspberry pi
		RAYLIB_BUILD_FLAGS ?= PLATFORM=PLATFORM_DRM GRAPHICS=GRAPHICS_API_OPENGL_ES3
		EXTRA_FLAGS += -extra-linker-flags="-ldrm -lgbm -lEGL -lGLESv2"
	endif
endif
ifeq ($(UNAME_OS),Darwin)
	OS := macos
endif

all: release

build-odin:
	$(MAKE) -C vendor/odin release-native

$(MINIAUDIO_LIB):
	@echo --- Building miniaudio...
	$(MAKE) -C vendor/odin/vendor/miniaudio/src

$(RAYLIB_LIB):
	@echo --- Building raylib...
	$(MAKE) -C vendor/raylib/src $(RAYLIB_BUILD_FLAGS)
	cp $(RAYLIB_LIB) vendor/odin/vendor/raylib/$(OS)/libraylib.a

BUILD_CMD := mkdir -p ./out && $(ODIN) build src -out:out/$(NAME) $(EXTRA_FLAGS)

debug: $(MINIAUDIO_LIB) $(RAYLIB_LIB)
	@echo --- Building iris...
	$(BUILD_CMD) -debug

release: $(MINIAUDIO_LIB) $(RAYLIB_LIB)
	@echo --- Building iris...
	$(BUILD_CMD)
	@echo --- Done!

clean:
	@echo --- Removing miniaudio artifacts...
	rm -f $(MINIAUDIO_LIB)
	@echo --- Removing raylib artifacts...
	$(MAKE) clean -C vendor/raylib/src
	@echo --- Removing iris artifacts...
	rm -f out/$(NAME)
	rm -rf out/*.dSYM
	@echo --- Done!
