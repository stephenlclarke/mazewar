SHELL := /bin/bash

PYTHON ?= python3
SWIFT_LLVM_COV ?= $(shell xcrun --find llvm-cov 2>/dev/null)
SWIFT_COVERAGE_MIN ?= 85

.PHONY: build test coverage coverage-check sonar sonar-scan ci

build:
	swift build

test:
	swift test

coverage:
	@test -n "$(SWIFT_LLVM_COV)" || { echo "llvm-cov is required" >&2; exit 1; }
	@rm -f coverage.lcov coverage.xml
	swift test --enable-code-coverage
	@test_binary="$$(find .build -path '*MazewarPackageTests.xctest/Contents/MacOS/MazewarPackageTests' -type f -print -quit)"; \
	profile="$$(find .build -path '*/codecov/default.profdata' -type f -print -quit)"; \
	test -n "$$test_binary" && test -n "$$profile" || { echo "Swift coverage artifacts are missing" >&2; exit 2; }; \
	"$(SWIFT_LLVM_COV)" export -format=lcov -instr-profile="$$profile" "$$test_binary" --sources Sources/MazewarCore > coverage.lcov
	$(PYTHON) Tools/coverage/lcov-to-sonarqube-generic.py coverage.lcov coverage.xml

coverage-check: coverage
	$(PYTHON) Tools/coverage/check-coverage.py --minimum "$(SWIFT_COVERAGE_MIN)" --coverage coverage.xml

sonar: coverage sonar-scan

sonar-scan:
	@test -f coverage.xml || { echo "coverage.xml is missing; run make coverage first" >&2; exit 2; }
	@sonar_token="$${SONAR_TOKEN:-$${SONAR_TOKEN_PERSONAL:-}}"; \
	test -n "$$sonar_token" || { echo "SONAR_TOKEN or SONAR_TOKEN_PERSONAL is required" >&2; exit 2; }; \
	SONAR_TOKEN="$$sonar_token" sonar-scanner

ci: coverage-check
