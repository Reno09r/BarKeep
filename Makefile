.PHONY: gen build run stop clean logs report signing test

APP := build/Build/Products/Debug/BarKeep.app
KEYCHAIN := $(HOME)/Library/Keychains/barkeep-dev.keychain-db
SIGN_IDENTITY := BarKeep Dev

gen:
	xcodegen generate

signing:
	@bash scripts/setup-signing.sh
	@security unlock-keychain -p barkeep "$(KEYCHAIN)"

build: gen signing
	xcodebuild \
		-project BarKeep.xcodeproj \
		-scheme BarKeep \
		-configuration Debug \
		-derivedDataPath build \
		CODE_SIGN_STYLE=Manual \
		CODE_SIGN_IDENTITY="$(SIGN_IDENTITY)" \
		OTHER_CODE_SIGN_FLAGS="--keychain $(KEYCHAIN)" \
		build

test: gen
	xcodebuild \
		-project BarKeep.xcodeproj \
		-scheme BarKeep \
		-configuration Debug \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		test

run: build
	@pkill -x BarKeep 2>/dev/null || true
	open "$(APP)"

stop:
	@pkill -x BarKeep 2>/dev/null || true

logs:
	@tail -n 80 -f ~/Library/Logs/BarKeep.log

report:
	@tail -n 120 ~/Library/Logs/BarKeep.log

clean:
	rm -rf build BarKeep.xcodeproj
