.PHONY: all build test clean install compile compile\:release compile\:static help

# Default target
all: build

# Variables
CRYSTAL := crystal
BUILD_FLAGS := --release
STATIC_FLAGS := --static --release --no-debug
SRC := src/cli.cr
OUT := bin/zone
INSTALL_PATH := /usr/local/bin

help: ## Show this help message
	@echo "Zone - Crystal Build Tasks"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_\:-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: compile ## Alias for compile

compile: ## Build the release binary (default)
	@echo "Building Zone (release mode)..."
	@mkdir -p bin
	$(CRYSTAL) build $(SRC) $(BUILD_FLAGS) -o $(OUT)
	@echo "✓ Build complete: $(OUT)"

compile\:release: ## Build optimized release binary (no debug symbols)
	@echo "Building Zone (optimized release)..."
	@mkdir -p bin
	$(CRYSTAL) build $(SRC) --release --no-debug -o $(OUT)
	@strip $(OUT)
	@echo "✓ Optimized build complete: $(OUT)"
	@ls -lh $(OUT)

compile\:static: ## Build fully static binary (portable, no dependencies)
	@echo "Building Zone (static binary)..."
	@mkdir -p bin
	$(CRYSTAL) build $(SRC) $(STATIC_FLAGS) -o $(OUT)
	@echo "✓ Static build complete: $(OUT)"
	@echo "Checking dependencies:"
	@ldd $(OUT) 2>&1 | grep "not a dynamic" || ldd $(OUT)

compile\:debug: ## Build with debug symbols
	@echo "Building Zone (debug mode)..."
	@mkdir -p bin
	$(CRYSTAL) build $(SRC) -o $(OUT)
	@echo "✓ Debug build complete: $(OUT)"

test: ## Run all tests
	@echo "Running tests..."
	$(CRYSTAL) spec

test\:verbose: ## Run tests with verbose output
	@echo "Running tests (verbose)..."
	$(CRYSTAL) spec --verbose

test\:single: ## Run a single test file (usage: make test:single FILE=spec/zone/timestamp_spec.cr)
	@echo "Running test: $(FILE)"
	$(CRYSTAL) spec $(FILE)

clean: ## Remove build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf bin/zone
	@rm -rf .crystal
	@echo "✓ Clean complete"

install: compile ## Install zone to system path
	@echo "Installing zone to $(INSTALL_PATH)..."
	@install -m 755 $(OUT) $(INSTALL_PATH)
	@echo "✓ Installed: $(INSTALL_PATH)/zone"

uninstall: ## Uninstall zone from system path
	@echo "Uninstalling zone..."
	@rm -f $(INSTALL_PATH)/zone
	@echo "✓ Uninstalled"

benchmark: ## Run performance benchmarks
	@echo "Running benchmarks..."
	@time $(OUT) "2025-01-15T10:30:00Z" --pretty > /dev/null
	@echo "✓ Benchmark complete"

version: ## Show Crystal version
	@$(CRYSTAL) version

check: ## Check code without building
	@echo "Checking code..."
	$(CRYSTAL) build $(SRC) --no-codegen

format: ## Format Crystal code
	@echo "Formatting code..."
	$(CRYSTAL) tool format src/ spec/
	@echo "✓ Format complete"

format\:check: ## Check if code is formatted
	@echo "Checking code format..."
	$(CRYSTAL) tool format --check src/ spec/

deps: ## Show dependencies (currently none - stdlib only!)
	@echo "Zone has no external dependencies."
	@echo "Uses only Crystal standard library."
