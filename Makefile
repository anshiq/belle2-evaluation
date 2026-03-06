# Belle II Evaluation Task: Reproducible Prefix-Based Build System

# ==============================================================
# Configuration
# ==============================================================

CURDIR := $(shell pwd)
PREFIX := $(CURDIR)/prefix
BUILD_DIR := $(CURDIR)/build
DOWNLOAD_DIR := $(CURDIR)/downloads

# Versions
LIBFFI_VERSION := 3.5.1
PYTHON_VERSION := 3.11.8
SQLITE_VERSION := 3450100
SQLITE_YEAR := 2024
XZ_VERSION := 5.8.2

# URLs
LIBFFI_URL := https://github.com/libffi/libffi/releases/download/v$(LIBFFI_VERSION)/libffi-$(LIBFFI_VERSION).tar.gz
PYTHON_URL := https://www.python.org/ftp/python/$(PYTHON_VERSION)/Python-$(PYTHON_VERSION).tar.xz
SQLITE_URL := https://www.sqlite.org/$(SQLITE_YEAR)/sqlite-autoconf-$(SQLITE_VERSION).tar.gz
XZ_URL := https://github.com/tukaani-project/xz/releases/download/v$(XZ_VERSION)/xz-$(XZ_VERSION).tar.gz

# Build environment
export PKG_CONFIG_PATH := $(PREFIX)/lib/pkgconfig
export LDFLAGS := -L$(PREFIX)/lib -Wl,-rpath,$(PREFIX)/lib
export CPPFLAGS := -I$(PREFIX)/include
export CFLAGS := -fPIC
export PATH := $(PREFIX)/bin:$(PATH)
export LD_LIBRARY_PATH := $(PREFIX)/lib

JOBS ?= $(shell nproc)

# ==============================================================
# Main Targets
# ==============================================================

.PHONY: all clean distclean verify help

all: python verify

help:
	@echo "Belle II Dependency Build System"
	@echo ""
	@echo "Targets:"
	@echo "  make all        Build full stack"
	@echo "  make clean      Remove build directory"
	@echo "  make distclean  Remove downloads and prefix"
	@echo "  make verify     Test installation"
	@echo ""

# ==============================================================
# Tool Check (minimal system safety)
# ==============================================================

check-tools:
	@command -v curl >/dev/null || (echo "curl required"; exit 1)
	@command -v gcc >/dev/null || (echo "gcc required"; exit 1)
	@command -v pkg-config >/dev/null || (echo "pkg-config required"; exit 1)
	@command -v make >/dev/null || (echo "make required"; exit 1)
	@echo '#include <zlib.h>' | gcc -E - >/dev/null 2>&1 || (echo "zlib headers not found. Install zlib1g-dev"; exit 1)
# ==============================================================
# Download Rules
# ==============================================================

$(DOWNLOAD_DIR):
	mkdir -p $@

$(BUILD_DIR):
	mkdir -p $@

$(DOWNLOAD_DIR)/libffi.tar.gz: | $(DOWNLOAD_DIR)
	curl -L $(LIBFFI_URL) -o $@

$(DOWNLOAD_DIR)/sqlite.tar.gz: | $(DOWNLOAD_DIR)
	curl -L $(SQLITE_URL) -o $@

$(DOWNLOAD_DIR)/xz.tar.gz: | $(DOWNLOAD_DIR)
	curl -L $(XZ_URL) -o $@

$(DOWNLOAD_DIR)/python.tar.xz: | $(DOWNLOAD_DIR)
	curl -L $(PYTHON_URL) -o $@

# ==============================================================
# libffi
# ==============================================================

.PHONY: libffi
libffi: $(PREFIX)/lib/libffi.so

$(PREFIX)/lib/libffi.so: check-tools $(DOWNLOAD_DIR)/libffi.tar.gz | $(BUILD_DIR)
	tar -xf $(DOWNLOAD_DIR)/libffi.tar.gz -C $(BUILD_DIR)
	cd $(BUILD_DIR)/libffi-$(LIBFFI_VERSION) && \
	./configure --prefix=$(PREFIX) --enable-shared --disable-static && \
	$(MAKE) -j$(JOBS) && \
	$(MAKE) install

# ==============================================================
# SQLite
# ==============================================================

.PHONY: sqlite
sqlite: $(PREFIX)/lib/libsqlite3.so

$(PREFIX)/lib/libsqlite3.so: $(DOWNLOAD_DIR)/sqlite.tar.gz | $(BUILD_DIR)
	tar -xf $(DOWNLOAD_DIR)/sqlite.tar.gz -C $(BUILD_DIR)
	cd $(BUILD_DIR)/sqlite-autoconf-$(SQLITE_VERSION) && \
	./configure --prefix=$(PREFIX) --enable-shared --disable-static && \
	$(MAKE) -j$(JOBS) && \
	$(MAKE) install

# ==============================================================
# XZ Utils
# ==============================================================

.PHONY: xz
xz: $(PREFIX)/lib/liblzma.so

$(PREFIX)/lib/liblzma.so: $(DOWNLOAD_DIR)/xz.tar.gz | $(BUILD_DIR)
	tar -xf $(DOWNLOAD_DIR)/xz.tar.gz -C $(BUILD_DIR)
	cd $(BUILD_DIR)/xz-$(XZ_VERSION) && \
	./configure --prefix=$(PREFIX) --enable-shared --disable-static && \
	$(MAKE) -j$(JOBS) && \
	$(MAKE) install

# ==============================================================
# Python (depends on others)
# ==============================================================

.PHONY: python
python: $(PREFIX)/bin/python3

$(PREFIX)/bin/python3: libffi sqlite xz $(DOWNLOAD_DIR)/python.tar.xz | $(BUILD_DIR)
	tar -xf $(DOWNLOAD_DIR)/python.tar.xz -C $(BUILD_DIR)
	cd $(BUILD_DIR)/Python-$(PYTHON_VERSION) && \
	./configure \
		--prefix=$(PREFIX) \
		--enable-shared \
		--with-system-ffi \
		--with-ensurepip=install \
		LDFLAGS="$(LDFLAGS)" \
		CPPFLAGS="$(CPPFLAGS)" && \
	$(MAKE) -j$(JOBS) -C $(BUILD_DIR)/Python-$(PYTHON_VERSION) && \
	$(MAKE) -C $(BUILD_DIR)/Python-$(PYTHON_VERSION) install

# ==============================================================
# Verification
# ==============================================================

verify:
	@echo ""
	@echo "Python version:"
	@$(PREFIX)/bin/python3 --version
	@echo ""
	@echo "Testing modules:"
	@$(PREFIX)/bin/python3 -c "import sqlite3, lzma, ctypes; print('All dependency modules working')"
	@echo ""
	@echo "Linked libraries:"
	@if command -v ldd >/dev/null; then \
	ldd $(PREFIX)/bin/python3 | grep $(PREFIX) || true; \
	fi

# ==============================================================
# Cleanup
# ==============================================================

clean:
	rm -rf $(BUILD_DIR)

distclean: clean
	rm -rf $(DOWNLOAD_DIR) $(PREFIX)