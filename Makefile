.PHONY: build test lint package release clean run

build:
	swift build

test:
	swift test

lint:
	node --check Extension/background.js
	node --check Extension/content.js
	node --check Extension/options.js
	node Extension/tests/adapters.test.js
	plutil -lint BundleResources/Info.plist
	python3 -m json.tool Extension/manifest.json >/dev/null

package:
	./Scripts/package-app.sh

release:
	./Scripts/make-release.sh

run:
	swift run

clean:
	swift package clean
	rm -rf dist
