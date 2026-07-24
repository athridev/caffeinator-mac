SHELL := /bin/zsh
APP := dist/Caffeinator.app
BINARY := $(APP)/Contents/MacOS/Caffeinator

.PHONY: build test preview social clean

build:
	./build.sh

test: build
	$(BINARY) --self-test
	$(BINARY) --hotkey-self-test
	plutil -lint $(APP)/Contents/Info.plist
	codesign --verify --deep --strict --verbose=2 $(APP)
	unzip -tq dist/Caffeinator-macOS.zip

preview: build
	mkdir -p .build/previews
	$(BINARY) --render-preview .build/previews/active.png
	$(BINARY) --render-preview .build/previews/timed.png --preview-timed
	$(BINARY) --render-preview .build/previews/standby.png --preview-off

social: build preview
	./scripts/generate-media.sh

clean:
	rm -rf .build dist
