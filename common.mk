ifeq ($(BUILD), win32)
	CC = i686-w64-mingw32-gcc
	AR = i686-w64-mingw32-ar
	LD = i686-w64-mingw32-ld
	PKGCONFIG = i686-w64-mingw32-pkg-config
	FLAGS = \
		--cc=$(CC) \
		--pkg-config=$(PKGCONFIG) \
		-D WINDOWS
	BINEXT = .exe
	LIBEXT = lib
else ifeq ($(BUILD), win64)
	CC = x86_64-w64-mingw32-gcc
	AR = x86_64-w64-mingw32-ar
	LD = x86_64-w64-mingw32-ld
	PKGCONFIG = x86_64-w64-mingw32-pkg-config
	FLAGS = \
		--cc=$(CC) \
		--pkg-config=$(PKGCONFIG) \
		-D WINDOWS
	BINEXT = .exe
	LIBEXT = lib
else
	AR = ar
	PKGCONFIG = pkg-config
	LIBEXT = a
endif


ifeq ($(DEBUG), yes)
	FLAGS += \
		-g \
		--save-temps \
		-D DEBUG
else
	FLAGS += \
		--Xcc="-w"
endif


_BUILD_DIR = $(BUILD_DIR)/$(NAME)

