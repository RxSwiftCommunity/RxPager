# Install Tasks

install-lint:
	brew remove swiftlint --force || true
	brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/66507c32f683bb7a6f7cf0ec6062b3f0c4844313/Formula/swiftlint.rb

# Run Tasks
publish:
	swiftlint lint --strict 2>/dev/null

lint:
	swiftlint lint --strict 2>/dev/null
