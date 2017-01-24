# Install Tasks

install-lint:
	brew install swiftlint

# Run Tasks
publish:
	pod trunk push RxPager.podspec

lint:
	swiftlint lint --strict 2>/dev/null
