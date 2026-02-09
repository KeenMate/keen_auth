.PHONY: setup dev deps compile test docs format clean publish publish-dry help

# Setup library + test app
setup: deps
	cd test_app && mix deps.get
	@echo "✓ Setup complete! Run 'make dev' to start"

# Run test app (for interactive library development)
dev:
	cd test_app && mix phx.server

# Run test app with iex
iex:
	cd test_app && iex -S mix phx.server

# Get dependencies
deps:
	mix deps.get

# Compile
compile:
	mix compile

# Run tests
test:
	mix test

# Generate documentation
docs:
	mix docs

# Format code
format:
	mix format

# Check formatting
format-check:
	mix format --check-formatted

# Clean build artifacts
clean:
	mix clean
	rm -rf _build deps

# Show test app routes
routes:
	cd test_app && mix phx.routes

# Publish to hex.pm (dry run)
publish-dry:
	mix hex.publish --dry-run

# Publish to hex.pm
publish:
	mix hex.publish

# Help
help:
	@echo "Development:"
	@echo "  setup        - Install all dependencies (library + test app)"
	@echo "  dev          - Start test app server (with keen_auth live reload)"
	@echo "  iex          - Start test app with interactive console"
	@echo "  routes       - Show test app routes"
	@echo ""
	@echo "Library:"
	@echo "  deps         - Get library dependencies"
	@echo "  compile      - Compile the library"
	@echo "  test         - Run tests"
	@echo "  docs         - Generate documentation"
	@echo "  format       - Format code"
	@echo "  format-check - Check code formatting"
	@echo "  clean        - Clean build artifacts"
	@echo ""
	@echo "Publishing:"
	@echo "  publish-dry  - Dry run publish to hex.pm"
	@echo "  publish      - Publish to hex.pm"
